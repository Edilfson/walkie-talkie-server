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
  },
};

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // Odaya katılma
  socket.on('join', ({ roomId, user }) => {
    socket.join(roomId);
    if (!rooms[roomId]) {
      rooms[roomId] = { participants: [] };
    }
    // Katılımcı ekle (tekrar eklenmesin)
    if (!rooms[roomId].participants.find(u => u.id === user.id)) {
      rooms[roomId].participants.push(user);
    }
    // Tüm istemcilere oda ve katılımcı listesini gönder
    io.emit('rooms', getRoomsSummary());
    io.to(roomId).emit('participants', rooms[roomId].participants);
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
  socket.on('createRoom', ({ roomId, name, createdBy, createdAt }) => {
    // Her kullanıcı sadece bir oda oluşturabilir
    const userRoomExists = Object.values(rooms).some(
      room => room.createdBy === createdBy && roomId !== 'genel'
    );
    if (!rooms[roomId] && !userRoomExists) {
      rooms[roomId] = { name, participants: [], createdBy, createdAt };
      io.emit('rooms', getRoomsSummary());
      console.log(`Room created: ${name}`);
    }
  });

  // Sesli mesajı ilet
  socket.on('audio', (data) => {
    // data: { room, audioBlob, sender }
    socket.to(data.room).emit('audio', data);
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
  }));
}

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
