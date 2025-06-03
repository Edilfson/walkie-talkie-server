import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkie_talkie_app/screens/home_screen.dart';
import 'package:walkie_talkie_app/screens/settings_screen.dart';
import 'package:walkie_talkie_app/providers/room_provider.dart';
import 'package:walkie_talkie_app/providers/audio_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Push notification (background): ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('themeMode');
    setState(() {
      if (themeString == 'light')
        _themeMode = ThemeMode.light;
      else if (themeString == 'dark')
        _themeMode = ThemeMode.dark;
      else
        _themeMode = ThemeMode.system;
    });
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String value = 'system';
    if (mode == ThemeMode.light) value = 'light';
    if (mode == ThemeMode.dark) value = 'dark';
    await prefs.setString('themeMode', value);
  }

  void _onThemeChanged(ThemeMode mode) {
    setState(() => _themeMode = mode);
    _saveThemeMode(mode);
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Genel',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: MaterialApp(
        title: 'Walkie Talkie',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.amber,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.amber,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: _themeMode,
        home: HomeScreen(
          onOpenSettings: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  initialUrl: '',
                  onUrlChanged: (_) {},
                  initialThemeMode: _themeMode,
                  onThemeChanged: _onThemeChanged,
                ),
              ),
            );
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
