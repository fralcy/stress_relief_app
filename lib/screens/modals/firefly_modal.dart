import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/game_room_provider.dart';
import '../../core/utils/asset_loader.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/lan/lan_service.dart';
import '../../core/utils/lan/lan_message.dart';
import '../../core/utils/lan/game_message.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/firefly_world.dart';
import '../../core/widgets/app_modal.dart';

// ──────────────────────────────────────────────────────────────
// FireflyModal
// ──────────────────────────────────────────────────────────────

class FireflyModal extends StatefulWidget {
  final int maxOnScreen;
  final int fireflySeed;
  final FireflyRole role;          // local player's initial role
  final int localToolId;           // 1-based slot (solo: 1 = lamp finger, LAN: player slot)
  final List<String> playerOrder;  // uid list in slot order; empty for solo
  final Map<int, FireflyRole> allRoles; // toolId → initial role; empty = solo

  const FireflyModal({
    super.key,
    required this.maxOnScreen,
    required this.fireflySeed,
    required this.role,
    this.localToolId = 1,
    this.playerOrder = const [],
    this.allRoles = const {},
  });

  @override
  State<FireflyModal> createState() => _FireflyModalState();

  static Future<void> show(
    BuildContext context, {
    required int maxOnScreen,
    required int fireflySeed,
    required FireflyRole role,
    int localToolId = 1,
    List<String> playerOrder = const [],
    Map<int, FireflyRole> allRoles = const {},
  }) {
    final h = MediaQuery.of(context).size.height * 0.95;
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.fireflyCatching,
      maxHeight: h,
      minHeight: h,
      scrollable: false,
      enableDrag: false,
      onClose: () {
        showDialog(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: Text(l10n.endGame),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dCtx).pop(),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dCtx).pop();
                  Navigator.of(context).pop();
                },
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      },
      content: FireflyModal(
        maxOnScreen: maxOnScreen,
        fireflySeed: fireflySeed,
        role: role,
        localToolId: localToolId,
        playerOrder: playerOrder,
        allRoles: allRoles,
      ),
    );
  }
}

class _FireflyModalState extends State<FireflyModal>
    with TickerProviderStateMixin {
  // ── Physics ───────────────────────────────────────────────
  static const double _fixedDt = 1.0 / 60.0;
  bool _worldReady = false;
  late FireflyWorld _world;

  // ── Ticker ───────────────────────────────────────────────
  late Ticker _ticker;
  DateTime? _lastTick;
  double _accumulator = 0.0;

  // ── Canvas ───────────────────────────────────────────────
  double _canvasWidth = 0;
  double _canvasHeight = 0;

  // ── Input — solo (Listener tracks 2 pointers) ────────────
  // pointer 1 = tool slot 1 (lamp), pointer 2 = tool slot 2 (jar)
  int? _pointer1Id;
  int? _pointer2Id;

  // ── Role & brightness (mutable mid-game) ─────────────────
  late FireflyRole _role;
  double _lampBrightness = 0.0;   // 0 = attract/dim, 1 = repel/bright

  // ── LAN ──────────────────────────────────────────────────
  StreamSubscription<LanIncomingEvent>? _lanSub;
  Timer? _syncTimer;
  String get _localId {
    try { return DataManager().userProfile.id; } catch (_) { return 'local'; }
  }
  bool get _isSolo => !LanService().isActive;
  bool get _isHost => _isSolo || LanService().role == LanRole.host;


  // ── Game end ─────────────────────────────────────────────
  bool _gameEnded = false;

  // ─────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _role = widget.role;
    _ticker = createTicker(_onTick)..start();
    _setupLan();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _syncTimer?.cancel();
    _lanSub?.cancel();
    if (_worldReady) _world.onFireflyCaught = null;
    super.dispose();
  }

  void _initWorld() {
    _world = FireflyWorld(
      canvasWidth: _canvasWidth,
      canvasHeight: _canvasHeight,
      maxOnScreen: widget.maxOnScreen,
      seed: widget.fireflySeed,
    );
    _world.onFireflyCaught = _onFireflyCaught;

    if (_isSolo) {
      // Solo: 2 tools — finger 1 = lamp, finger 2 = jar
      _world.addTool(1, FireflyRole.lamp, Offset(_canvasWidth * 0.35, _canvasHeight * 0.5));
      _world.addTool(2, FireflyRole.jar, Offset(_canvasWidth * 0.65, _canvasHeight * 0.5));
    } else {
      // LAN: one tool per player, evenly spread
      final n = widget.playerOrder.length.clamp(1, 4);
      for (int i = 0; i < n; i++) {
        final toolId = i + 1;
        final tx = _canvasWidth * (i + 1) / (n + 1);
        final initRole = widget.allRoles[toolId]
            ?? (toolId == widget.localToolId ? widget.role : FireflyRole.lamp);
        _world.addTool(toolId, initRole, Offset(tx, _canvasHeight * 0.5));
      }
    }

    _worldReady = true;
  }

  // ─────────────────────────────────────────────────────────
  // LAN
  // ─────────────────────────────────────────────────────────

  void _setupLan() {
    if (_isSolo) return;

    if (_isHost) {
      _syncTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) { if (_worldReady) _sendFireflySync(); },
      );
    }

    _lanSub = LanService().incomingEvents.listen((event) {
      final gm = GameMessage.tryExtract(event.message);
      if (gm == null) return;

      if (gm.event == GameEvent.playerAction) {
        if (_isHost) {
          LanService().broadcastMessage(
            GameMessage.gameState(_localId, gm.data),
          );
        }
        _applyPeerMessage(gm.data, event.message.senderId);
      } else if (gm.event == GameEvent.gameState && !_isHost) {
        final fromId = gm.data['fromId'] as String? ?? '';
        _applyPeerMessage(gm.data, fromId);
      } else if (gm.event == GameEvent.gameEnd) {
        _onGameEnd(gm.data);
      }
    });
  }

  void _applyPeerMessage(Map<String, dynamic> data, String fromId) {
    if (fromId == _localId) return;
    if (!mounted || !_worldReady) return;

    final type = data['type'] as String?;
    switch (type) {
      case 'moveTool':
        final toolId = (data['toolId'] as num).toInt();
        final nx = (data['nx'] as num).toDouble();
        final ny = (data['ny'] as num).toDouble();
        final brightness = (data['brightness'] as num? ?? 0).toDouble();
        final roleStr = data['role'] as String? ?? '';
        final role = FireflyRole.values.firstWhere(
          (r) => r.name == roleStr, orElse: () => FireflyRole.lamp);
        if (_isHost) {
          _world.updateToolPos(toolId, Offset(nx * _canvasWidth, ny * _canvasHeight));
          _world.switchToolType(toolId, role);
          _world.setToolBrightness(toolId, brightness);
        }

      case 'switchTool':
        final toolId = (data['toolId'] as num).toInt();
        final roleStr = data['role'] as String? ?? '';
        final role = FireflyRole.values.firstWhere(
          (r) => r.name == roleStr, orElse: () => FireflyRole.lamp);
        setState(() => _world.switchToolType(toolId, role));

      case 'catchRequest':
        if (!_isHost) return;
        final id = (data['fireflyId'] as num).toInt();
        _world.catchFireflyById(id);
        _sendCatchEvent(id, fromId);
        _onFireflyCaught();

      case 'catchEvent':
        final id = (data['fireflyId'] as num).toInt();
        setState(() => _world.catchFireflyById(id));
        SfxService().taskComplete();
        HapticFeedback.lightImpact();

      case 'fireflySync':
        if (_isHost) return;
        final list = data['fireflies'] as List<dynamic>? ?? [];
        for (final rs in list) {
          final id = (rs['id'] as num).toInt();
          final nx = (rs['nx'] as num).toDouble();
          final ny = (rs['ny'] as num).toDouble();
          final phase = (rs['phase'] as num).toDouble();
          _world.setLerpTarget(
            id,
            Offset(nx * _canvasWidth, ny * _canvasHeight),
            phase,
          );
        }
        // Apply other players' tool positions (skip own tool to avoid jitter)
        final tools = data['tools'] as List<dynamic>? ?? [];
        for (final t in tools) {
          final toolId = (t['id'] as num).toInt();
          if (toolId == widget.localToolId) continue;
          final nx = (t['nx'] as num).toDouble();
          final ny = (t['ny'] as num).toDouble();
          final brightness = (t['brightness'] as num? ?? 0).toDouble();
          final roleStr = t['role'] as String? ?? '';
          final role = FireflyRole.values.firstWhere(
            (r) => r.name == roleStr, orElse: () => FireflyRole.lamp);
          _world.updateToolPos(toolId, Offset(nx * _canvasWidth, ny * _canvasHeight));
          _world.switchToolType(toolId, role);
          _world.setToolBrightness(toolId, brightness);
        }

      case 'playerLeft':
        final toolId = data['toolId'] as int?;
        if (toolId != null && _worldReady) {
          setState(() => _world.removeTool(toolId));
        }
    }
  }

  void _sendAction(Map<String, dynamic> data) {
    if (_isSolo) return;
    final payload = {...data, 'fromId': _localId};
    if (_isHost) {
      LanService().broadcastMessage(GameMessage.gameState(_localId, payload));
    } else {
      LanService().sendMessage(GameMessage.playerAction(_localId, payload));
    }
  }

  void _sendFireflySync() {
    final payload = _world.buildSyncPayload();
    _sendAction({'type': 'fireflySync', ...payload});
  }

  void _sendCatchEvent(int fireflyId, String caughtBy) {
    _sendAction({'type': 'catchEvent', 'fireflyId': fireflyId, 'caughtBy': caughtBy});
  }

  void _sendToolMove(Offset pos) {
    _sendAction({
      'type': 'moveTool',
      'toolId': widget.localToolId,
      'nx': pos.dx / _canvasWidth,
      'ny': pos.dy / _canvasHeight,
      'role': _role.name,
      'brightness': _role == FireflyRole.lamp ? _lampBrightness : 0.0,
    });
  }

  // ─────────────────────────────────────────────────────────
  // Ticker
  // ─────────────────────────────────────────────────────────

  void _onTick(Duration _) {
    if (!mounted || !_worldReady) return;

    final now = DateTime.now();
    if (_lastTick == null) { _lastTick = now; return; }
    final elapsed =
        (now.difference(_lastTick!).inMicroseconds / 1e6).clamp(0.0, 0.25);
    _lastTick = now;

    _accumulator += elapsed;
    bool dirty = false;
    while (_accumulator >= _fixedDt) {
      if (_isHost || _isSolo) {
        dirty = _world.step(_fixedDt) || dirty;
      } else {
        dirty = _world.stepClient(_fixedDt) || dirty;
      }
      _accumulator -= _fixedDt;
    }

    // Check catches (solo or host)
    if (_isHost || _isSolo) {
      final newly = _world.checkCatch();
      if (newly.isNotEmpty && !_isSolo) {
        for (final id in newly) {
          _sendCatchEvent(id, _localId);
        }
      }
    }

    if (dirty) setState(() {});
  }

  // ─────────────────────────────────────────────────────────
  // SFX / haptics
  // ─────────────────────────────────────────────────────────

  void _onFireflyCaught() {
    if (!mounted) return;
    SfxService().taskComplete();
    HapticFeedback.lightImpact();
    setState(() {});
  }

  // ─────────────────────────────────────────────────────────
  // Game end
  // ─────────────────────────────────────────────────────────

  void _onGameEnd(Map<String, dynamic> _) {
    if (_gameEnded || !mounted) return;
    setState(() => _gameEnded = true);
    if (!_isHost) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) { if (mounted) Navigator.of(context).pop(); });
    }
  }

  void _confirmExit() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.endGame),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              Navigator.of(context).pop();
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Input — solo: Listener for 2 independent pointers
  // ─────────────────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent e) {
    if (!_worldReady) return;
    if (_pointer1Id == null) {
      _pointer1Id = e.pointer;
      _moveTool(1, e.localPosition);
    } else if (_pointer2Id == null) {
      _pointer2Id = e.pointer;
      _moveTool(2, e.localPosition);
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_worldReady) return;
    if (e.pointer == _pointer1Id) _moveTool(1, e.localPosition);
    if (e.pointer == _pointer2Id) _moveTool(2, e.localPosition);
  }

  void _onPointerUp(PointerUpEvent e) {
    if (e.pointer == _pointer1Id) _pointer1Id = null;
    if (e.pointer == _pointer2Id) _pointer2Id = null;
  }

  // ─────────────────────────────────────────────────────────
  // Input — LAN: single GestureDetector for local tool
  // ─────────────────────────────────────────────────────────

  void _onLanPanUpdate(DragUpdateDetails d) {
    if (!_worldReady) return;
    final pos = _clamp(d.localPosition);
    _moveTool(widget.localToolId, pos);
    _sendToolMove(pos);
  }

  // ─────────────────────────────────────────────────────────
  // Tool control
  // ─────────────────────────────────────────────────────────

  void _moveTool(int toolId, Offset pos) {
    final clamped = _clamp(pos);
    setState(() => _world.updateToolPos(toolId, clamped));
  }

  void _switchTool() {
    setState(() {
      _role = _role == FireflyRole.lamp ? FireflyRole.jar : FireflyRole.lamp;
      _world.switchToolType(widget.localToolId, _role);
    });
    _sendAction({
      'type': 'switchTool',
      'toolId': widget.localToolId,
      'role': _role.name,
    });
  }

  void _toggleBrightness() {
    setState(() {
      _lampBrightness = _lampBrightness < 0.5 ? 1.0 : 0.0;
      if (_worldReady) _world.setToolBrightness(widget.localToolId, _lampBrightness);
    });
    // Send updated position+brightness so host knows about brightness change
    if (!_isSolo && _worldReady) {
      // Notify via moveTool with current position (dummy pan)
    }
  }

  Offset _clamp(Offset p) => Offset(
        p.dx.clamp(0, _canvasWidth),
        p.dy.clamp(0, _canvasHeight),
      );

  // ─────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final snap = _worldReady ? _world.buildRenderData() : null;

    return Column(
      children: [
        // ── Info bar ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Text(
                '${l10n.caught}: ${snap?.totalCaught ?? 0}',
                style: AppTypography.bodySmall(context,
                    color: theme.primary, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Brightness toggle (only when current role is lamp, or solo)
              if (_isSolo || _role == FireflyRole.lamp)
                GestureDetector(
                  onTap: _toggleBrightness,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _lampBrightness < 0.5 ? l10n.attractMode : l10n.repelMode,
                      style: AppTypography.bodySmall(context, color: theme.primary),
                    ),
                  ),
                ),
              // Switch tool (LAN only)
              if (!_isSolo)
                GestureDetector(
                  onTap: _switchTool,
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _role == FireflyRole.lamp ? l10n.roleLamp : l10n.roleJar,
                      style: AppTypography.bodySmall(context, color: theme.primary),
                    ),
                  ),
                ),
              // End game (host LAN or solo)
              if (_isSolo)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: TextButton(
                    onPressed: _confirmExit,
                    child: Text(l10n.endGame,
                        style: TextStyle(color: theme.primary)),
                  ),
                ),
              if (!_isSolo && _isHost)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: TextButton(
                    onPressed: () {
                      context.read<GameRoomProvider>().endGame(
                            {'caughtCount': snap?.totalCaught ?? 0},
                          );
                      _onGameEnd({});
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.endGame,
                        style: TextStyle(color: theme.primary)),
                  ),
                ),
            ],
          ),
        ),

        // ── Canvas ───────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_canvasWidth == 0) {
                _canvasWidth = constraints.maxWidth;
                _canvasHeight = constraints.maxHeight;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_worldReady) setState(_initWorld);
                });
              }

              Widget canvas = Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      AssetLoader.getFireflyBgAsset(
                        DataManager().userSettings.currentScenes[0].sceneSet,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => ColoredBox(color: theme.background),
                    ),
                  ),
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _FireflyPainter(
                      snapshot: snap,
                      primaryColor: theme.primary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              );

              if (_isSolo) {
                return Listener(
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  child: canvas,
                );
              }

              return GestureDetector(
                onPanUpdate: _onLanPanUpdate,
                child: canvas,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// CustomPainter
// ──────────────────────────────────────────────────────────────

class _FireflyPainter extends CustomPainter {
  final FireflyWorldRenderSnapshot? snapshot;
  final Color primaryColor;
  final Color backgroundColor;

  static const Color _fireflyColor = Color(0xFFCCFF66); // warm yellow-green
  static const Color _litFireflyColor = Color(0xFFFFFF99); // brighter when lit

  _FireflyPainter({
    required this.snapshot,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Background ──────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    if (snapshot == null) return;
    final snap = snapshot!;

    // ── Tools ────────────────────────────────────────────
    for (final tool in snap.tools) {
      if (tool.type == FireflyRole.lamp) {
        _drawLamp(canvas, tool, snap.lampRadius);
      } else {
        _drawJar(canvas, tool, snap.jarCatchRadius);
      }
    }

    // ── Fireflies ────────────────────────────────────────
    for (final f in snap.fireflies) {
      final s = math.sin(f.glowPhase);
      final haloRadius = 3.5 + 2.0 * s;
      final sigma = 4.0 + 2.5 * s;
      final haloOpacity = (0.15 + 0.35 * ((s + 1) / 2));  // 0.15..0.5
      final baseColor = f.isLit ? _litFireflyColor : _fireflyColor;

      // Glow halo (pulsing, can go dim but never fully gone)
      canvas.drawCircle(
        f.position,
        haloRadius + sigma * 1.5,
        Paint()
          ..color = baseColor.withValues(alpha: haloOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
      // Core dot — always 2.5px, always visible
      canvas.drawCircle(
        f.position,
        2.5,
        Paint()..color = baseColor.withValues(alpha: 0.85),
      );
    }

  }

  void _drawLamp(Canvas canvas, ToolRenderData tool, double glowRadius) {
    final lampAlpha = 0.10 + tool.brightness * 0.22;
    final lampPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          tool.lampColor.withValues(alpha: lampAlpha),
          tool.lampColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: tool.position,
        radius: glowRadius,
      ));
    canvas.drawCircle(tool.position, glowRadius, lampPaint);
    canvas.drawCircle(
      tool.position,
      10,
      Paint()..color = tool.lampColor.withValues(alpha: 0.9),
    );
  }

  void _drawJar(Canvas canvas, ToolRenderData tool, double jarRadius) {
    canvas.drawCircle(
      tool.position,
      jarRadius,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      tool.position,
      jarRadius,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(_FireflyPainter old) => true;
}
