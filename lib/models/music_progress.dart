import 'package:hive/hive.dart';

part 'music_progress.g.dart';

// Các loại nhạc cụ
@HiveType(typeId: 15)
enum Instrument {
  @HiveField(0)
  key,
  @HiveField(1)
  string,
  @HiveField(2)
  synth,
  @HiveField(3)
  bass,
  @HiveField(4)
  drum
}

// Model cho nốt nhạc
@HiveType(typeId: 16)
class Note {
  @HiveField(0)
  final String pitch;
  
  @HiveField(1)
  final int startTimeMilliseconds; // Lưu Duration dưới dạng milliseconds

  Note({
    required this.pitch,
    required this.startTimeMilliseconds,
  });

  // Helper getter để convert về Duration
  Duration get startTime => Duration(milliseconds: startTimeMilliseconds);

  Note copyWith({
    String? pitch,
    int? startTimeMilliseconds,
  }) {
    return Note(
      pitch: pitch ?? this.pitch,
      startTimeMilliseconds: startTimeMilliseconds ?? this.startTimeMilliseconds,
    );
  }
}

// Model cho bản nhạc
@HiveType(typeId: 17)
class MusicTrack {
  @HiveField(0)
  final String name;
  
  @HiveField(1)
  final DateTime createdAt;
  
  @HiveField(2)
  final Map<Instrument, List<Note>> tracks;

  MusicTrack({
    required this.name,
    required this.createdAt,
    required this.tracks,
  });

  MusicTrack copyWith({
    String? name,
    DateTime? createdAt,
    Map<Instrument, List<Note>>? tracks,
  }) {
    return MusicTrack(
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      tracks: tracks ?? this.tracks,
    );
  }
}

// Model cho tiến trình chơi nhạc
@HiveType(typeId: 7)
class MusicProgress {
  @HiveField(0)
  final List<MusicTrack> savedTracks;

  MusicProgress({
    required this.savedTracks,
  });
  
  MusicProgress copyWith({
    List<MusicTrack>? savedTracks,
  }) {
    return MusicProgress(
      savedTracks: savedTracks ?? this.savedTracks,
    );
  }
}