import 'package:flutter/foundation.dart';
// Mobil için paketler
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
// Web için
import 'dart:html' as html;

class AudioProvider extends ChangeNotifier {
  // Ortak değişkenler
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isInitialized = false;
  String? _recordingPath;
  String? _audioUrl;

  // Mobil değişkenler
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;

  // Web değişkenleri
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _audioChunks = [];
  html.MediaStream? _stream;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;
  String? get recordingPath => _recordingPath;

  Future<void> initialize() async {
    if (kIsWeb) {
      _isInitialized = true;
      notifyListeners();
      return;
    }
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    await _recorder!.openRecorder();
    await _player!.openPlayer();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (kIsWeb) {
      try {
        if (html.window.navigator.mediaDevices != null) {
          _stream = await html.window.navigator.mediaDevices!
              .getUserMedia({'audio': true});
          _mediaRecorder = html.MediaRecorder(_stream!);
          _audioChunks = [];
          _mediaRecorder!.addEventListener('dataavailable', (event) {
            final data = (event as html.BlobEvent).data;
            if (data != null && data.size > 0) {
              _audioChunks.add(data);
            }
          });
          _mediaRecorder!.start();
          _isRecording = true;
          notifyListeners();
        }
      } catch (e) {
        print('Web mikrofon izni alınamadı: $e');
        _isRecording = false;
        notifyListeners();
      }
      return;
    }
    // Mobil (Android/iOS)
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _isRecording = false;
      notifyListeners();
      return;
    }
    await _recorder!.startRecorder(toFile: 'audio.aac', codec: Codec.aacADTS);
    _isRecording = true;
    notifyListeners();
  }

  Future<String?> stopRecording() async {
    if (kIsWeb) {
      if (_mediaRecorder != null && _isRecording) {
        final completer = Completer<String?>();
        void onStopHandler(event) async {
          final blob = html.Blob(_audioChunks, 'audio/webm');
          // Base64 olarak oku
          final reader = html.FileReader();
          reader.readAsDataUrl(blob);
          await reader.onLoad.first;
          final base64 = reader.result as String;
          _audioUrl = base64;
          _recordingPath = base64;
          _stream?.getTracks().forEach((track) => track.stop());
          completer.complete(base64);
          _mediaRecorder!.removeEventListener('stop', onStopHandler);
          notifyListeners();
        }

        _mediaRecorder!.addEventListener('stop', onStopHandler);
        _mediaRecorder!.stop();
        _isRecording = false;
        notifyListeners();
        return completer.future;
      }
      _isRecording = false;
      notifyListeners();
      return null;
    }
    // Mobil (Android/iOS)
    if (_isRecording) {
      String? path = await _recorder!.stopRecorder();
      _isRecording = false;
      _recordingPath = path;
      notifyListeners();
      return path;
    }
    _isRecording = false;
    notifyListeners();
    return null;
  }

  Future<void> playAudio(String? path) async {
    if (kIsWeb) {
      if (path == null) return;

      try {
        html.AudioElement? audio;

        // Eğer base64 ile başlıyorsa, önce blob oluştur sonra URL'e çevir
        if (path.startsWith('data:audio')) {
          // Base64'ü blob'a çevir
          final response = await html.window.fetch(path);
          final blob = await response.blob();
          final blobUrl = html.Url.createObjectUrl(blob);

          audio = html.AudioElement(blobUrl);

          // Oynatma bittiğinde blob URL'yi temizle
          audio.onEnded.listen((_) {
            html.Url.revokeObjectUrl(blobUrl);
          });
        } else {
          // Normal URL ise direkt kullan
          audio = html.AudioElement(path);
        }

        _isPlaying = true;
        notifyListeners();

        // Ses oynatmaya başla
        await audio.play();
        await audio.onEnded.first;

        _isPlaying = false;
        notifyListeners();
        return;
      } catch (e) {
        print('Audio playback error: $e');
        _isPlaying = false;
        notifyListeners();
        return;
      }
    }
    // Mobil (Android/iOS)
    if (path == null) return;
    _isPlaying = true;
    notifyListeners();
    await _player!.startPlayer(
        fromURI: path,
        codec: Codec.aacADTS,
        whenFinished: () {
          _isPlaying = false;
          notifyListeners();
        });
  }

  Future<void> stopPlaying() async {
    if (kIsWeb) {
      _isPlaying = false;
      notifyListeners();
      return;
    }
    await _player?.stopPlayer();
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _recorder?.closeRecorder();
      _player?.closePlayer();
    }
    super.dispose();
  }
}
