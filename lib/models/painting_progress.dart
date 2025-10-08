// Model cho bức tranh
class Painting{
  final String name;
  final DateTime createdAt;
  final List<List<String>> pixels; //Grid 64x64, mỗi cell là mã màu 8-bit

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
class PaintingProgress {
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