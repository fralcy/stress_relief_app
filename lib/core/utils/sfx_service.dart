import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'data_manager.dart';

/// Service quản lý sound effects cho toàn app
/// Singleton để đảm bảo chỉ có 1 instance
class SfxService {
  static final SfxService _instance = SfxService._internal();
  factory SfxService() => _instance;
  SfxService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _isEnabled = true;
  double _volume = 0.7; // Default 70%

  /// Map SFX types sang file paths
  static const Map<String, String> _sfxAssets = {
    'button_click': 'audio/sfx/button_click.mp3',
    'task_complete': 'audio/sfx/task_complete.mp3',
    'reward': 'audio/sfx/reward.mp3',
    'error': 'audio/sfx/error.mp3',
    'page_transition': 'audio/sfx/page_transition.mp3',
  };

  /// Khởi tạo service
  Future<void> initialize() async {
    // Load settings
    final settings = DataManager().userSettings;
    _isEnabled = settings.sfxEnabled;
    _volume = settings.sfxVolume / 100.0; // Convert 0-100 to 0.0-1.0

    // Set release mode để SFX chơi một lần rồi stop
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);

    // Set audio context để không tranh giành audio focus với BGM (không hỗ trợ trên web)
    if (!kIsWeb) {
      await _sfxPlayer.setAudioContext(AudioContext(
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
          audioFocus: AndroidAudioFocus.gainTransientMayDuck, // Short audio focus for SFX
        ),
      ));
    }
  }

  /// Chơi một sound effect
  Future<void> play(String sfxName) async {
    if (!_isEnabled) return;

    final assetPath = _sfxAssets[sfxName];
    if (assetPath != null) {
      await _sfxPlayer.stop(); // Stop SFX trước đó (nếu có)
      await _sfxPlayer.play(AssetSource(assetPath), volume: _volume);
    }
  }

  // ===== Shortcut methods cho từng loại SFX =====
  
  /// Button click - Dùng nhiều nhất
  Future<void> buttonClick() => play('button_click');

  /// Task complete - Hoàn thành công việc ✓
  Future<void> taskComplete() => play('task_complete');

  /// Reward - Nhận điểm/thành tựu 🎉
  Future<void> reward() => play('reward');

  /// Error - Thao tác sai/cảnh báo ⚠️
  Future<void> error() => play('error');

  /// Page transition - Chuyển màn hình 🔄
  Future<void> pageTransition() => play('page_transition');

  /// Đổi volume (0-100)
  void changeVolume(int volume) {
    _volume = volume / 100.0; // Convert 0-100 to 0.0-1.0
  }

  /// Bật/tắt SFX
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Dispose khi app đóng
  void dispose() {
    _sfxPlayer.dispose();
  }
}