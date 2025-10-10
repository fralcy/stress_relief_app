import 'package:hive/hive.dart';

part 'painting_progress.g.dart';

// Model cho bức tranh
@HiveType(typeId: 14)
class Painting {
  @HiveField(0)
  final String name;
  
  @HiveField(1)
  final DateTime createdAt;
  
  @HiveField(2)
  final List<List<String>> pixels; // Grid 64x64, mỗi cell là mã màu 8-bit

  Painting({
    required this.name,
    required this.createdAt,
    required this.pixels,
  });

  Painting copyWith({
    String? name,
    DateTime? createdAt,
    List<List<String>>? pixels,
  }) {
    return Painting(
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      pixels: pixels ?? this.pixels,
    );
  }
}

// Model cho tiến trình mini-game vẽ tranh
@HiveType(typeId: 6)
class PaintingProgress {
  @HiveField(0)
  final List<Painting>? savedPaintings;

  PaintingProgress({
    this.savedPaintings,
  });

  PaintingProgress copyWith({
    List<Painting>? savedPaintings,
  }) {
    return PaintingProgress(
      savedPaintings: savedPaintings ?? this.savedPaintings,
    );
  }
}