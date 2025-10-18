import 'package:audioplayers/audioplayers.dart';
import 'data_manager.dart';

/// Service quản lý background music cho toàn app
/// Singleton để đảm bảo chỉ có 1 instance nhạc chạy
class BgmService {
  static final BgmService _instance = BgmService._internal();
  factory BgmService() => _instance;
  BgmService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;
  String? _currentBgm;

  /// Map BGM name sang file path
  static const Map<String, String> _bgmAssets = {
    'Lofi Beats': 'audio/bgm/lofi_beats.mp3',
    'Rain Sounds': 'audio/bgm/rain_sounds.mp3',
    'Piano Music': 'audio/bgm/piano_music.mp3',
    'Acoustic Ballad': 'audio/bgm/acoustic_ballad.mp3',
    'Traditional Melodies': 'audio/bgm/traditional_melodies.mp3',
    'Indie Vibes': 'audio/bgm/indie_vibes.mp3',
    'Soft Pop': 'audio/bgm/soft_pop.mp3',
    'Chill Acoustic': 'audio/bgm/chill_acoustic.mp3',
  };

  /// Khởi tạo service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Set release mode để nhạc chạy liên tục
    await _player.setReleaseMode(ReleaseMode.loop);
    
    // Load settings và play nhạc
    final settings = DataManager().userSettings;
    await _applySettings(settings.bgm, settings.bgmVolume);
    
    _isInitialized = true;
  }

  /// Apply settings từ UserSettings
  Future<void> _applySettings(String bgm, int volume) async {
    _currentBgm = bgm;
    await _player.setVolume(volume / 100.0);
    
    final assetPath = _bgmAssets[bgm];
    if (assetPath != null) {
      await _player.play(AssetSource(assetPath));
    }
  }

  /// Đổi bài hát
  Future<void> changeBgm(String bgmName) async {
    if (!_isInitialized) await initialize();
    if (_currentBgm == bgmName) return;

    _currentBgm = bgmName;
    final assetPath = _bgmAssets[bgmName];
    
    if (assetPath != null) {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    }
  }

  /// Đổi volume (0-100)
  Future<void> changeVolume(int volume) async {
    if (!_isInitialized) await initialize();
    await _player.setVolume(volume / 100.0);
  }

  /// Pause nhạc
  Future<void> pause() async {
    if (!_isInitialized) return;
    await _player.pause();
  }

  /// Resume nhạc
  Future<void> resume() async {
    if (!_isInitialized) await initialize();
    await _player.resume();
  }

  /// Stop nhạc
  Future<void> stop() async {
    if (!_isInitialized) return;
    await _player.stop();
  }

  /// Dispose khi app đóng
  void dispose() {
    _player.dispose();
    _isInitialized = false;
  }
}