import '../providers/scene_provider.dart';
import '../providers/score_provider.dart';
import '../../models/scene_models.dart';
import '../constants/app_assets.dart';

/// Service để xử lý logic mua sắm scenes
class SceneShopService {
  final SceneProvider _sceneProvider;
  final ScoreProvider _scoreProvider;

  SceneShopService({
    required SceneProvider sceneProvider,
    required ScoreProvider scoreProvider,
  })  : _sceneProvider = sceneProvider,
        _scoreProvider = scoreProvider;

  /// Lấy thông tin tất cả scene collections cho shop
  List<SceneCollectionInfo> getSceneCollections() {
    return SceneSet.values.map((sceneSet) {
      Map<String, dynamic> info = AppAssets.sceneCollections[sceneSet]!;
      bool isUnlocked = _sceneProvider.isSceneSetUnlocked(sceneSet);
      bool isCurrentSet = _sceneProvider.getCurrentSceneSet() == sceneSet;
      bool canAfford = _sceneProvider.canAffordSceneSet(sceneSet);
      int unlockedCount = _sceneProvider.getUnlockedScenesCount(sceneSet);

      return SceneCollectionInfo(
        sceneSet: sceneSet,
        name: info['name'],
        price: info['price'],
        icon: info['icon'],
        description: info['description'],
        isUnlocked: isUnlocked,
        isCurrentSet: isCurrentSet,
        canAfford: canAfford,
        unlockedScenesCount: unlockedCount,
        totalScenesCount: SceneType.values.length,
      );
    }).toList();
  }

  /// Lấy thông tin chi tiết của một scene collection
  SceneCollectionInfo? getSceneCollectionInfo(SceneSet sceneSet) {
    Map<String, dynamic>? info = AppAssets.sceneCollections[sceneSet];
    if (info == null) return null;

    bool isUnlocked = _sceneProvider.isSceneSetUnlocked(sceneSet);
    bool isCurrentSet = _sceneProvider.getCurrentSceneSet() == sceneSet;
    bool canAfford = _sceneProvider.canAffordSceneSet(sceneSet);
    int unlockedCount = _sceneProvider.getUnlockedScenesCount(sceneSet);

    return SceneCollectionInfo(
      sceneSet: sceneSet,
      name: info['name'],
      price: info['price'],
      icon: info['icon'],
      description: info['description'],
      isUnlocked: isUnlocked,
      isCurrentSet: isCurrentSet,
      canAfford: canAfford,
      unlockedScenesCount: unlockedCount,
      totalScenesCount: SceneType.values.length,
    );
  }

  /// Mua scene collection
  Future<void> purchaseSceneCollection(SceneSet sceneSet) async {
    if (_sceneProvider.isSceneSetUnlocked(sceneSet)) return;

    int price = AppAssets.sceneCollections[sceneSet]?['price'] ?? 0;
    if (_scoreProvider.currentPoints < price) return;

    bool success = await _sceneProvider.purchaseSceneSet(sceneSet);
    if (success) _scoreProvider.refresh();
  }

  /// Chuyển sang sử dụng scene collection
  Future<void> useSceneCollection(SceneSet sceneSet) async {
    if (!_sceneProvider.isSceneSetUnlocked(sceneSet)) return;
    if (_sceneProvider.getCurrentSceneSet() == sceneSet) return;
    await _sceneProvider.changeCurrentSceneSet(sceneSet);
  }

  /// Lấy danh sách scenes trong một collection với trạng thái unlock
  List<SceneItemInfo> getSceneItemsInCollection(SceneSet sceneSet) {
    return SceneType.values.map((sceneType) {
      SceneKey sceneKey = SceneKey(sceneSet, sceneType);
      bool isUnlocked = _sceneProvider.isSceneUnlocked(sceneKey);
      String assetPath = AppAssets.sceneAssets[sceneSet]?[sceneType] ?? '';
      
      return SceneItemInfo(
        sceneKey: sceneKey,
        name: _getSceneTypeName(sceneType),
        assetPath: assetPath,
        isUnlocked: isUnlocked,
        price: 1000, // Fixed price per scene
      );
    }).toList();
  }

  /// Helper method để lấy tên hiển thị của SceneType  
  String _getSceneTypeName(SceneType sceneType) {
    // Return enum name for now, UI will handle localization
    return sceneType.toString().split('.').last;
  }
}

/// Model cho thông tin scene collection trong shop
class SceneCollectionInfo {
  final SceneSet sceneSet;
  final String name;
  final int price;
  final String icon;
  final String description;
  final bool isUnlocked;
  final bool isCurrentSet;
  final bool canAfford;
  final int unlockedScenesCount;
  final int totalScenesCount;

  SceneCollectionInfo({
    required this.sceneSet,
    required this.name,
    required this.price,
    required this.icon,
    required this.description,
    required this.isUnlocked,
    required this.isCurrentSet,
    required this.canAfford,
    required this.unlockedScenesCount,
    required this.totalScenesCount,
  });

  /// Getter để kiểm tra có phải collection miễn phí không
  bool get isFree => price == 0;

  /// Getter để kiểm tra unlock một phần
  bool get isPartiallyUnlocked => unlockedScenesCount > 0 && unlockedScenesCount < totalScenesCount;
}

/// Model cho thông tin scene item riêng lẻ
class SceneItemInfo {
  final SceneKey sceneKey;
  final String name;
  final String assetPath;
  final bool isUnlocked;
  final int price;

  SceneItemInfo({
    required this.sceneKey,
    required this.name,
    required this.assetPath,
    required this.isUnlocked,
    required this.price,
  });
}

