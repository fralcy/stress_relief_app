import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'data_manager.dart';
import '../../models/music_progress.dart';

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

  // ==================== MUSIC MANAGEMENT ====================
  
  static const int defaultTrackCount = 5;
  final DataManager _dataManager = DataManager();

  /// Load progress hiện tại
  MusicProgress? loadProgress() {
    return _dataManager.musicProgress;
  }

  /// Khởi tạo 5 đoạn nhạc trống mặc định nếu chưa có
  Future<void> initializeDefaultTracks() async {
    final progress = loadProgress();
    
    // Nếu đã có đoạn nhạc rồi thì không cần init
    if (progress != null && progress.savedTracks.isNotEmpty) {
      return;
    }
    
    // Tạo 5 đoạn nhạc trống với tên "Nhạc 1", "Nhạc 2", ...
    final tracks = List.generate(
      defaultTrackCount,
      (index) => MusicTrack(
        name: 'Nhạc ${index + 1}',
        createdAt: DateTime.now(),
        tracks: _createEmptyTracks(),
      ),
    );
    
    final newProgress = MusicProgress(savedTracks: tracks, selected: 0);

    await _dataManager.saveMusicProgress(newProgress);
  }

  /// Lấy đoạn nhạc hiện tại đang làm việc (đầu tiên trong list)
  MusicTrack? getCurrentTrack() {
    final progress = loadProgress();
    if (progress == null || progress.savedTracks.isEmpty) {
      return null;
    }

    final idx = progress.selected;
    if (idx < 0 || idx >= progress.savedTracks.length) {
      return progress.savedTracks.first;
    }

    return progress.savedTracks[idx];
  }

  /// Tạo tracks trống cho tất cả nhạc cụ
  Map<Instrument, List<Note>> _createEmptyTracks() {
    return {
      for (Instrument instrument in Instrument.values)
        instrument: <Note>[],
    };
  }

  /// Lưu đoạn nhạc hiện tại
  Future<void> saveTrack(Map<Instrument, List<Note>> tracks, {String? name}) async {
    var progress = loadProgress();
    
    final musicTrack = MusicTrack(
      name: name ?? 'Track ${DateTime.now().toString()}',
      createdAt: DateTime.now(),
      tracks: tracks,
    );

    if (progress == null) {
      // Tạo mới progress
      progress = MusicProgress(savedTracks: [musicTrack], selected: 0);
    } else {
      final savedTracks = List<MusicTrack>.from(progress.savedTracks);

      if (savedTracks.isEmpty) {
        // Thêm track mới nếu chưa có track nào
        savedTracks.add(musicTrack);
      } else {
        final idx = progress.selected;
        if (idx >= 0 && idx < savedTracks.length) {
          // Update track đang chọn
          savedTracks[idx] = musicTrack;
        } else {
          // Fallback: thêm vào cuối
          savedTracks.add(musicTrack);
        }
      }

      progress = progress.copyWith(savedTracks: savedTracks);
    }

    await _dataManager.saveMusicProgress(progress);
  }

  /// Chọn track để làm việc (di chuyển lên đầu list)
  Future<void> selectTrack(int index) async {
    final progress = loadProgress();
    if (progress != null && index >= 0 && index < progress.savedTracks.length) {
      await _dataManager.saveMusicProgress(
        progress.copyWith(selected: index)
      );
    }
  }

  /// Update tên track hiện tại
  Future<void> updateCurrentTrackName(String newName) async {
    final progress = loadProgress();
    if (progress == null || progress.savedTracks.isEmpty) {
      return;
    }

    final savedTracks = List<MusicTrack>.from(progress.savedTracks);
    final idx = progress.selected;
    if (idx >= 0 && idx < savedTracks.length) {
      savedTracks[idx] = savedTracks[idx].copyWith(name: newName);
      await _dataManager.saveMusicProgress(
        progress.copyWith(savedTracks: savedTracks)
      );
    }
  }

  /// Clear track hiện tại
  Future<void> clearCurrentTrack() async {
    final current = getCurrentTrack();
    if (current != null) {
      await saveTrack(_createEmptyTracks(), name: current.name);
    }
  }

  /// Convert timeline từ composing modal sang tracks format
  Map<Instrument, List<Note>> convertTimelineToTracks(List<List<int?>> timeline, int bpm) {
    final tracks = <Instrument, List<Note>>{};
    
    // Tính thời gian giữa các beat (ms)
    final beatDurationMs = (60000 / bpm).round();
    
    // Mapping từ InstrumentType index sang Instrument
    const instrumentMapping = [
      Instrument.key,    // piano -> key
      Instrument.string, // guitar -> string  
      Instrument.synth,  // synth -> synth
      Instrument.bass,   // bass -> bass
      Instrument.drum,   // drum -> drum
    ];
    
    for (int instrumentIndex = 0; instrumentIndex < instrumentMapping.length; instrumentIndex++) {
      final instrument = instrumentMapping[instrumentIndex];
      final notes = <Note>[];
      
      for (int beatIndex = 0; beatIndex < timeline.length; beatIndex++) {
        if (instrumentIndex < timeline[beatIndex].length) {
          final noteValue = timeline[beatIndex][instrumentIndex];
          if (noteValue != null) {
            notes.add(Note(
              pitch: 'note_$noteValue',
              startTimeMilliseconds: beatIndex * beatDurationMs,
            ));
          }
        }
      }
      
      tracks[instrument] = notes;
    }
    
    return tracks;
  }

  /// Convert tracks format về timeline cho composing modal
  List<List<int?>> convertTracksToTimeline(Map<Instrument, List<Note>> tracks, int totalBeats, int bpm) {
    // Khởi tạo timeline trống
    final timeline = List.generate(
      totalBeats,
      (_) => List<int?>.filled(Instrument.values.length, null),
    );
    
    final beatDurationMs = (60000 / bpm).round();
    
    // Mapping từ pitch letter sang note value (C major scale)
    final pitchToValue = {
      'C': 1,
      'D': 2,
      'E': 3,
      'F': 4,
      'G': 5,
      'A': 6,
      'B': 7,
    };
    
    for (final entry in tracks.entries) {
      final instrument = entry.key;
      final notes = entry.value;
      final instrumentIndex = instrument.index;
      
      for (final note in notes) {
        final beatIndex = note.startTimeMilliseconds ~/ beatDurationMs;
        if (beatIndex < totalBeats) {
          // Extract note value từ pitch
          int? noteValue;
          
          // Nếu pitch là chữ cái (C, D, E...) từ samples
          if (pitchToValue.containsKey(note.pitch)) {
            noteValue = pitchToValue[note.pitch];
          } else {
            // Nếu pitch là 'note_1', 'note_2'... từ saved tracks
            final pitchStr = note.pitch.replaceAll('note_', '');
            noteValue = int.tryParse(pitchStr);
          }
          
          if (noteValue != null && noteValue >= 1 && noteValue <= 8) {
            timeline[beatIndex][instrumentIndex] = noteValue;
          }
        }
      }
    }
    
    return timeline;
  }
}