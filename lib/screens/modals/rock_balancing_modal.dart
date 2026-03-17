import 'package:flutter/material.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/l10n/app_localizations.dart';

/// Màn hình game chính: Xếp Đá (Rock Balancing).
/// Triển khai đầy đủ ở commit tiếp theo.
class RockBalancingModal extends StatefulWidget {
  final int rockCount;
  final int rockSeed;

  const RockBalancingModal({
    super.key,
    required this.rockCount,
    required this.rockSeed,
  });

  @override
  State<RockBalancingModal> createState() => _RockBalancingModalState();

  static Future<void> show(
    BuildContext context, {
    required int rockCount,
    required int rockSeed,
  }) {
    return AppModal.show(
      context: context,
      title: AppLocalizations.of(context).rockBalancing,
      maxHeight: MediaQuery.of(context).size.height * 0.95,
      minHeight: MediaQuery.of(context).size.height * 0.95,
      content: RockBalancingModal(rockCount: rockCount, rockSeed: rockSeed),
    );
  }
}

class _RockBalancingModalState extends State<RockBalancingModal>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    // TODO: implement full game in next commit
    return const Center(child: CircularProgressIndicator());
  }
}
