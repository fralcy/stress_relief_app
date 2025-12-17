import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/painting_service.dart';
import '../../core/widgets/pixel_canvas.dart';
import '../../models/painting_progress.dart';

/// Modal hiển thị gallery của các tranh
class GalleryModal extends StatefulWidget {
  final Function() onPaintingSelected;
  
  const GalleryModal({
    super.key,
    required this.onPaintingSelected,
  });

  @override
  State<GalleryModal> createState() => _GalleryModalState();

  /// Helper để show modal
  static Future<void> show(
    BuildContext context, {
    required Function() onPaintingSelected,
  }) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.gallery,
      maxHeight: MediaQuery.of(context).size.height * 0.8,
      content: GalleryModal(onPaintingSelected: onPaintingSelected),
    );
  }
}

class _GalleryModalState extends State<GalleryModal> {
  final PaintingService _paintingService = PaintingService();
  List<Painting> _paintings = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPaintings();
  }

  void _loadPaintings() {
    final progress = _paintingService.loadProgress();
    if (progress != null && progress.savedPaintings != null) {
      setState(() {
        _paintings = progress.savedPaintings!;
        _selectedIndex = progress.selected;
      });
    }
  }

  Future<void> _onSelectPainting(int index) async {
    SfxService().buttonClick();
    await _paintingService.selectPainting(index);
    
    // Đóng modal và notify parent để reload
    if (mounted) {
      Navigator.of(context).pop();
      widget.onPaintingSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    if (_paintings.isEmpty) {
      return Center(
        child: Text(
          'Không có tranh nào',
          style: TextStyle(color: theme.text),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.myPaintings,
            style: AppTypography.labelLarge(context, color: theme.text),
          ),
          const SizedBox(height: 16),
          
          // List của các tranh
          ..._paintings.asMap().entries.map((entry) {
            final index = entry.key;
            final painting = entry.value;
            final isSelected = index == _selectedIndex;
            
            return GestureDetector(
              onTap: () => _onSelectPainting(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? theme.primary.withOpacity(0.2)
                    : theme.background,
                  border: Border.all(
                    color: isSelected ? theme.primary : theme.border,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Preview canvas (thu nhỏ)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: PixelCanvas(
                          gridSize: 32,
                          pixels: painting.pixels,
                          selectedColorIndex: -1, // Disable painting
                          onPixelPaint: (_, __) {}, // No-op
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Tên tranh
                    Expanded(
                      child: Builder(
                        builder: (context) => Text(
                          painting.name,
                          style: AppTypography.labelLarge(context, color: theme.text),
                        ),
                      ),
                    ),
                    
                    // Indicator nếu đang chọn
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: theme.primary,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}