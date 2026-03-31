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
  final Set<SceneSet> _expandedSets = {};

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    
    return Consumer2<SceneProvider, ScoreProvider>(
      builder: (context, sceneProvider, scoreProvider, child) {
        // Create fresh service instance with current providers for reactive updates
        final shopService = SceneShopService(
          sceneProvider: sceneProvider,
          scoreProvider: scoreProvider,
        );
        final collections = shopService.getSceneCollections();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points display
            _buildPointsDisplay(scoreProvider.currentPoints, theme),
            
            const SizedBox(height: 20),
            
            // Collections list - rebuild each time for reactive state
            ...collections.map((collection) => 
              _buildCollectionCard(collection, theme)
            ),
          ],
        );
      },
    );
  }

  Widget _buildPointsDisplay(int currentPoints, AppTheme theme) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Text(
        '${l10n.yourPoints}: $currentPoints',
        style: AppTypography.bodyLarge(context,
          color: theme.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCollectionCard(SceneCollectionInfo collection, AppTheme theme) {
    final l10n = AppLocalizations.of(context);
    String collectionName;
    
    // Map scene sets to localized names
    switch (collection.sceneSet) {
      case SceneSet.defaultSet:
        collectionName = l10n.cozyHome;
        break;
      case SceneSet.forest:
        collectionName = l10n.forest;
        break;
      case SceneSet.beach:
        collectionName = l10n.beach;
        break;
      case SceneSet.peachBlossom:
        collectionName = l10n.peachBlossom;
        break;
      case SceneSet.desert:
        collectionName = l10n.desert;
        break;
      case SceneSet.cosmic:
        collectionName = l10n.cosmic;
        break;
      case SceneSet.castle:
        collectionName = l10n.castle;
        break;
      case SceneSet.winter:
        collectionName = l10n.winter;
        break;
    }
    
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
    final isExpanded = _expandedSets.contains(collection.sceneSet);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Living room preview thumbnail
        _buildLivingRoomPreview(collection),

        const SizedBox(height: 12),

        // Description and price info
        _buildCollectionInfo(collection, theme),

        const SizedBox(height: 16),

        // Action buttons
        _buildActionButtons(collection, theme),

        const SizedBox(height: 4),

        Divider(color: theme.border, height: 1),

        // Expand toggle
        _buildExpandToggle(collection, theme, isExpanded),

        // Remaining 4 rooms grid (animated)
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildRoomsGrid(collection),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildLivingRoomPreview(SceneCollectionInfo collection) {
    final path = AppAssets.sceneAssets[collection.sceneSet]![SceneType.livingRoom]!;
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, e, stack) => _buildImagePlaceholder(),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 32),
      ),
    );
  }

  Widget _buildExpandToggle(SceneCollectionInfo collection, AppTheme theme, bool isExpanded) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedSets.remove(collection.sceneSet);
          } else {
            _expandedSets.add(collection.sceneSet);
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isExpanded ? l10n.scenePreviewCollapse : l10n.scenePreviewExpand,
              style: AppTypography.bodySmall(context, color: theme.text.withValues(alpha: 0.6)),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.keyboard_arrow_down, size: 16, color: theme.text.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsGrid(SceneCollectionInfo collection) {
    final scenes = AppAssets.sceneAssets[collection.sceneSet]!;
    final types = [SceneType.garden, SceneType.aquarium, SceneType.paintingRoom, SceneType.musicRoom];
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildRoomThumbnail(scenes[types[0]]!)),
            const SizedBox(width: 6),
            Expanded(child: _buildRoomThumbnail(scenes[types[1]]!)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _buildRoomThumbnail(scenes[types[2]]!)),
            const SizedBox(width: 6),
            Expanded(child: _buildRoomThumbnail(scenes[types[3]]!)),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomThumbnail(String path) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, e, stack) => _buildImagePlaceholder(),
        ),
      ),
    );
  }

  Widget _buildCollectionInfo(SceneCollectionInfo collection, AppTheme theme) {
    final l10n = AppLocalizations.of(context);
    String description;
    
    // Map scene sets to localized descriptions
    switch (collection.sceneSet) {
      case SceneSet.defaultSet:
        description = l10n.cozyHomeDesc;
        break;
      case SceneSet.forest:
        description = l10n.forestDesc;
        break;
      case SceneSet.beach:
        description = l10n.beachDesc;
        break;
      case SceneSet.peachBlossom:
        description = l10n.peachBlossomDesc;
        break;
      case SceneSet.winter:
        description = l10n.winterDesc;
        break;
      case SceneSet.desert:
        description = l10n.desertDesc;
        break;
      case SceneSet.cosmic:
        description = l10n.cosmicDesc;
        break;
      case SceneSet.castle:
        description = l10n.castleDesc;
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: AppTypography.bodyMedium(context,
            color: theme.text.withValues(alpha: 0.7),
          ),
        ),
        
        const SizedBox(height: 8),
        
        if (collection.isFree) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppLocalizations.of(context).free,
              style: AppTypography.bodySmall(context,
                color: context.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ] else ...[
          Row(
            children: [
              if (!collection.isUnlocked) ...[
                Text(
                  '${collection.price} ${AppLocalizations.of(context).points}',
                  style: AppTypography.bodyLarge(context,
                    color: theme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!collection.canAfford) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${AppLocalizations.of(context).notEnoughPoints})',
                    style: AppTypography.bodySmall(context,
                      color: context.colorScheme.error,
                    ),
                  ),
                ],
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppLocalizations.of(context).ownedBadge,
                    style: AppTypography.bodySmall(context,
                      color: context.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(SceneCollectionInfo collection, AppTheme theme) {
    if (collection.isCurrentSet) {
      // Already using this set
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: context.onSecondaryContainer,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).currentlyUsing,
              style: AppTypography.bodyMedium(context,
                color: context.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (collection.isUnlocked) {
      // Can switch to this set
      return AppButton(
        icon: Icons.palette,
        label: AppLocalizations.of(context).useCollection,
        onPressed: () => _handleUseCollection(collection),
        width: double.infinity,
      );
    } else {
      // Need to buy this set
      return AppButton(
        icon: Icons.shopping_cart,
        label: collection.isFree ? AppLocalizations.of(context).free : AppLocalizations.of(context).buyCollection,
        onPressed: () => _handlePurchaseCollection(collection),
        isDisabled: !collection.canAfford && !collection.isFree,
        width: double.infinity,
      );
    }
  }



  Future<void> _handlePurchaseCollection(SceneCollectionInfo collection) async {
    try {
      final sceneProvider = Provider.of<SceneProvider>(context, listen: false);
      final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
      final shopService = SceneShopService(
        sceneProvider: sceneProvider,
        scoreProvider: scoreProvider,
      );
      
      await shopService.purchaseSceneCollection(collection.sceneSet);
      // Providers will automatically notify listeners and update UI
      // No manual setState needed due to Consumer2 watching providers
    } catch (e) {
      // Silent fail for performance
    }
  }

  Future<void> _handleUseCollection(SceneCollectionInfo collection) async {
    try {
      final sceneProvider = Provider.of<SceneProvider>(context, listen: false);
      final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
      final shopService = SceneShopService(
        sceneProvider: sceneProvider,
        scoreProvider: scoreProvider,
      );
      
      await shopService.useSceneCollection(collection.sceneSet);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Silent fail for performance
    }
  }
}