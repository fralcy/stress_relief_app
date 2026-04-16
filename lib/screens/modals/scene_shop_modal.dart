import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/providers/scene_provider.dart';
import '../../core/providers/score_provider.dart';
import '../../core/utils/scene_shop_service.dart';
import '../../core/utils/navigation_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/constants/app_assets.dart';
import '../../models/scene_models.dart';

/// Modal shop để mua và đổi scene collections
class SceneShopModal extends StatefulWidget {
  const SceneShopModal({super.key});

  /// Show scene shop modal
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.sceneShop,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      content: const SceneShopModal(),
    );
  }

  @override
  State<SceneShopModal> createState() => _SceneShopModalState();
}

class _SceneShopModalState extends State<SceneShopModal> {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Consumer2<SceneProvider, ScoreProvider>(
      builder: (context, sceneProvider, scoreProvider, child) {
        final shopService = SceneShopService(
          sceneProvider: sceneProvider,
          scoreProvider: scoreProvider,
        );
        final collections = shopService.getSceneCollections();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPointsDisplay(scoreProvider.currentPoints, theme),
            const SizedBox(height: 20),
            ...collections.map((c) => _buildCollectionCard(c, theme)),
          ],
        );
      },
    );
  }

  Widget _buildPointsDisplay(int currentPoints, AppTheme theme) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Text(
        '${l10n.yourPoints}: $currentPoints',
        textAlign: TextAlign.center,
        style: AppTypography.bodyLarge(context,
            color: theme.text, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCollectionCard(SceneCollectionInfo collection, AppTheme theme) {
    final l10n = AppLocalizations.of(context);
    final collectionName = switch (collection.sceneSet) {
      SceneSet.defaultSet  => l10n.cozyHome,
      SceneSet.forest      => l10n.forest,
      SceneSet.beach       => l10n.beach,
      SceneSet.peachBlossom => l10n.peachBlossom,
      SceneSet.desert      => l10n.desert,
      SceneSet.cosmic      => l10n.cosmic,
      SceneSet.castle      => l10n.castle,
      SceneSet.winter      => l10n.winter,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        title: collectionName,
        isExpandable: false,
        content: _buildCollectionContent(collection, theme),
      ),
    );
  }

  Widget _buildCollectionContent(SceneCollectionInfo collection, AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slider with left/right arrows — covers all 5 rooms
        _CollectionPreviewSlider(scenes: AppAssets.sceneAssets[collection.sceneSet]!),

        const SizedBox(height: 12),

        _buildCollectionInfo(collection, theme),

        const SizedBox(height: 16),

        _buildActionButtons(collection, theme),
      ],
    );
  }

  Widget _buildCollectionInfo(SceneCollectionInfo collection, AppTheme theme) {
    final l10n = AppLocalizations.of(context);
    final description = switch (collection.sceneSet) {
      SceneSet.defaultSet   => l10n.cozyHomeDesc,
      SceneSet.forest       => l10n.forestDesc,
      SceneSet.beach        => l10n.beachDesc,
      SceneSet.peachBlossom => l10n.peachBlossomDesc,
      SceneSet.winter       => l10n.winterDesc,
      SceneSet.desert       => l10n.desertDesc,
      SceneSet.cosmic       => l10n.cosmicDesc,
      SceneSet.castle       => l10n.castleDesc,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: AppTypography.bodyMedium(context, color: theme.text),
        ),

        const SizedBox(height: 8),

        if (collection.isFree) ...[
          _buildBadge(l10n.free),
        ] else if (!collection.isUnlocked) ...[
          Row(
            children: [
              Text(
                '${collection.price} ${l10n.points}',
                style: AppTypography.bodyLarge(context,
                    color: theme.primary, fontWeight: FontWeight.bold),
              ),
              if (!collection.canAfford) ...[
                const SizedBox(width: 8),
                Text(
                  '(${l10n.notEnoughPoints})',
                  style: AppTypography.bodySmall(context,
                      color: context.colorScheme.error),
                ),
              ],
            ],
          ),
        ] else ...[
          _buildBadge(l10n.ownedBadge),
        ],
      ],
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall(context,
            color: context.onSecondaryContainer, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButtons(SceneCollectionInfo collection, AppTheme theme) {
    final l10n = AppLocalizations.of(context);

    if (collection.isCurrentSet) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle,
                color: context.onSecondaryContainer, size: 16),
            const SizedBox(width: 8),
            Text(
              l10n.currentlyUsing,
              style: AppTypography.bodyMedium(context,
                  color: context.onSecondaryContainer,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    } else if (collection.isUnlocked) {
      return AppButton(
        icon: Icons.palette,
        label: l10n.useCollection,
        onPressed: () => _handleUseCollection(collection),
        width: double.infinity,
      );
    } else {
      return AppButton(
        icon: Icons.shopping_cart,
        label: collection.isFree ? l10n.free : l10n.buyCollection,
        onPressed: () => _handlePurchaseCollection(collection),
        isDisabled: !collection.canAfford && !collection.isFree,
        width: double.infinity,
      );
    }
  }

  Future<void> _handlePurchaseCollection(SceneCollectionInfo collection) async {
    final l10n = AppLocalizations.of(context);
    try {
      final sceneProvider = Provider.of<SceneProvider>(context, listen: false);
      final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
      await SceneShopService(
        sceneProvider: sceneProvider,
        scoreProvider: scoreProvider,
      ).purchaseSceneCollection(collection.sceneSet);
      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(l10n.purchaseSuccessful),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${l10n.purchaseFailed}: $e'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _handleUseCollection(SceneCollectionInfo collection) async {
    final l10n = AppLocalizations.of(context);
    try {
      final sceneProvider = Provider.of<SceneProvider>(context, listen: false);
      final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
      await SceneShopService(
        sceneProvider: sceneProvider,
        scoreProvider: scoreProvider,
      ).useSceneCollection(collection.sceneSet);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${l10n.operationFailed}: $e'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Slider with arrow navigation and auto-advance for scene collection previews
// ---------------------------------------------------------------------------

class _CollectionPreviewSlider extends StatefulWidget {
  final Map<SceneType, String> scenes;

  const _CollectionPreviewSlider({required this.scenes});

  @override
  State<_CollectionPreviewSlider> createState() =>
      _CollectionPreviewSliderState();
}

class _CollectionPreviewSliderState extends State<_CollectionPreviewSlider> {
  static const _roomOrder = [
    SceneType.livingRoom,
    SceneType.garden,
    SceneType.aquarium,
    SceneType.paintingRoom,
    SceneType.musicRoom,
  ];

  late final PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _pageController.animateToPage(
        (_currentPage + 1) % _roomOrder.length,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Navigate to a specific page and reset the auto-advance countdown.
  void _goTo(int page) {
    _timer.cancel();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _startTimer();
  }

  void _prev() => _goTo((_currentPage - 1 + _roomOrder.length) % _roomOrder.length);
  void _next() => _goTo((_currentPage + 1) % _roomOrder.length);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    final roomLabels = [
      l10n.livingRoom,
      l10n.garden,
      l10n.aquarium,
      l10n.paintingRoom,
      l10n.musicRoom,
    ];

    return Column(
      children: [
        // Image pager — no overlay
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemCount: _roomOrder.length,
              itemBuilder: (context, index) {
                final path = widget.scenes[_roomOrder[index]];
                if (path == null) return _placeholder();
                return Image.asset(
                  path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => _placeholder(),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Controls row: [←]  dots + room name  [→]
        Row(
          children: [
            _ArrowButton(icon: Icons.chevron_left_rounded, onTap: _prev),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_roomOrder.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 14 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? theme.primary : theme.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  // Room name
                  Text(
                    roomLabels[_currentPage],
                    style: AppTypography.bodySmall(context,
                        color: theme.text.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            _ArrowButton(icon: Icons.chevron_right_rounded, onTap: _next),
          ],
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.image_not_supported_outlined,
            color: Colors.grey.shade400, size: 32),
      );
}

// Semi-transparent arrow button overlaid on the image
class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: context.onPrimary, size: 22),
        ),
      ),
    );
  }
}
