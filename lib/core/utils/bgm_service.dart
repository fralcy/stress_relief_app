import 'package:audioplayers/audioplayers.dart';
import 'data_manager.dart';

/// Service quản lý background music cho toàn app
/// Singleton để đảm bảo chỉ có 1 instance nhạc chạy
class BgmService {
  static final BgmService _instance = BgmService._internal();
  factory BgmService() => _instance;
  BgmService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _isInitialized = false;
  String? _currentBgm;
  double _currentVolume = 0.5; // Track current volume (0.0-1.0)

  /// Map BGM name sang file path
  static const Map<String, String> _bgmAssets = {
    'Lofi Beats': 'audio/bgm/lofi_beats.mp3',
    'Rain Sounds': 'audio/bgm/rain_sounds.mp3',
    'Piano Music': 'audio/bgm/piano_music.mp3',
    'Acoustic Ballad': 'audio/bgm/acoustic_ballad.mp3',
    'Folk Song': 'audio/bgm/folk_song.mp3',
    'Indie Vibes': 'audio/bgm/indie_vibes.mp3',
    'Soft Pop': 'audio/bgm/soft_pop.mp3',
    'Chill Acoustic': 'audio/bgm/chill_acoustic.mp3',
  };

  /// Khởi tạo service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Set release mode để nhạc chạy liên tục
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    
    // Set audio context cho background music
    await _bgmPlayer.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain, // Giữ audio focus cho BGM
      ),
    ));
    
    // Load settings và play nhạc
    final settings = DataManager().userSettings;
    await _applySettings(settings.bgm, settings.bgmVolume);
    
    _isInitialized = true;
  }

  /// Apply settings từ UserSettings
  Future<void> _applySettings(String bgm, int volume) async {
    _currentBgm = bgm;
    _currentVolume = volume / 100.0;
    await _bgmPlayer.setVolume(_currentVolume);

    final assetPath = _bgmAssets[bgm];
    if (assetPath != null) {
      await _bgmPlayer.play(AssetSource(assetPath));
    }
  }

  /// Đổi bài hát
  Future<void> changeBgm(String bgmName) async {
    if (!_isInitialized) await initialize();
    if (_currentBgm == bgmName) return;

    _currentBgm = bgmName;
    final assetPath = _bgmAssets[bgmName];
    
    if (assetPath != null) {
      await _bgmPlayer.stop();
      await _bgmPlayer.play(AssetSource(assetPath));
    }
  }

  /// Đổi volume (0-100)
  Future<void> changeVolume(int volume) async {
    if (!_isInitialized) await initialize();
    _currentVolume = volume / 100.0;
    await _bgmPlayer.setVolume(_currentVolume);
  }

  /// Pause nhạc
  Future<void> pause() async {
    if (!_isInitialized) return;
    await _bgmPlayer.pause();
  }

  /// Resume nhạc
  Future<void> resume() async {
    if (!_isInitialized) await initialize();
    await _bgmPlayer.resume();
  }

  /// Stop nhạc
  Future<void> stop() async {
    if (!_isInitialized) return;
    await _bgmPlayer.stop();
  }

  /// Fade out BGM over duration then stop
  /// Used by Sleep Guide timer for smooth transition
  Future<void> fadeOutAndStop(Duration fadeDuration) async {
    if (!_isInitialized) return;

    final originalVolume = _currentVolume;
    const steps = 20; // 20 volume steps for smooth fade
    final stepDuration = fadeDuration.inMilliseconds ~/ steps;

    // Gradually reduce volume to 0
    for (int i = steps; i > 0; i--) {
      await _bgmPlayer.setVolume((originalVolume * i) / steps);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }

    // Stop playback
    await _bgmPlayer.stop();

    // Restore original volume for next playback
    _currentVolume = originalVolume;
    await _bgmPlayer.setVolume(_currentVolume);
  }

  /// Dispose khi app đóng
  void dispose() {
    _bgmPlayer.dispose();
    _isInitialized = false;
  }
}