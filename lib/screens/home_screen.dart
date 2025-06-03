import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../providers/audio_provider.dart';
import 'room_screen.dart';
import '../models/room.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenSettings;
  const HomeScreen({super.key, this.onOpenSettings});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _roomPasswordController = TextEditingController();
  final TextEditingController _roomInviteCodeController =
      TextEditingController();
  final TextEditingController _joinPasswordController = TextEditingController();
  final TextEditingController _joinInviteCodeController =
      TextEditingController();
  String? _selectedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _nameController.addListener(_onNameChanged);
    // Otomatik giriş ve oda listesini göster
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      if (!roomProvider.isConnected) {
        await roomProvider.initialize('Misafir'); // Otomatik anonim giriş
      }
    });
  }

  void _onNameChanged() {
    final newIsValid = _nameController.text.trim().isNotEmpty;
    print('Name changed: "${_nameController.text}", valid: $newIsValid');
    setState(() {
      // _isNameValid = newIsValid;
    });
  }

  Future<void> _initializeAudio() async {
    await context.read<AudioProvider>().initialize();
    if (mounted) {
      setState(() {
        // _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0F08),
      body: SafeArea(
        child: Consumer<RoomProvider>(
          builder: (context, roomProvider, child) {
            // Eğer giriş yapılmamışsa giriş ekranı yerine oda listesi göster
            if (!roomProvider.isConnected) {
              return const Center(child: CircularProgressIndicator());
            }
            // Oda listesi
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merhaba, ${roomProvider.currentUser?.name}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Bir odaya katıl veya yeni oda oluştur',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: widget.onOpenSettings,
                          icon: const Icon(Icons.settings,
                              color: Colors.white, size: 28),
                        ),
                        IconButton(
                          onPressed: () => _showCreateRoomDialog(roomProvider),
                          icon: const Icon(Icons.add_circle,
                              color: Colors.amber, size: 32),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Online kişi sayısı
                Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Online: ${roomProvider.totalOnlineUsers}',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'Mevcut Odalar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: roomProvider.availableRooms.isEmpty
                      ? const Center(
                          child: Text(
                            'Henüz oda yok\nYeni oda oluşturmak için + butonuna tıklayın',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: roomProvider.availableRooms.length,
                          itemBuilder: (context, index) {
                            final room = roomProvider.availableRooms[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 15),
                              color: Colors.white.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(15),
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.amber,
                                  child: Icon(Icons.group, color: Colors.black),
                                ),
                                title: Text(
                                  room.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${room.participants.length} kişi',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white54,
                                ),
                                onTap: () => _joinRoom(roomProvider, room.id),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _joinApp(RoomProvider roomProvider) async {
    await roomProvider.initialize(
      _nameController.text.trim(),
      avatarUrl: _selectedAvatarUrl,
      status: _statusController.text.trim(),
    );
    if (mounted) setState(() {}); // Giriş sonrası UI güncellensin
  }

  Future<void> _joinRoom(RoomProvider roomProvider, String roomId) async {
    Room? room;
    try {
      room = roomProvider.availableRooms.firstWhere((r) => r.id == roomId);
    } catch (_) {
      room = null;
    }
    String? password;
    String? inviteCode;
    if (room != null &&
        (((room.password ?? '').isNotEmpty) ||
            ((room.inviteCode ?? '').isNotEmpty))) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Odaya Katıl'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((room?.password ?? '').isNotEmpty)
                TextField(
                  controller: _joinPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Oda Şifresi'),
                ),
              if ((room?.inviteCode ?? '').isNotEmpty)
                TextField(
                  controller: _joinInviteCodeController,
                  decoration: const InputDecoration(labelText: 'Davet Kodu'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _joinPasswordController.clear();
                _joinInviteCodeController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                password = _joinPasswordController.text.trim().isNotEmpty
                    ? _joinPasswordController.text.trim()
                    : null;
                inviteCode = _joinInviteCodeController.text.trim().isNotEmpty
                    ? _joinInviteCodeController.text.trim()
                    : null;
                _joinPasswordController.clear();
                _joinInviteCodeController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Katıl'),
            ),
          ],
        ),
      );
    }
    await roomProvider.joinRoom(roomId,
        password: password, inviteCode: inviteCode);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const RoomScreen(),
        ),
      );
    }
  }

  void _showCreateRoomDialog(RoomProvider roomProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C1810),
        title: const Text(
          'Yeni Oda Oluştur',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _roomNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Oda adını girin',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _roomPasswordController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Oda şifresi (isteğe bağlı)',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _roomInviteCodeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Davet kodu (isteğe bağlı)',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_roomNameController.text.trim().isNotEmpty) {
                final newRoomId = await roomProvider.createRoom(
                  _roomNameController.text.trim(),
                  password: _roomPasswordController.text.trim().isNotEmpty
                      ? _roomPasswordController.text.trim()
                      : null,
                  inviteCode: _roomInviteCodeController.text.trim().isNotEmpty
                      ? _roomInviteCodeController.text.trim()
                      : null,
                );
                _roomNameController.clear();
                _roomPasswordController.clear();
                _roomInviteCodeController.clear();
                if (mounted) Navigator.of(context).pop();
                // Oda oluşturunca otomatik olarak oda ekranına geç
                if (newRoomId != null && mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RoomScreen(),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Oluştur', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _roomNameController.dispose();
    _roomPasswordController.dispose();
    _roomInviteCodeController.dispose();
    _joinPasswordController.dispose();
    _joinInviteCodeController.dispose();
    _statusController.dispose();
    super.dispose();
  }
}
