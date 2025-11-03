import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'data_manager.dart';

/// Service quản lý phát âm thanh nhạc cụ cho composing modal
/// Singleton để đảm bảo chỉ có 1 instance
class ComposingService {
  static final ComposingService _instance = ComposingService._internal();
  factory ComposingService() => _instance;
  ComposingService._internal();

  // Tạo nhiều AudioPlayer để phát đồng thời nhiều nhạc cụ
  final List<AudioPlayer> _players = [];
  bool _isInitialized = false;
  double _volume = 0.5; // Default, sẽ load từ settings

  /// Khởi tạo service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Load volume từ SFX settings
    final settings = DataManager().userSettings;
    _volume = settings.sfxVolume / 100.0; // Dùng chung với SFX
    
    // Tạo 5 players
    for (int i = 0; i < 5; i++) {
      final player = AudioPlayer();
      
      // Set audio context giống SFX
      await player.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceAccessibility,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ));
      
      await player.setReleaseMode(ReleaseMode.stop);
      _players.add(player);
    }
    
    _isInitialized = true;
  }

  /// Phát âm thanh nhạc cụ
  /// [instrument]: tên nhạc cụ (piano, guitar, synth, bass, drum)
  /// [note]: số từ 1-8
  /// [trackIndex]: index của track (0-4) để dùng player riêng
  Future<void> playNote(String instrument, int note, {int trackIndex = 0}) async {
    if (!_isInitialized) await initialize();
    if (note < 1 || note > 8) return;
    if (trackIndex < 0 || trackIndex >= _players.length) return;

    // Check xem SFX có bật không
    final settings = DataManager().userSettings;
    if (!settings.sfxEnabled) return;

    final path = 'audio/instruments/$instrument/$note.mp3';
    
    try {
      final player = _players[trackIndex];
      await player.stop();
      await player.play(AssetSource(path), volume: _volume);
    } catch (e) {
      // Ignore nếu file không tồn tại
    }
  }

  /// Cập nhật volume khi user thay đổi trong settings
  void updateVolume(int volume) {
    _volume = volume / 100.0;
  }

  /// Phát nhiều notes cùng lúc (cho playback)
  /// [notes]: Map từ instrument -> note number
  Future<void> playChord(Map<String, int> notes) async {
    if (!_isInitialized) await initialize();
    
    int trackIndex = 0;
    for (var entry in notes.entries) {
      if (trackIndex < _players.length) {
        await playNote(entry.key, entry.value, trackIndex: trackIndex);
        trackIndex++;
      }
    }
  }

  /// Stop tất cả nhạc
  Future<void> stopAll() async {
    if (!_isInitialized) return;
    for (var player in _players) {
      await player.stop();
    }
  }

  /// Dispose khi không dùng
  void dispose() {
    for (var player in _players) {
      player.dispose();
    }
    _players.clear();
    _isInitialized = false;
  }
}