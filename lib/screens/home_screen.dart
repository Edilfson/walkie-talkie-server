import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../providers/audio_provider.dart';
import 'room_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();
  bool _isInitialized = false;
  bool _isNameValid = false;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final newIsValid = _nameController.text.trim().isNotEmpty;
    print('Name changed: "${_nameController.text}", valid: $newIsValid');
    setState(() {
      _isNameValid = newIsValid;
    });
  }

  Future<void> _initializeAudio() async {
    await context.read<AudioProvider>().initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C1810),
              Color(0xFF1A0F08),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Consumer<RoomProvider>(
              builder: (context, roomProvider, child) {
                if (!roomProvider.isConnected) {
                  return _buildLoginScreen(roomProvider);
                }
                return _buildRoomListScreen(roomProvider);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginScreen(RoomProvider roomProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.radio,
          size: 100,
          color: Colors.amber,
        ),
        const SizedBox(height: 20),
        const Text(
          'Walkie Talkie',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Anında sesli iletişim',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 50),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Adınızı girin',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.person, color: Colors.amber),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isInitialized && _isNameValid
                ? () {
                    print(
                        'Button pressed! Name valid: $_isNameValid, Initialized: $_isInitialized');
                    _joinApp(roomProvider);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  (_isInitialized && _isNameValid) ? Colors.amber : Colors.grey,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _isInitialized
                ? const Text(
                    'Uygulamaya Gir',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  )
                : const CircularProgressIndicator(color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomListScreen(RoomProvider roomProvider) {
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
            IconButton(
              onPressed: () => _showCreateRoomDialog(roomProvider),
              icon: const Icon(Icons.add_circle, color: Colors.amber, size: 32),
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
  }

  Future<void> _joinApp(RoomProvider roomProvider) async {
    print('Join app called with name: ${_nameController.text.trim()}');
    await roomProvider.initialize(_nameController.text.trim());
    print('Room provider initialized');
  }

  Future<void> _joinRoom(RoomProvider roomProvider, String roomId) async {
    await roomProvider.joinRoom(roomId);
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
        content: TextField(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_roomNameController.text.trim().isNotEmpty) {
                final newRoomId = await roomProvider
                    .createRoom(_roomNameController.text.trim());
                _roomNameController.clear();
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
    super.dispose();
  }
}
