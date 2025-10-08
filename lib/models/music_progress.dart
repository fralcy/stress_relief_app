// Các loại nhạc cụ
enum Instrument{
  key,
  string,
  synth,
  bass,
  drum
}
// Model cho nốt nhạc
class Note {
  final String pitch;
  final Duration startTime;

  Note({
    required this.pitch,
    required this.startTime,
  });

  Note copyWith({
    String? pitch,
    Duration? startTime,
    Duration? duration,
    Instrument? instrument,
  }) {
    return Note(
      pitch: pitch ?? this.pitch,
      startTime: startTime ?? this.startTime,
    );
  }
}
// Model cho bản nhạc
class MusicTrack{
  final String name;
  final DateTime createdAt;
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