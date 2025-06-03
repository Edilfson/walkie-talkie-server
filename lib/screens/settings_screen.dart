import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final String initialUrl;
  final Function(String) onUrlChanged;
  final ThemeMode initialThemeMode;
  final Function(ThemeMode) onThemeChanged;
  const SettingsScreen({
    required this.initialUrl,
    required this.onUrlChanged,
    required this.initialThemeMode,
    required this.onThemeChanged,
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _controller;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl);
    _themeMode = widget.initialThemeMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Sunucu Adresi'),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('serverUrl', _controller.text);
                widget.onUrlChanged(_controller.text);
                Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
            const SizedBox(height: 24),
            const Text('Tema Seçimi',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              title: const Text('Sistem Varsayılanı'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: _themeMode,
                onChanged: (val) {
                  setState(() => _themeMode = val!);
                  widget.onThemeChanged(val!);
                },
              ),
            ),
            ListTile(
              title: const Text('Açık Tema'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: _themeMode,
                onChanged: (val) {
                  setState(() => _themeMode = val!);
                  widget.onThemeChanged(val!);
                },
              ),
            ),
            ListTile(
              title: const Text('Koyu Tema'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: _themeMode,
                onChanged: (val) {
                  setState(() => _themeMode = val!);
                  widget.onThemeChanged(val!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
