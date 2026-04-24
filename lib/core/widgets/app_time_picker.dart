import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_typography.dart';
import '../providers/time_picker_provider.dart';

class _RangeInputFormatter extends TextInputFormatter {
  const _RangeInputFormatter(this.max);
  final int max;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final val = int.tryParse(newValue.text);
    if (val == null || val > max) return oldValue;
    return newValue;
  }
}

// Large multiplier for the looping virtual list.
const _kLoopMultiplier = 1000;

// Returns the index in the looped list nearest to [current] that maps to [target].
int _nearestLoopIndex(int current, int target, int count) {
  final base = (current ~/ count) * count + target;
  final candidates = [base - count, base, base + count];
  return candidates
      .reduce((a, b) => (a - current).abs() < (b - current).abs() ? a : b);
}

class AppTimePicker extends StatefulWidget {
  const AppTimePicker({
    super.key,
    this.label = '',
    required this.time,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay time;
  final Function(TimeOfDay)? onChanged;

  @override
  State<AppTimePicker> createState() => _AppTimePickerState();
}

class _AppTimePickerState extends State<AppTimePicker> {
  late TimePickerProvider _notifier;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;

  static const _kHourCount = 24;
  static const _kMinuteCount = 60;

  final TextEditingController _hourTextCtrl = TextEditingController();
  final TextEditingController _minuteTextCtrl = TextEditingController();
  final FocusNode _hourFocus = FocusNode();
  final FocusNode _minuteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _notifier = TimePickerProvider(widget.time);
    // Start near the middle of the virtual list so scrolling loops both ways.
    _hourCtrl = FixedExtentScrollController(
        initialItem: _kHourCount * (_kLoopMultiplier ~/ 2) + widget.time.hour);
    _minuteCtrl = FixedExtentScrollController(
        initialItem:
            _kMinuteCount * (_kLoopMultiplier ~/ 2) + widget.time.minute);
    _notifier.addListener(_syncScrollControllers);
    _hourFocus.addListener(() {
      if (!_hourFocus.hasFocus) _commitHour();
    });
    _minuteFocus.addListener(() {
      if (!_minuteFocus.hasFocus) _commitMinute();
    });
  }

  void _syncScrollControllers() {
    if (!_notifier.editingHour &&
        _hourCtrl.hasClients &&
        _hourCtrl.selectedItem % _kHourCount != _notifier.hour) {
      _hourCtrl.jumpToItem(
          _nearestLoopIndex(_hourCtrl.selectedItem, _notifier.hour, _kHourCount));
    }
    if (!_notifier.editingMinute &&
        _minuteCtrl.hasClients &&
        _minuteCtrl.selectedItem % _kMinuteCount != _notifier.minute) {
      _minuteCtrl.jumpToItem(_nearestLoopIndex(
          _minuteCtrl.selectedItem, _notifier.minute, _kMinuteCount));
    }
  }

  @override
  void didUpdateWidget(AppTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.time != widget.time) {
      _notifier.syncFromTime(widget.time);
    }
  }

  @override
  void dispose() {
    _notifier.removeListener(_syncScrollControllers);
    _notifier.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _hourTextCtrl.dispose();
    _minuteTextCtrl.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  void _startEditHour() {
    _hourTextCtrl.text = _notifier.hour.toString().padLeft(2, '0');
    _notifier.startEditHour();
    Future.microtask(() => _hourTextCtrl.selection =
        TextSelection(baseOffset: 0, extentOffset: _hourTextCtrl.text.length));
  }

  void _startEditMinute() {
    _minuteTextCtrl.text = _notifier.minute.toString().padLeft(2, '0');
    _notifier.startEditMinute();
    Future.microtask(() => _minuteTextCtrl.selection =
        TextSelection(baseOffset: 0, extentOffset: _minuteTextCtrl.text.length));
  }

  void _commitHour() {
    if (!_notifier.editingHour) return;
    final val = int.tryParse(_hourTextCtrl.text);
    final h = val?.clamp(0, 23);
    _notifier.commitHour(h);
    if (h != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _hourCtrl.hasClients) {
          _hourCtrl.jumpToItem(
              _nearestLoopIndex(_hourCtrl.selectedItem, h, _kHourCount));
        }
      });
      widget.onChanged?.call(TimeOfDay(hour: h, minute: _notifier.minute));
    }
  }

  void _commitMinute() {
    if (!_notifier.editingMinute) return;
    final val = int.tryParse(_minuteTextCtrl.text);
    final m = val?.clamp(0, 59);
    _notifier.commitMinute(m);
    if (m != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _minuteCtrl.hasClients) {
          _minuteCtrl.jumpToItem(
              _nearestLoopIndex(_minuteCtrl.selectedItem, m, _kMinuteCount));
        }
      });
      widget.onChanged?.call(TimeOfDay(hour: _notifier.hour, minute: m));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onChanged != null;

    const itemExtent = 36.0;
    const wheelHeight = itemExtent * 3;

    final picker = ChangeNotifierProvider.value(
      value: _notifier,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: SizedBox(
          height: wheelHeight,
          child: Consumer<TimePickerProvider>(
            builder: (context, notifier, _) => Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: itemExtent,
                  left: 0,
                  right: 0,
                  child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.outline),
                ),
                Positioned(
                  top: itemExtent * 2,
                  left: 0,
                  right: 0,
                  child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.outline),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildColumn(
                      context: context,
                      controller: _hourCtrl,
                      itemCount: _kHourCount,
                      selectedValue: notifier.hour,
                      isEditing: notifier.editingHour,
                      textCtrl: _hourTextCtrl,
                      focusNode: _hourFocus,
                      onWheelChanged: isEnabled
                          ? (i) {
                              final h = i % _kHourCount;
                              _notifier.setHour(h);
                              widget.onChanged!(
                                  TimeOfDay(hour: h, minute: _notifier.minute));
                            }
                          : null,
                      onTapCenter: isEnabled ? _startEditHour : null,
                      onCommit: _commitHour,
                      itemExtent: itemExtent,
                    ),
                    Text(
                      ':',
                      style: AppTypography.labelMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    _buildColumn(
                      context: context,
                      controller: _minuteCtrl,
                      itemCount: _kMinuteCount,
                      selectedValue: notifier.minute,
                      isEditing: notifier.editingMinute,
                      textCtrl: _minuteTextCtrl,
                      focusNode: _minuteFocus,
                      onWheelChanged: isEnabled
                          ? (i) {
                              final m = i % _kMinuteCount;
                              _notifier.setMinute(m);
                              widget.onChanged!(
                                  TimeOfDay(hour: _notifier.hour, minute: m));
                            }
                          : null,
                      onTapCenter: isEnabled ? _startEditMinute : null,
                      onCommit: _commitMinute,
                      itemExtent: itemExtent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.label.isEmpty) return picker;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTypography.bodySmall(context)),
        const SizedBox(height: 4),
        picker,
      ],
    );
  }

  Widget _buildColumn({
    required BuildContext context,
    required FixedExtentScrollController controller,
    required int itemCount,
    required int selectedValue,
    required bool isEditing,
    required TextEditingController textCtrl,
    required FocusNode focusNode,
    required ValueChanged<int>? onWheelChanged,
    required VoidCallback? onTapCenter,
    required VoidCallback onCommit,
    required double itemExtent,
  }) {
    final theme = Theme.of(context);

    if (isEditing) {
      return SizedBox(
        width: 48,
        height: itemExtent * 3,
        child: Center(
          child: TextField(
            controller: textCtrl,
            focusNode: focusNode,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
              _RangeInputFormatter(itemCount - 1),
            ],
            style: AppTypography.labelMedium(context).copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              counterText: '',
            ),
            onSubmitted: (_) => onCommit(),
          ),
        ),
      );
    }

    return GestureDetector(
      onTapUp: (details) {
        final centerStart = itemExtent;
        final centerEnd = itemExtent * 2;
        if (details.localPosition.dy >= centerStart &&
            details.localPosition.dy <= centerEnd) {
          onTapCenter?.call();
        }
      },
      child: SizedBox(
        width: 48,
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: itemExtent,
          diameterRatio: 1.2,
          physics: onWheelChanged != null
              ? const FixedExtentScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          onSelectedItemChanged: onWheelChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount * _kLoopMultiplier,
            builder: (context, i) {
              final value = i % itemCount;
              final isSelected = value == selectedValue;
              return Center(
                child: Text(
                  value.toString().padLeft(2, '0'),
                  style: AppTypography.labelMedium(context).copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
