import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/constants/drawing_templates.dart';
import '../../core/widgets/pixel_canvas.dart';
import '../../models/painting_progress.dart';

/// Modal hiển thị các template lineart cho vẽ tranh
class TemplatesModal extends StatefulWidget {
  final Function(Painting) onTemplateSelected;
  
  const TemplatesModal({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  State<TemplatesModal> createState() => _TemplatesModalState();

  /// Helper để show modal
  static Future<void> show(
    BuildContext context, {
    required Function(Painting) onTemplateSelected,
  }) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.templates,
      maxHeight: MediaQuery.of(context).size.height * 0.8,
      content: TemplatesModal(onTemplateSelected: onTemplateSelected),
    );
  }
}

class _TemplatesModalState extends State<TemplatesModal> {
  Future<void> _onSelectTemplate(Painting template) async {
    SfxService().buttonClick();
    
    final l10n = AppLocalizations.of(context);
    
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.useTemplate),
        content: Text(l10n.currentWillBeReplaced('drawing')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      // Đóng modal và notify parent
      Navigator.of(context).pop();
      widget.onTemplateSelected(template);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final templates = DrawingTemplates.getTemplates(l10n);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.selectTemplate,
            style: AppTypography.labelLarge(context, color: theme.text),
          ),
          const SizedBox(height: 16),
          
          // Grid layout 2 cột
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              
              return GestureDetector(
                onTap: () => _onSelectTemplate(template),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.background,
                    border: Border.all(color: theme.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Preview canvas
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: PixelCanvas(
                                gridSize: 32,
                                pixels: template.pixels,
                                selectedColorIndex: -1, // Disable painting
                                onPixelPaint: (_, __) {}, // No-op
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Template name - hiển thị thẳng trên card
                      Text(
                        template.name,
                        style: AppTypography.labelMedium(context, color: theme.text),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
