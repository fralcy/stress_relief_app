import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/providers/scene_provider.dart';
import '../../core/providers/score_provider.dart';
import '../../core/utils/scene_shop_service.dart';
import '../../core/l10n/app_localizations.dart';
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
      maxHeight: MediaQuery.of(context).size.height * 0.8,
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
      child: Row(
        children: [
          Icon(
            Icons.stars,
            color: theme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            '${l10n.yourPoints}: $currentPoints',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
        ],
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
      case SceneSet.japanese:
        collectionName = l10n.japanese;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description and price info
        _buildCollectionInfo(collection, theme),
        
        const SizedBox(height: 16),
        
        // Action buttons
        _buildActionButtons(collection, theme),
      ],
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
      case SceneSet.japanese:
        description = l10n.japaneseDesc;
        break;
      case SceneSet.winter:
        description = l10n.winterDesc;
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: theme.text.withValues(alpha: 0.7),
          ),
        ),
        
        const SizedBox(height: 8),
        
        if (collection.isFree) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppLocalizations.of(context).free,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ] else ...[
          Row(
            children: [
              if (!collection.isUnlocked) ...[
                Text(
                  '${collection.price} ${AppLocalizations.of(context).points}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.primary,
                  ),
                ),
                if (!collection.canAfford) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${AppLocalizations.of(context).notEnoughPoints})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppLocalizations.of(context).ownedBadge,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
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
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green.shade700,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).currentlyUsing,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green.shade700,
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