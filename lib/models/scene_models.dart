import 'package:hive/hive.dart';
part 'scene_models.g.dart';

/// Các bộ cảnh có thể unlock
@HiveType(typeId: 8)
enum SceneSet {
  @HiveField(0)
  defaultSet,  // Bộ mặc định ban đầu
  @HiveField(1)
  japanese,    // Phong cách Nhật Bản
  @HiveField(2)
  beach,       // Bãi biển nhiệt đới
  @HiveField(3)
  winter,      // Mùa đông tuyết trắng
  @HiveField(4)
  forest,      // Rừng cây xanh mát
}

/// 5 loại phòng trong app
@HiveType(typeId: 9)
enum SceneType {
  @HiveField(0)
  livingRoom,
  @HiveField(1)
  garden,
  @HiveField(2)
  aquarium,
  @HiveField(3)
  paintingRoom,
  @HiveField(4)
  musicRoom,
}

/// Lớp scene key cho việc lưu trữ
/// Dùng để map scene set + type thành một key duy nhất
@HiveType(typeId: 10)
class SceneKey {
  @HiveField(0)
  final SceneSet sceneSet;
  
  @HiveField(1)
  final SceneType sceneType;
  
  SceneKey(this.sceneSet, this.sceneType);

  // Getter
  SceneSet get getSceneSet => sceneSet;
  SceneType get getSceneType => sceneType;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SceneKey &&
        other.sceneSet == sceneSet &&
        other.sceneType == sceneType;
  }
  
  @override
  int get hashCode => sceneSet.hashCode ^ sceneType.hashCode;
}

/// Các biểu cảm của linh vật mèo
@HiveType(typeId: 11)
enum MascotExpression {
  @HiveField(0)
  idle,      // Trạng thái nghỉ
  @HiveField(1)
  happy,     // Vui vẻ
  @HiveField(2)
  calm,      // Bình tĩnh, thư giãn
  @HiveField(3)
  sad,       // Buồn
  @HiveField(4)
  sleepy,    // Buồn ngủ
  @HiveField(5)
  surprised, // Ngạc nhiên
}