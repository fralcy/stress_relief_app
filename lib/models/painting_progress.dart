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
  final List<List<int>> pixels; // Grid 64x64, mỗi cell là số thứ tự của màu trong palette

  Painting({
    required this.name,
    required this.createdAt,
    required this.pixels,
  });

  Painting copyWith({
    String? name,
    DateTime? createdAt,
    List<List<int>>? pixels,
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

  @HiveField(1)
  final int selected; // Index của tranh đang chọn, mặc định là 0

  PaintingProgress({
    this.savedPaintings,
    this.selected = 0,
  });

  PaintingProgress copyWith({
    List<Painting>? savedPaintings,
    int? selected,
  }) {
    return PaintingProgress(
      savedPaintings: savedPaintings ?? this.savedPaintings,
      selected: selected ?? this.selected,
    );
  }
}