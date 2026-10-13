import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/utils/tv_build.dart';

/// Exposes both range limits as keyboard-adjustable sliders on TV.
class TvRangeSlider extends StatelessWidget {
  const TvRangeSlider({
    super.key,
    required this.values,
    required this.min,
    required this.max,
    required this.divisions,
    required this.labels,
    required this.onChanged,
  });

  final RangeValues values;
  final double min;
  final double max;
  final int divisions;
  final RangeLabels labels;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!TvBuild.enabled) {
      return RangeSlider(
        values: values,
        min: min,
        max: max,
        divisions: divisions,
        labels: labels,
        onChanged: onChanged,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('下限 ${labels.start}'),
        Slider(
          value: values.start,
          min: min,
          max: max,
          divisions: divisions,
          label: labels.start,
          onChanged: (value) =>
              onChanged(RangeValues(value.clamp(min, values.end), values.end)),
        ),
        Text('上限 ${labels.end}'),
        Slider(
          value: values.end,
          min: min,
          max: max,
          divisions: divisions,
          label: labels.end,
          onChanged: (value) => onChanged(
            RangeValues(values.start, value.clamp(values.start, max)),
          ),
        ),
      ],
    );
  }
}

/// Adds remote long-OK/menu-key support to an already focusable control.
class TvRemotePress extends StatefulWidget {
  const TvRemotePress({
    super.key,
    required this.onPressed,
    required this.onLongPress,
    required this.child,
  });

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  State<TvRemotePress> createState() => _TvRemotePressState();
}

class _TvRemotePressState extends State<TvRemotePress> {
  Timer? _timer;
  LogicalKeyboardKey? _pressed;
  bool _longPress = false;

  void _cancel() {
    _timer?.cancel();
    _pressed = null;
    _longPress = false;
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (widget.onLongPress == null) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.contextMenu) {
      if (event is KeyDownEvent) widget.onLongPress!();
      return KeyEventResult.handled;
    }
    if (key != LogicalKeyboardKey.select &&
        key != LogicalKeyboardKey.enter &&
        key != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      _cancel();
      _pressed = key;
      _timer = Timer(const Duration(milliseconds: 650), () {
        if (!mounted || !node.hasFocus || _pressed != key) return;
        _longPress = true;
        widget.onLongPress?.call();
      });
    } else if (event is KeyUpEvent && _pressed == key) {
      final activate = !_longPress;
      _cancel();
      if (activate) widget.onPressed?.call();
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => !TvBuild.enabled
      ? widget.child
      : Focus(
          canRequestFocus: false,
          onFocusChange: (focused) {
            if (!focused) _cancel();
          },
          onKeyEvent: _handleKey,
          child: widget.child,
        );
}

/// Keyboard access for the custom (pointer-only) media progress bar.
class TvSeekControl extends StatefulWidget {
  const TvSeekControl({
    super.key,
    required this.onStep,
    required this.onActivate,
    required this.child,
  });

  final ValueChanged<int> onStep;
  final VoidCallback onActivate;
  final Widget child;

  @override
  State<TvSeekControl> createState() => _TvSeekControlState();
}

class _TvSeekControlState extends State<TvSeekControl> {
  DateTime? _lastStep;

  @override
  Widget build(BuildContext context) => !TvBuild.enabled
      ? widget.child
      : Focus(
          debugLabel: 'TV progress bar',
          onKeyEvent: (_, event) {
            if (event is KeyUpEvent) return KeyEventResult.ignored;
            final direction = switch (event.logicalKey) {
              LogicalKeyboardKey.arrowLeft => -1,
              LogicalKeyboardKey.arrowRight => 1,
              _ => 0,
            };
            if (direction != 0) {
              final now = DateTime.now();
              if (event is KeyDownEvent ||
                  _lastStep == null ||
                  now.difference(_lastStep!) >=
                      const Duration(milliseconds: 250)) {
                _lastStep = now;
                widget.onStep(direction);
              }
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter) {
              if (event is KeyDownEvent) widget.onActivate();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Semantics(label: '播放进度，左右调整，确定播放或暂停', child: widget.child),
        );
}
