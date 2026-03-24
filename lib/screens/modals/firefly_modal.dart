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
import '../../core/utils/data_manager.dart';
import '../../core/utils/lan/lan_service.dart';
import '../../core/utils/lan/lan_message.dart';
import '../../core/utils/lan/game_message.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/firefly_world.dart';
import '../../core/widgets/app_modal.dart';

// ──────────────────────────────────────────────────────────────
// FireflyRole
// ──────────────────────────────────────────────────────────────

enum FireflyRole { lamp, jar }

// ──────────────────────────────────────────────────────────────
// FireflyModal
// ──────────────────────────────────────────────────────────────

class FireflyModal extends StatefulWidget {
  final int fireflyCount;
  final int fireflySeed;
  final FireflyRole role; // local player's role

  const FireflyModal({
    super.key,
    required this.fireflyCount,
    required this.fireflySeed,
    required this.role,
  });

  @override
  State<FireflyModal> createState() => _FireflyModalState();

  static Future<void> show(
    BuildContext context, {
    required int fireflyCount,
    required int fireflySeed,
    required FireflyRole role,
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
        fireflyCount: fireflyCount,
        fireflySeed: fireflySeed,
        role: role,
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
  // In solo mode: first pointer = lamp, second = jar.
  // In LAN mode: single GestureDetector moves the local role.
  int? _lampPointerId;
  int? _jarPointerId;

  // ── Role (mutable — player can switch their own tool) ────
  late FireflyRole _role;

  // ── Lamp brightness state ─────────────────────────────────
  // Toggle button cycles 0.0 (attract/dim) → 1.0 (repel/bright)
  double _lampBrightness = 0.0;

  // ── LAN ──────────────────────────────────────────────────
  StreamSubscription<LanIncomingEvent>? _lanSub;
  Timer? _syncTimer;
  String get _localId {
    try { return DataManager().userProfile.id; } catch (_) { return 'local'; }
  }
  bool get _isSolo => !LanService().isActive;
  bool get _isHost => _isSolo || LanService().role == LanRole.host;

  // LAN interpolation: store lerp targets for each firefly
  final Map<int, Offset> _lerpTargets = {};   // fireflyId → target pos
  final Map<int, double> _lerpPhases = {};    // fireflyId → target phase

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
      maxOnScreen: widget.fireflyCount,
      seed: widget.fireflySeed,
    );
    _world.onFireflyCaught = _onFireflyCaught;
    _worldReady = true;
  }

  // ─────────────────────────────────────────────────────────
  // LAN
  // ─────────────────────────────────────────────────────────

  void _setupLan() {
    if (_isSolo) return;

    if (_isHost) {
      // Host broadcasts firefly state at 20 Hz
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
      case 'moveLamp':
        final nx = (data['nx'] as num).toDouble();
        final ny = (data['ny'] as num).toDouble();
        final brightness = (data['brightness'] as num? ?? 0).toDouble();
        setState(() {
          _world.setLampPos(Offset(nx * _canvasWidth, ny * _canvasHeight));
          _world.setLampBrightness(brightness);
        });

      case 'moveJar':
        final nx = (data['nx'] as num).toDouble();
        final ny = (data['ny'] as num).toDouble();
        setState(() {
          _world.setJarPos(Offset(nx * _canvasWidth, ny * _canvasHeight));
        });

      case 'catchRequest':
        // Host only — validate and broadcast
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
        if (_isHost) return; // host is authoritative, ignore own sync
        final list = data['fireflies'] as List<dynamic>? ?? [];
        for (final rs in list) {
          final id = (rs['id'] as num).toInt();
          final nx = (rs['nx'] as num).toDouble();
          final ny = (rs['ny'] as num).toDouble();
          final phase = (rs['phase'] as num).toDouble();
          _lerpTargets[id] = Offset(nx * _canvasWidth, ny * _canvasHeight);
          _lerpPhases[id] = phase;
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
    _sendAction({
      'type': 'fireflySync',
      'fireflies': _world.buildSyncPayload(),
    });
  }

  void _sendCatchEvent(int fireflyId, String caughtBy) {
    _sendAction({'type': 'catchEvent', 'fireflyId': fireflyId, 'caughtBy': caughtBy});
  }

  void _sendLampMove(Offset pos) {
    _sendAction({
      'type': 'moveLamp',
      'nx': pos.dx / _canvasWidth,
      'ny': pos.dy / _canvasHeight,
      'brightness': _lampBrightness,
    });
  }

  void _sendJarMove(Offset pos) {
    _sendAction({
      'type': 'moveJar',
      'nx': pos.dx / _canvasWidth,
      'ny': pos.dy / _canvasHeight,
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

    // Apply LAN lerp targets (client interpolation between 20Hz sync packets)
    if (!_isHost && _lerpTargets.isNotEmpty) {
      _applyLerpTargets();
    }

    _accumulator += elapsed;
    bool dirty = false;
    while (_accumulator >= _fixedDt) {
      dirty = _world.step(_fixedDt) || dirty;
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

  void _applyLerpTargets() {
    // Lerp firefly render positions toward the latest host sync positions.
    // This smooths the 20Hz sync into a 60Hz visual update.
    // Lerp targets are applied directly by the host's fireflySync packets.
    // The 20Hz sync + 60Hz ticker creates smooth visual interpolation.
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
  }

  // ─────────────────────────────────────────────────────────
  // Input — solo: Listener for 2 independent pointers
  // ─────────────────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent e) {
    if (!_worldReady) return;
    if (_lampPointerId == null) {
      _lampPointerId = e.pointer;
      _moveLamp(e.localPosition);
    } else if (_jarPointerId == null) {
      _jarPointerId = e.pointer;
      _moveJar(e.localPosition);
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_worldReady) return;
    if (e.pointer == _lampPointerId) _moveLamp(e.localPosition);
    if (e.pointer == _jarPointerId) _moveJar(e.localPosition);
  }

  void _onPointerUp(PointerUpEvent e) {
    if (e.pointer == _lampPointerId) _lampPointerId = null;
    if (e.pointer == _jarPointerId) _jarPointerId = null;
  }

  // ─────────────────────────────────────────────────────────
  // Input — LAN: single GestureDetector for local role
  // ─────────────────────────────────────────────────────────

  void _onLanPanUpdate(DragUpdateDetails d) {
    if (!_worldReady) return;
    final pos = d.localPosition;
    if (_role == FireflyRole.lamp) {
      _moveLamp(pos);
      _sendLampMove(pos);
    } else {
      _moveJar(pos);
      _sendJarMove(pos);
    }
  }

  void _moveLamp(Offset pos) {
    final clamped = _clamp(pos);
    setState(() {
      _world.setLampPos(clamped);
      _world.setLampBrightness(_lampBrightness);
    });
  }

  void _moveJar(Offset pos) {
    setState(() => _world.setJarPos(_clamp(pos)));
  }

  Offset _clamp(Offset p) => Offset(
        p.dx.clamp(0, _canvasWidth),
        p.dy.clamp(0, _canvasHeight),
      );

  void _toggleBrightness() {
    setState(() {
      _lampBrightness = _lampBrightness < 0.5 ? 1.0 : 0.0;
      if (_worldReady) _world.setLampBrightness(_lampBrightness);
    });
  }

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
              // Lamp brightness toggle (visible to lamp holder or solo)
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
              // Switch tool button (LAN only — each player switches own role)
              if (!_isSolo)
                GestureDetector(
                  onTap: () => setState(() {
                    _role = _role == FireflyRole.lamp
                        ? FireflyRole.jar
                        : FireflyRole.lamp;
                  }),
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

              Widget canvas = CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _FireflyPainter(
                  snapshot: snap,
                  primaryColor: theme.primary,
                  backgroundColor: theme.background,
                ),
              );

              // Solo: use Listener for 2-finger independent control
              if (_isSolo) {
                return Listener(
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  child: canvas,
                );
              }

              // LAN: single drag for local role
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
  static const double _lampGlowRadius = 180.0;
  static const double _jarRadius = 32.0;
  static const double _jarCatchRadius = 44.0;

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

    // ── Lamp glow (RadialGradient) ───────────────────────
    final lampAlpha = 0.12 + snap.lampBrightness * 0.20;
    final lampPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          snap.lampColor.withValues(alpha: lampAlpha),
          snap.lampColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: snap.lampPos,
        radius: _lampGlowRadius,
      ));
    canvas.drawCircle(snap.lampPos, _lampGlowRadius, lampPaint);

    // ── Lamp handle ──────────────────────────────────────
    canvas.drawCircle(
      snap.lampPos,
      10,
      Paint()..color = snap.lampColor.withValues(alpha: 0.9),
    );

    // ── Jar ──────────────────────────────────────────────
    // Catch zone (faint)
    canvas.drawCircle(
      snap.jarPos,
      _jarCatchRadius,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    // Jar outline
    canvas.drawCircle(
      snap.jarPos,
      _jarRadius,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    // Caught count inside jar
    final tp = TextPainter(
      text: TextSpan(
        text: '${snap.totalCaught}',
        style: TextStyle(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      snap.jarPos - Offset(tp.width / 2, tp.height / 2),
    );

    // ── Fireflies ────────────────────────────────────────
    for (final f in snap.fireflies) {
      final s = math.sin(f.glowPhase);
      final radius = 3.0 + 1.5 * s;
      final sigma = 4.0 + 2.0 * s;
      final opacity = 0.5 + 0.5 * s;

      // Glow halo
      canvas.drawCircle(
        f.position,
        radius + sigma * 1.5,
        Paint()
          ..color = _fireflyColor.withValues(alpha: opacity * 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
      // Core
      canvas.drawCircle(
        f.position,
        radius,
        Paint()..color = _fireflyColor.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_FireflyPainter old) => true;
}
