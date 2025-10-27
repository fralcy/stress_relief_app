import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/l10n/app_localizations.dart';

/// Modal vẽ tranh
class DrawingModal extends StatefulWidget {
  const DrawingModal({super.key});

  @override
  State<DrawingModal> createState() => _DrawingModalState();

  /// Helper để show modal
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.art,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      content: const DrawingModal(),
    );
  }
}

class _DrawingModalState extends State<DrawingModal> {
  String _drawingName = 'My Drawing___';
  int _selectedColorIndex = 2; // Red được chọn mặc định

  // 32 màu: 8 hàng x 4 cột
  final List<Color> _colorPalette = [
    const Color(0xFF0066CC),
    const Color(0xFFFFFFFF),
    const Color(0xFFFF6B35),
    const Color(0xFFFFCC00),
    
    const Color(0xFF00AA00),
    const Color(0xFF00CC66),
    const Color(0xFF3366FF),
    const Color(0xFFCC66FF),
    
    const Color(0xFF996633),
    const Color(0xFF808080),
    const Color(0xFF000000),
    const Color(0xFFCC0066),
    
    const Color(0xFFFF99CC),
    const Color(0xFF66CCFF),
    const Color(0xFFFFFF99),
    const Color(0xFF99FF99),
    
    const Color(0xFFFF9999),
    const Color(0xFF9999FF),
    const Color(0xFFCCCCCC),
    const Color(0xFF663300),
    
    const Color(0xFF006666),
    const Color(0xFF660066),
    const Color(0xFFFF3300),
    const Color(0xFFFFFF00),
    
    const Color(0xFF00FF00),
    const Color(0xFF0000FF),
    const Color(0xFFFF00FF),
    const Color(0xFF00FFFF),
    
    const Color(0xFF333333),
    const Color(0xFF666666),
    const Color(0xFF999999),
    const Color(0xFFCCCCCC),
  ];

  void _onColorSelected(int index) {
    SfxService().buttonClick();
    setState(() {
      _selectedColorIndex = index;
    });
  }

  void _onClear() {
    SfxService().buttonClick();
    // TODO: Xóa canvas
    print('Clear canvas');
  }

  void _onUndo() {
    SfxService().buttonClick();
    // TODO: Hoàn tác
    print('Undo last stroke');
  }

  void _onSave() {
    SfxService().buttonClick();
    // TODO: Lưu bức tranh
    print('Save drawing');
  }

  void _onOpen() {
    SfxService().buttonClick();
    // TODO: Mở bức tranh đã lưu
    print('Open drawing');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ========== TOOLBAR: Tên + Actions ==========
        _buildToolbar(l10n, theme),
        
        const SizedBox(height: 16),
        
        // ========== CANVAS MOCKUP (64x64 grid) ==========
        _buildCanvas(theme),
        
        const SizedBox(height: 16),
        
        // ========== COLOR PALETTE LABEL ==========
        Text(
          l10n.colorPalette,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Selected color indicator
        Row(
          children: [
            Text(
              '${l10n.selected}: ',
              style: TextStyle(color: theme.text, fontSize: 14),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _colorPalette[_selectedColorIndex],
                border: Border.all(color: theme.border, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _getColorName(_selectedColorIndex),
              style: TextStyle(
                color: theme.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // ========== COLOR PALETTE GRID (8 rows x 4 cols) ==========
        _buildColorPalette(theme),
      ],
    );
  }

  Widget _buildToolbar(AppLocalizations l10n, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drawing name với icon
        Row(
          children: [
            Text(
              '${l10n.canvasName}: ',
              style: TextStyle(
                color: theme.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _drawingName,
              style: TextStyle(
                color: theme.text,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            const Text('✏️', style: TextStyle(fontSize: 16)),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AppButton(icon: Icons.clear, onPressed: _onClear, width: 56),
            AppButton(icon: Icons.undo, onPressed: _onUndo, width: 56),
            AppButton(icon: Icons.save, onPressed: _onSave, width: 56),
            AppButton(icon: Icons.folder_open, onPressed: _onOpen, width: 56),
          ],
        ),
      ],
    );
  }

  Widget _buildCanvas(dynamic theme) {
    return Container(
      width: double.infinity,
      height: 300, // Square-ish cho mobile
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: theme.border, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '64×64 Grid\n(mockup)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildColorPalette(dynamic theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 cột
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1, // Square cells
      ),
      itemCount: 32,
      itemBuilder: (context, index) {
        final isSelected = index == _selectedColorIndex;
        return GestureDetector(
          onTap: () => _onColorSelected(index),
          child: Container(
            decoration: BoxDecoration(
              color: _colorPalette[index],
              border: Border.all(
                color: isSelected ? Colors.red : theme.border,
                width: isSelected ? 3 : 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  String _getColorName(int index) {
    // Tên màu đơn giản cho demo
    const colorNames = [
      'Blue', 'White', 'Orange', 'Yellow',
      'Green', 'Cyan', 'Navy', 'Purple',
      'Brown', 'Gray', 'Black', 'Pink',
      'Rose', 'Sky', 'Cream', 'Mint',
      'Coral', 'Lavender', 'Silver', 'Dark Brown',
      'Teal', 'Violet', 'Red', 'Bright Yellow',
      'Lime', 'Indigo', 'Magenta', 'Aqua',
      'Dark', 'Mid Gray', 'Light Gray', 'Pale',
    ];
    return colorNames[index % colorNames.length];
  }
}