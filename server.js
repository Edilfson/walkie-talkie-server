const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(cors());

// Flutter web build klasörünü statik olarak sun
app.use(express.static(path.join(__dirname, 'build/web')));

// Kök URL'ye gelen isteklerde index.html döndür
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build/web', 'index.html'));
});

const server = http.createServer(app);
const io = socketIo(server, {
  cors: { origin: '*' }
});

// Oda ve katılımcı yönetimi için bellek içi veri yapıları
const rooms = {
  genel: {
    name: 'Genel Sohbet',
    participants: [],
    createdBy: 'system',
    createdAt: new Date().toISOString(),
    messages: [], // Son 1 saatlik mesajlar burada tutulacak
  },
};

// Mesaj geçmişi için maksimum süre (ms cinsinden)
const MESSAGE_HISTORY_MS = 60 * 60 * 1000; // 1 saat

function pruneOldMessages(roomId) {
  if (!rooms[roomId] || !rooms[roomId].messages) return;
  const now = Date.now();
  rooms[roomId].messages = rooms[roomId].messages.filter(msg => now - msg.sentAt < MESSAGE_HISTORY_MS);
}

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // Odaya katılma
  socket.on('join', ({ roomId, user, password, inviteCode }) => {
    // Oda yoksa oluştur (şifresiz/davetsiz ise)
    if (!rooms[roomId]) {
      rooms[roomId] = { participants: [], messages: [] };
    }
    // Şifre/davet kodu kontrolü
    const room = rooms[roomId];
    if ((room.password && room.password !== password) || (room.inviteCode && room.inviteCode !== inviteCode)) {
      socket.emit('join_error', { message: 'Şifre veya davet kodu hatalı!' });
      return;
    }
    socket.join(roomId);
    // Katılımcı ekle (tekrar eklenmesin)
    if (!room.participants.find(u => u.id === user.id)) {
      room.participants.push(user);
    }
    // Oda geçmişini sadece yeni katılana gönder
    pruneOldMessages(roomId);
    socket.emit('history', room.messages || []);
    // Tüm istemcilere oda ve katılımcı listesini gönder
    io.emit('rooms', getRoomsSummary());
    io.to(roomId).emit('participants', room.participants);
    console.log(`User ${user.name} joined room ${roomId}`);
  });

  // Odadan ayrılma
  socket.on('leave', ({ roomId, userId }) => {
    socket.leave(roomId);
    if (rooms[roomId]) {
      rooms[roomId].participants = rooms[roomId].participants.filter(u => u.id !== userId);
      // Oda silme kuralı: Sadece 'genel' oda ve kullanıcıya ait ilk oluşturulan oda hariç, oda boşsa sil
      if (
        rooms[roomId].participants.length === 0 &&
        roomId !== 'genel' &&
        !(rooms[roomId].createdBy && rooms[roomId].createdBy === userId)
      ) {
        delete rooms[roomId];
      }
    }
    io.emit('rooms', getRoomsSummary());
    if (rooms[roomId]) {
      io.to(roomId).emit('participants', rooms[roomId].participants);
    }
    console.log(`User ${userId} left room ${roomId}`);
  });

  // Oda oluşturma
  socket.on('createRoom', ({ roomId, name, createdBy, createdAt, password, inviteCode }) => {
    // Her kullanıcı sadece bir oda oluşturabilir
    const userRoomExists = Object.values(rooms).some(
      room => room.createdBy === createdBy && roomId !== 'genel'
    );
    if (!rooms[roomId] && !userRoomExists) {
      rooms[roomId] = { name, participants: [], createdBy, createdAt, password, inviteCode, messages: [] };
      // Davet linki üret
      rooms[roomId].inviteLink = `https://yourapp.com/join/${roomId}${inviteCode ? `?invite=${inviteCode}` : ''}`;
      io.emit('rooms', getRoomsSummary());
      console.log(`Room created: ${name}`);
    }
  });

  // Sesli mesajı ilet
  socket.on('audio', (data) => {
    // data: { room, audioBlob, sender, sentAt }
    const msg = {
      ...data,
      sentAt: Date.now(),
    };
    if (!rooms[data.room]) return;
    if (!rooms[data.room].messages) rooms[data.room].messages = [];
    rooms[data.room].messages.push(msg);
    pruneOldMessages(data.room);
    socket.to(data.room).emit('audio', msg);
  });

  // Kısa yazılı mesaj event'i
  socket.on('textMessage', (data) => {
    const msg = {
      ...data,
      sentAt: Date.now(),
    };
    if (!rooms[data.roomId]) return;
    if (!rooms[data.roomId].textMessages) rooms[data.roomId].textMessages = [];
    rooms[data.roomId].textMessages.push(msg);
    io.to(data.roomId).emit('textMessage', msg);
  });

  // Katılımcı atma (kick)
  socket.on('kickParticipant', ({ roomId, targetUserId, byUserId }) => {
    const room = rooms[roomId];
    if (!room) return;
    // Sadece oda yöneticisi atabilir
    if (room.createdBy !== byUserId) return;
    // Katılımcıyı çıkar
    room.participants = room.participants.filter(u => u.id !== targetUserId);
    // Atılan kullanıcıya özel event gönder
    const targetSocket = Array.from(io.sockets.sockets.values()).find(s => s.userId === targetUserId);
    if (targetSocket) {
      targetSocket.leave(roomId);
      targetSocket.emit('kicked', { roomId });
    }
    io.to(roomId).emit('participants', room.participants);
    io.emit('rooms', getRoomsSummary());
    console.log(`User ${targetUserId} kicked from room ${roomId} by ${byUserId}`);
  });

  // Bağlantı kopunca tüm odalardan çıkar
  socket.on('disconnect', () => {
    for (const roomId in rooms) {
      rooms[roomId].participants = rooms[roomId].participants.filter(u => u.socketId !== socket.id);
      // 'genel' odasını asla silme
      if (rooms[roomId].participants.length === 0 && roomId !== 'genel') {
        delete rooms[roomId];
      }
    }
    io.emit('rooms', getRoomsSummary());
    console.log('User disconnected:', socket.id);
  });
});

function getRoomsSummary() {
  // Oda listesini ve katılımcı sayılarını döndür
  return Object.entries(rooms).map(([id, room]) => ({
    id,
    name: room.name || 'Oda',
    participants: room.participants,
    createdBy: room.createdBy,
    createdAt: room.createdAt,
    password: room.password ? true : false, // Şifreli mi?
    inviteCode: room.inviteCode ? true : false, // Davet kodlu mu?
    inviteLink: room.inviteLink || null,
  }));
}

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
