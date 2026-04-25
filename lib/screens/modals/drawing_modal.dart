import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/l10n/app_localizations.dart';
import 'package:flutter_tutorial_overlay/flutter_tutorial_overlay.dart';
import '../../core/constants/drawing_palette.dart';
import '../../core/widgets/pixel_canvas.dart';
import '../../core/utils/painting_service.dart';
import 'gallery_modal.dart';
import 'templates_modal.dart';
import '../../models/painting_progress.dart';
import 'package:provider/provider.dart';
import '../../core/providers/score_provider.dart';
import '../../core/providers/achievement_provider.dart';
import '../../core/widgets/achievement_popup.dart';
import '../../core/utils/achievement_service.dart';

/// Modal vẽ tranh
class DrawingModal extends StatefulWidget {
  const DrawingModal({super.key});

  @override
  State<DrawingModal> createState() => _DrawingModalState();

  /// Helper để show modal
  static Future<void> show(BuildContext context) async {
    await PaintingService().initializeDefaultPaintings();
    if (!context.mounted) return;

    final size = MediaQuery.of(context).size;
    if (size.width >= 720 && size.width > size.height && size.height >= 600) {
      return _showLandscape(context);
    }

    final l10n = AppLocalizations.of(context);
    final modalKey = GlobalKey<_DrawingModalState>();
    return AppModal.show(
      context: context,
      title: l10n.art,
      maxHeight: size.height * 0.92,
      onHelpPressed: () => modalKey.currentState?._showTutorial(),
      content: DrawingModal(key: modalKey),
    );
  }

  static Future<void> _showLandscape(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modalKey = GlobalKey<_DrawingModalState>();
    final size = MediaQuery.of(context).size;
    final dialogWidth = (size.width * 0.92).clamp(0.0, 1100.0);
    final dialogHeight = size.height * 0.92;
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: AppModal(
            isDialog: true,
            title: l10n.art,
            scrollable: false,
            content: DrawingModal(key: modalKey),
            onHelpPressed: () => modalKey.currentState?._showTutorial(),
          ),
        ),
      ),
    );
  }
}

class _DrawingModalState extends State<DrawingModal> {
  final PaintingService _paintingService = PaintingService();
  final TextEditingController _nameController = TextEditingController();

  final GlobalKey _toolbarKey = GlobalKey();
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _zoomKey = GlobalKey();
  final GlobalKey _paletteKey = GlobalKey();

  late List<List<int>> _pixels;
  int _selectedColorIndex = 0;
  String _drawingName = 'My Drawing';
  bool _isLoading = true;
  bool _isEditingName = false;

  // Undo history
  final List<List<List<int>>> _history = [];
  static const int _maxHistorySize = 20;

  // Achievement tracking — cumulative pixel changes this session
  int _pixelChangeCount = 0;

  // Scroll control
  bool _isDrawing = false;

  // Zoom and pan controls
  int _zoomLevel = 1; // 1, 2, 4
  double _panX = 0;
  double _panY = 0;

  // Collapsible sections
  bool _isZoomExpanded = false;
  bool _isPaletteExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadPainting();
  }

  @override
  void dispose() {
    _nameController.dispose();
    if (_pixelChangeCount > 0) {
      AchievementService().addPixelsOnly(_pixelChangeCount);
    }
    super.dispose();
  }

  Future<void> _flushPixelAchievement() async {
    if (_pixelChangeCount <= 0 || !mounted) return;
    final score = context.read<ScoreProvider>();
    final delta = _pixelChangeCount;
    _pixelChangeCount = 0;
    final newly = await context.read<AchievementProvider>().onPixelsPainted(delta, score);
    if (newly.isNotEmpty && mounted) AchievementPopup.show(context, newly);
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
      _pixelChangeCount++;
    });

    // Auto-save
    _paintingService.savePainting(_pixels, name: _drawingName);
    _flushPixelAchievement();
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

    // Achievement trigger
    if (_pixelChangeCount > 0 && mounted) {
      final score = context.read<ScoreProvider>();
      final delta = _pixelChangeCount;
      _pixelChangeCount = 0;
      final newly =
          await context.read<AchievementProvider>().onPixelsPainted(delta, score);
      if (newly.isNotEmpty && mounted) {
        AchievementPopup.show(context, newly);
      }
    }
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

  void _showTutorial() {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;
    TutorialOverlay(
      context: context,
      blurOpacity: kIsWeb ? 0 : 20,
      blurSigma: kIsWeb ? 0 : 6,
      steps: [
        TutorialStep(targetKey: _toolbarKey, title: l10n.tutorialDrawToolbarTitle, description: l10n.tutorialDrawToolbarDesc, tag: 'draw_toolbar'),
        TutorialStep(targetKey: _canvasKey, title: l10n.tutorialDrawCanvasTitle, description: l10n.tutorialDrawCanvasDesc, tag: 'draw_canvas'),
        TutorialStep(targetKey: _zoomKey, title: l10n.tutorialDrawZoomTitle, description: l10n.tutorialDrawZoomDesc, tag: 'draw_zoom'),
        TutorialStep(targetKey: _paletteKey, title: l10n.tutorialDrawPaletteTitle, description: l10n.tutorialDrawPaletteDesc, tag: 'draw_palette'),
      ],
      nextText: l10n.tutorialNext,
      skipText: l10n.tutorialSkip,
      finshText: l10n.tutorialGotIt,
      onComplete: () => SfxService().buttonClick(),
      tooltipBackgroundColor: kIsWeb ? theme.text : theme.background,
      titleTextColor: kIsWeb ? theme.background : theme.text,
      descriptionTextColor: kIsWeb ? theme.background : theme.text,
      nextButtonStyle: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      skipButtonStyle: TextButton.styleFrom(
        foregroundColor: theme.text,
      ),
      finishButtonStyle: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final size = MediaQuery.of(context).size;
    final isLandscape =
        size.width >= 720 && size.width > size.height && size.height >= 600;
    return isLandscape ? _buildLandscape(context) : _buildPortrait(context);
  }

  Widget _buildPortrait(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

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
            KeyedSubtree(key: _toolbarKey, child: _buildToolbar(l10n, theme)),

            const SizedBox(height: 16),

            // ========== CANVAS ==========
            KeyedSubtree(
              key: _canvasKey,
              child: Listener(
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
            ),

            const SizedBox(height: 12),

            // ========== ZOOM & PAN (collapsible) ==========
            KeyedSubtree(
              key: _zoomKey,
              child: _buildCollapsibleSection(
                title: l10n.tutorialDrawZoomTitle,
                isExpanded: _isZoomExpanded,
                onToggle: () => setState(() => _isZoomExpanded = !_isZoomExpanded),
                theme: theme,
                child: _buildZoomPanControls(l10n, theme),
              ),
            ),

            const SizedBox(height: 8),

            // ========== COLOR PALETTE (collapsible) ==========
            KeyedSubtree(
              key: _paletteKey,
              child: _buildCollapsibleSection(
                title: l10n.colorPalette,
                isExpanded: _isPaletteExpanded,
                onToggle: () => setState(() => _isPaletteExpanded = !_isPaletteExpanded),
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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

                    _buildColorPalette(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscape(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: toolbar + canvas only
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Toolbar
                KeyedSubtree(key: _toolbarKey, child: _buildToolbar(l10n, theme)),

                const SizedBox(height: 16),

                // Canvas
                KeyedSubtree(
                  key: _canvasKey,
                  child: Listener(
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
                ),
              ],
            ),
          ),
        ),

        VerticalDivider(width: 1, thickness: 1, color: theme.border),

        // Right: zoom/pan + palette (always expanded)
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Zoom & pan
                KeyedSubtree(
                  key: _zoomKey,
                  child: _buildZoomPanControls(l10n, theme),
                ),

                const SizedBox(height: 16),
                Divider(color: theme.border, height: 1, thickness: 1),
                const SizedBox(height: 16),

                // Color palette
                KeyedSubtree(
                  key: _paletteKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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

                      _buildColorPalette(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Collapsible section header + animated body
  Widget _buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required dynamic theme,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row (tap to toggle)
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge(context,
                    color: theme.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.text,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // Body (animated show/hide)
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: child,
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
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
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  child: Icon(Icons.check, color: context.theme.primary, size: 24),
                ),
              ),
              const SizedBox(width: 8),
              // Cancel button
              GestureDetector(
                onTap: _onCancelEdit,
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  child: Icon(Icons.close, color: context.colorScheme.error, size: 24),
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
                  width: 56,
                  height: 56,
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
          '${l10n.zoom}: ${_zoomLevel}x ($displayGridSize×$displayGridSize pixels)',
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
                  width: 56,
                  height: 56,
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
                  width: 56,
                  height: 56,
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
                  width: 56,
                  height: 56,
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
                  width: 56,
                  height: 56,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPalette(dynamic theme) {
    const itemSize = 48.0;
    const minGap = 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemsPerRow = ((width + minGap) / (itemSize + minGap)).floor().clamp(1, 32);
        // Gap để các ô căn đều 2 lề
        final gap = itemsPerRow > 1
            ? (width - itemsPerRow * itemSize) / (itemsPerRow - 1)
            : 0.0;

        final colors = DrawingPalette.flatColors;
        final rows = <List<int>>[];
        for (var i = 0; i < colors.length; i += itemsPerRow) {
          rows.add(List.generate(
            (i + itemsPerRow).clamp(0, colors.length) - i,
            (j) => i + j,
          ));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows.asMap().entries.map((entry) {
            final indices = entry.value;
            final rowGap = gap;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (var i = 0; i < indices.length; i++) ...[
                    if (i > 0) SizedBox(width: rowGap),
                    _buildSwatch(indices[i], theme, itemSize),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSwatch(int currentIndex, dynamic theme, double size) {
    final colorHex = DrawingPalette.flatColors[currentIndex];
    final isSelected = currentIndex == _selectedColorIndex;
    return Semantics(
      label: 'Color ${currentIndex + 1}${isSelected ? ", selected" : ""}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => _onColorSelected(currentIndex),
        child: Container(
          width: size,
          height: size,
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
  }
}
