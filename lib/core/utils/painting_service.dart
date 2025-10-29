import '../../models/painting_progress.dart';
import '../constants/drawing_palette.dart';
import 'data_manager.dart';

class PaintingService {
  static const int defaultGridSize = 32;
  static const int defaultPaintingCount = 5;
  
  final DataManager _dataManager = DataManager();

  // Load progress hiện tại
  PaintingProgress? loadProgress() {
    return _dataManager.paintingProgress;
  }

  // Khởi tạo 5 tranh trống mặc định nếu chưa có
  Future<void> initializeDefaultPaintings() async {
    final progress = loadProgress();
    
    // Nếu đã có tranh rồi thì không cần init
    if (progress != null && 
        progress.savedPaintings != null && 
        progress.savedPaintings!.isNotEmpty) {
      return;
    }
    
    // Tạo 5 tranh trống với tên "Tranh 1", "Tranh 2", ...
    final paintings = List.generate(
      defaultPaintingCount,
      (index) => Painting(
        name: 'Tranh ${index + 1}',
        createdAt: DateTime.now(),
        pixels: createEmptyGrid(),
      ),
    );
    
    final newProgress = PaintingProgress(
      savedPaintings: paintings,
      selected: 0,
    );
    
    await _dataManager.savePaintingProgress(newProgress);
  }

  // Lấy tranh hiện tại đang làm việc
  Painting? getCurrentPainting() {
    final progress = loadProgress();
    if (progress == null || 
        progress.savedPaintings == null || 
        progress.savedPaintings!.isEmpty) {
      return null;
    }
    
    final index = progress.selected;
    if (index >= progress.savedPaintings!.length) {
      return progress.savedPaintings!.first;
    }
    
    return progress.savedPaintings![index];
  }

  // Tạo tranh mới (grid trống với -1)
  List<List<int>> createEmptyGrid() {
    return List.generate(
      defaultGridSize,
      (_) => List.generate(defaultGridSize, (_) => DrawingPalette.emptyIndex),
    );
  }

  // Lưu tranh hiện tại
  Future<void> savePainting(List<List<int>> pixels, {String? name}) async {
    var progress = loadProgress();
    
    final painting = Painting(
      name: name ?? 'Painting ${DateTime.now().toString()}',
      createdAt: DateTime.now(),
      pixels: pixels,
    );

    if (progress == null) {
      // Tạo mới progress
      progress = PaintingProgress(
        savedPaintings: [painting],
        selected: 0,
      );
    } else {
      final paintings = List<Painting>.from(progress.savedPaintings ?? []);
      
      if (paintings.isEmpty) {
        // Thêm tranh mới nếu chưa có tranh nào
        paintings.add(painting);
      } else {
        // Update tranh đang chọn
        final index = progress.selected;
        if (index < paintings.length) {
          paintings[index] = painting;
        } else {
          paintings.add(painting);
        }
      }
      
      progress = progress.copyWith(savedPaintings: paintings);
    }

    await _dataManager.savePaintingProgress(progress);
  }

  // Chọn tranh để làm việc
  Future<void> selectPainting(int index) async {
    final progress = loadProgress();
    if (progress != null && 
        progress.savedPaintings != null &&
        index < progress.savedPaintings!.length) {
      await _dataManager.savePaintingProgress(
        progress.copyWith(selected: index)
      );
    }
  }

  // Update tên tranh hiện tại
  Future<void> updateCurrentPaintingName(String newName) async {
    final progress = loadProgress();
    if (progress == null || 
        progress.savedPaintings == null || 
        progress.savedPaintings!.isEmpty) {
      return;
    }
    
    final paintings = List<Painting>.from(progress.savedPaintings!);
    final index = progress.selected;
    
    if (index < paintings.length) {
      paintings[index] = paintings[index].copyWith(name: newName);
      await _dataManager.savePaintingProgress(
        progress.copyWith(savedPaintings: paintings)
      );
    }
  }

  // Clear canvas hiện tại
  Future<void> clearCurrentCanvas() async {
    final current = getCurrentPainting();
    if (current != null) {
      await savePainting(createEmptyGrid(), name: current.name);
    }
  }
}