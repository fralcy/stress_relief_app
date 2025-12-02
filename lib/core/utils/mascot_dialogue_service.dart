import 'dart:math';
import '../../models/scene_models.dart';
import '../l10n/app_localizations.dart';

/// Service quản lý dialogue của mascot
///
/// Features:
/// - Random dialogue selection without immediate repetition
/// - Scene-specific greetings and click dialogues
/// - Expression mapping (idle and happy only)
class MascotDialogueService {
  static final MascotDialogueService _instance = MascotDialogueService._internal();
  factory MascotDialogueService() => _instance;
  MascotDialogueService._internal();

  final _random = Random();
  final Map<SceneType, int> _lastGreetingVariants = {};
  final Map<SceneType, int> _lastClickVariants = {};

  /// Lấy dialogue chào mừng khi chuyển scene
  /// Trả về variant khác với lần trước (tránh lặp lại)
  String getSceneGreeting(SceneType scene, AppLocalizations l10n) {
    final variant = _getRandomVariant(_lastGreetingVariants, scene, 2);
    return l10n.getMascotSceneGreeting(scene, variant);
  }

  /// Lấy dialogue khi click vào mascot
  /// Trả về variant khác với lần trước (tránh lặp lại)
  String getClickDialogue(SceneType scene, AppLocalizations l10n) {
    final variant = _getRandomVariant(_lastClickVariants, scene, 2);
    return l10n.getMascotClickDialogue(scene, variant);
  }

  /// Lấy biểu cảm ngẫu nhiên (idle hoặc happy)
  MascotExpression getRandomExpression() {
    return _random.nextBool() ? MascotExpression.idle : MascotExpression.happy;
  }

  /// Lấy variant ngẫu nhiên, tránh lặp lại variant trước đó
  /// Nếu chưa có lịch sử, chọn ngẫu nhiên
  /// Nếu đã có lịch sử, chọn variant còn lại
  int _getRandomVariant(
    Map<SceneType, int> lastVariants,
    SceneType scene,
    int maxVariants,
  ) {
    final lastVariant = lastVariants[scene];
    int newVariant;

    if (lastVariant == null) {
      // Lần đầu tiên, chọn ngẫu nhiên
      newVariant = _random.nextInt(maxVariants);
    } else {
      // Đã có lịch sử, chọn variant còn lại (với maxVariants=2, đơn giản là đổi)
      newVariant = (lastVariant + 1) % maxVariants;
    }

    lastVariants[scene] = newVariant;
    return newVariant;
  }
}
