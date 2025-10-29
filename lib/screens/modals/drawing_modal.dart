import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/constants/drawing_palette.dart';
import '../../core/widgets/pixel_canvas.dart';
import '../../core/utils/painting_service.dart';
import 'gallery_modal.dart';

/// Modal vẽ tranh
class DrawingModal extends StatefulWidget {
  const DrawingModal({super.key});

  @override
  State<DrawingModal> createState() => _DrawingModalState();

  /// Helper để show modal
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    // Init default paintings nếu chưa có
    await PaintingService().initializeDefaultPaintings();
    
    if (!context.mounted) return;
    
    return AppModal.show(
      context: context,
      title: l10n.art,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      content: const DrawingModal(),
    );
  }
}

class _DrawingModalState extends State<DrawingModal> {
  final PaintingService _paintingService = PaintingService();
  final TextEditingController _nameController = TextEditingController();
  
  late List<List<int>> _pixels;
  int _selectedColorIndex = 0;
  String _drawingName = 'My Drawing';
  bool _isLoading = true;
  bool _isEditingName = false;
  
  // Undo history
  final List<List<List<int>>> _history = [];
  static const int _maxHistorySize = 20;
  
  // Scroll control
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    _loadPainting();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadPainting() {
    final painting = _paintingService.getCurrentPainting();
    
    if (painting != null) {
      setState(() {
        _pixels = painting.pixels.map((row) => List<int>.from(row)).toList();
        _drawingName = painting.name;
        _nameController.text = painting.name;
        _isLoading = false;
      });
    } else {
      // Tạo mới nếu chưa có
      setState(() {
        _pixels = _paintingService.createEmptyGrid();
        _nameController.text = _drawingName;
        _isLoading = false;
      });
    }
    
    // Save initial state to history
    _saveToHistory();
  }
  
  void _saveToHistory() {
    final snapshot = _pixels.map((row) => List<int>.from(row)).toList();
    _history.add(snapshot);
    
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
    }
  }

  void _onPixelPaint(int row, int col) {
    if (_pixels[row][col] == _selectedColorIndex) return;
    
    _saveToHistory();
    
    setState(() {
      _pixels[row][col] = _selectedColorIndex;
    });
    
    // Auto-save
    _paintingService.savePainting(_pixels, name: _drawingName);
  }
  
  void _onUndo() {
    SfxService().buttonClick();
    
    if (_history.length <= 1) return;
    
    _history.removeLast();
    
    final previousState = _history.last;
    setState(() {
      _pixels = previousState.map((row) => List<int>.from(row)).toList();
    });
    
    // Auto-save
    _paintingService.savePainting(_pixels, name: _drawingName);
  }

  void _onColorSelected(int index) {
    SfxService().buttonClick();
    setState(() {
      _selectedColorIndex = index;
    });
  }

  void _onClear() {
    SfxService().buttonClick();
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearCanvas),
        content: Text(l10n.thisWillEraseEverything),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveToHistory();
              setState(() {
                _pixels = _paintingService.createEmptyGrid();
              });
              _paintingService.clearCurrentCanvas();
            },
            child: Text(l10n.clearCanvasWarning),
          ),
        ],
      ),
    );
  }

  Future<void> _onOpen() async {
    SfxService().buttonClick();
    
    // Show gallery modal
    await GalleryModal.show(
      context,
      onPaintingSelected: () {
        // Reload painting khi chọn tranh mới
        setState(() {
          _isLoading = true;
        });
        _loadPainting();
      },
    );
  }

  void _onEditName() {
    SfxService().buttonClick();
    setState(() {
      _isEditingName = true;
    });
  }

  Future<void> _onSaveName() async {
    SfxService().buttonClick();
    
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _nameController.text = _drawingName;
      setState(() {
        _isEditingName = false;
      });
      return;
    }
    
    setState(() {
      _drawingName = newName;
      _isEditingName = false;
    });
    
    // Save name
    await _paintingService.updateCurrentPaintingName(newName);
    
    // Re-save painting with new name
    await _paintingService.savePainting(_pixels, name: newName);
  }

  void _onCancelEdit() {
    SfxService().buttonClick();
    _nameController.text = _drawingName;
    setState(() {
      _isEditingName = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Block scroll khi đang vẽ
        return _isDrawing;
      },
      child: SingleChildScrollView(
        physics: _isDrawing ? const NeverScrollableScrollPhysics() : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========== TOOLBAR ==========
            _buildToolbar(l10n, theme),
            
            const SizedBox(height: 16),
            
            // ========== CANVAS ==========
            Listener(
              onPointerDown: (_) => setState(() => _isDrawing = true),
              onPointerUp: (_) => setState(() => _isDrawing = false),
              onPointerCancel: (_) => setState(() => _isDrawing = false),
              child: AspectRatio(
                aspectRatio: 1,
                child: PixelCanvas(
                  gridSize: 32,
                  pixels: _pixels,
                  selectedColorIndex: _selectedColorIndex,
                  onPixelPaint: _onPixelPaint,
                ),
              ),
            ),
            
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
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(DrawingPalette.hexToInt(
                      DrawingPalette.getColorByIndex(_selectedColorIndex)
                    )),
                    border: Border.all(color: theme.border, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // ========== COLOR PALETTE GRID ==========
            _buildColorPalette(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(AppLocalizations l10n, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drawing name với edit functionality
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
            
            if (_isEditingName) ...[
              // Text field để edit
              Expanded(
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary),
                    ),
                  ),
                  onSubmitted: (_) => _onSaveName(),
                ),
              ),
              const SizedBox(width: 8),
              // Save button
              GestureDetector(
                onTap: _onSaveName,
                child: const Text('✓', style: TextStyle(fontSize: 20, color: Colors.green)),
              ),
              const SizedBox(width: 8),
              // Cancel button
              GestureDetector(
                onTap: _onCancelEdit,
                child: const Text('✗', style: TextStyle(fontSize: 20, color: Colors.red)),
              ),
            ] else ...[
              // Display name
              Text(
                _drawingName,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              // Edit button
              GestureDetector(
                onTap: _onEditName,
                child: const Text('✏️', style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AppButton(
              icon: Icons.undo, 
              onPressed: _history.length > 1 ? _onUndo : null,
              width: 56,
            ),
            AppButton(icon: Icons.clear, onPressed: _onClear, width: 56),
            AppButton(icon: Icons.folder_open, onPressed: _onOpen, width: 56),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPalette(dynamic theme) {
    int index = 0;
    return Column(
      children: DrawingPalette.colors.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((colorHex) {
              final currentIndex = index++;
              final isSelected = currentIndex == _selectedColorIndex;
              return GestureDetector(
                onTap: () => _onColorSelected(currentIndex),
                child: Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Color(DrawingPalette.hexToInt(colorHex)),
                    border: Border.all(
                      color: isSelected ? Colors.white : theme.border,
                      width: isSelected ? 3 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 8)]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}