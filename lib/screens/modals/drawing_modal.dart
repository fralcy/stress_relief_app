import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/constants/drawing_palette.dart';
import '../../core/widgets/pixel_canvas.dart';
import '../../core/utils/painting_service.dart';
import 'gallery_modal.dart';
import 'templates_modal.dart';
import '../../models/painting_progress.dart';

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
  
  // Zoom and pan controls
  int _zoomLevel = 1; // 1, 2, 4
  double _panX = 0;
  double _panY = 0;

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

  Future<void> _onTemplates() async {
    SfxService().buttonClick();
    
    // Show templates modal
    await TemplatesModal.show(
      context,
      onTemplateSelected: (Painting template) {
        // Load template vào canvas
        _saveToHistory();
        setState(() {
          _pixels = template.pixels.map((row) => List<int>.from(row)).toList();
        });
        _paintingService.savePainting(_pixels, name: _drawingName);
      },
    );
  }

  void _onZoomIn() {
    SfxService().buttonClick();
    if (_zoomLevel < 4) {
      setState(() {
        _zoomLevel *= 2;
        // Reset pan khi zoom
        _panX = 0;
        _panY = 0;
      });
    }
  }

  void _onZoomOut() {
    SfxService().buttonClick();
    if (_zoomLevel > 1) {
      setState(() {
        _zoomLevel ~/= 2;
        // Reset pan khi zoom
        _panX = 0;
        _panY = 0;
      });
    }
  }

  void _onPanLeft() {
    SfxService().buttonClick();
    if (_zoomLevel > 1) {
      setState(() {
        _panX = (_panX - 0.25).clamp(-(_zoomLevel - 1).toDouble(), 0);
      });
    }
  }

  void _onPanRight() {
    SfxService().buttonClick();
    if (_zoomLevel > 1) {
      setState(() {
        _panX = (_panX + 0.25).clamp(0, (_zoomLevel - 1).toDouble());
      });
    }
  }

  void _onPanUp() {
    SfxService().buttonClick();
    if (_zoomLevel > 1) {
      setState(() {
        _panY = (_panY - 0.25).clamp(-(_zoomLevel - 1).toDouble(), 0);
      });
    }
  }

  void _onPanDown() {
    SfxService().buttonClick();
    if (_zoomLevel > 1) {
      setState(() {
        _panY = (_panY + 0.25).clamp(0, (_zoomLevel - 1).toDouble());
      });
    }
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
                  zoomLevel: _zoomLevel,
                  panX: _panX,
                  panY: _panY,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ========== ZOOM AND PAN CONTROLS ==========
            _buildZoomPanControls(l10n, theme),
            
            const SizedBox(height: 16),
            
            // ========== COLOR PALETTE LABEL ==========
            Text(
              l10n.colorPalette,
              style: AppTypography.bodyLarge(context,
                color: theme.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Selected color indicator
            Row(
              children: [
                Text(
                  '${l10n.selected}: ',
                  style: AppTypography.bodyMedium(context, color: theme.text),
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
              style: AppTypography.bodyLarge(context,
                color: theme.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            if (_isEditingName) ...[
              // Text field để edit
              Expanded(
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: AppTypography.bodyLarge(context,
                    color: theme.text,
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
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: const Icon(Icons.check, color: Colors.green, size: 24),
                ),
              ),
              const SizedBox(width: 8),
              // Cancel button
              GestureDetector(
                onTap: _onCancelEdit,
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: const Icon(Icons.close, color: Colors.red, size: 24),
                ),
              ),
            ] else ...[
              // Display name
              Text(
                _drawingName,
                style: AppTypography.bodyLarge(context,
                  color: theme.text,
                ),
              ),
              const SizedBox(width: 8),
              // Edit button
              GestureDetector(
                onTap: _onEditName,
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: Icon(Icons.edit, color: theme.primary, size: 24),
                ),
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
              onPressed: _onUndo,
              isDisabled: _history.length <= 1,
              width: 56,
            ),
            AppButton(icon: Icons.clear, onPressed: _onClear, width: 56),
            AppButton(icon: Icons.folder_open, onPressed: _onOpen, width: 56),
            AppButton(icon: Icons.star, onPressed: _onTemplates, width: 56),
          ],
        ),
      ],
    );
  }

  Widget _buildZoomPanControls(AppLocalizations l10n, dynamic theme) {
    final displayGridSize = 32 ~/ _zoomLevel;
    
    return Column(
      children: [
        // Zoom info
        Text(
          '${l10n.zoom}: ${_zoomLevel}x (${displayGridSize}x$displayGridSize pixels)',
          style: AppTypography.bodyMedium(context,
            color: theme.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Controls layout
        Column(
          children: [
            // Top row: Up arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  icon: Icons.keyboard_arrow_up,
                  onPressed: _onPanUp,
                  isDisabled: _zoomLevel <= 1,
                  width: 48,
                  height: 48,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Middle row: Left, Zoom controls, Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AppButton(
                  icon: Icons.keyboard_arrow_left,
                  onPressed: _onPanLeft,
                  isDisabled: _zoomLevel <= 1,
                  width: 48,
                  height: 48,
                ),
                
                // Zoom controls
                Row(
                  children: [
                    AppButton(
                      icon: Icons.zoom_out,
                      onPressed: _onZoomOut,
                      isDisabled: _zoomLevel <= 1,
                      width: 56,
                      height: 48,
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      icon: Icons.zoom_in,
                      onPressed: _onZoomIn,
                      isDisabled: _zoomLevel >= 4,
                      width: 56,
                      height: 48,
                    ),
                  ],
                ),
                
                AppButton(
                  icon: Icons.keyboard_arrow_right,
                  onPressed: _onPanRight,
                  isDisabled: _zoomLevel <= 1,
                  width: 48,
                  height: 48,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Bottom row: Down arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  icon: Icons.keyboard_arrow_down,
                  onPressed: _onPanDown,
                  isDisabled: _zoomLevel <= 1,
                  width: 48,
                  height: 48,
                ),
              ],
            ),
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
              return Semantics(
                label: 'Color ${currentIndex + 1}${isSelected ? ", selected" : ""}',
                button: true,
                selected: isSelected,
                child: GestureDetector(
                  onTap: () => _onColorSelected(currentIndex),
                  child: Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Color(DrawingPalette.hexToInt(colorHex)),
                      border: Border.all(
                        color: isSelected ? theme.primary : theme.border,
                        width: isSelected ? 3 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [BoxShadow(color: theme.primary.withOpacity(0.5), blurRadius: 8)]
                          : null,
                    ),
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