import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Uses real Flutter focus and actions, including controls in popup routes.
/// The outline follows the focused control; no pointer events are synthesized.
class TvNavigation extends StatefulWidget {
  const TvNavigation({super.key, required this.child});

  final Widget child;

  @override
  State<TvNavigation> createState() => _TvNavigationState();
}

class _TvNavigationState extends State<TvNavigation> {
  final _outline = ValueNotifier<Rect?>(null);
  FocusHighlightStrategy? _previousStrategy;
  bool _framePending = false;

  @override
  void initState() {
    super.initState();
    final manager = FocusManager.instance;
    _previousStrategy = manager.highlightStrategy;
    manager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    manager.addEarlyKeyEventHandler(_handleControlKey);
    // Follow scrolling and route animations without starting an idle ticker.
    // This app-lifetime callback only runs when Flutter already draws a frame.
    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      if (!mounted || _framePending) return;
      _framePending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _framePending = false;
        if (mounted) _refreshFocus();
      });
    });
  }

  void _refreshFocus() {
    final node = FocusManager.instance.primaryFocus;
    if (node is FocusScopeNode) {
      // Newly pushed pages/dialogs and asynchronously loaded lists need an
      // initial control. Existing leaf focus is left alone on route return.
      final context = node.context;
      if (context != null) {
        final policy = FocusTraversalGroup.maybeOf(context);
        final first = policy?.findFirstFocus(node, ignoreCurrentFocus: true);
        if (first != null && first != node && first is! FocusScopeNode) {
          first.requestFocus();
        }
      }
    }
    final nodeContext = node?.context;
    final target = nodeContext?.mounted == true
        ? nodeContext!.findRenderObject()
        : null;
    final overlay = context.findRenderObject();
    Rect? rect;
    if (node != null &&
        node is! FocusScopeNode &&
        !node.skipTraversal &&
        target is RenderBox &&
        target.attached &&
        target.hasSize &&
        overlay is RenderBox &&
        overlay.hasSize) {
      rect = (target.localToGlobal(Offset.zero) & target.size)
          .shift(-overlay.localToGlobal(Offset.zero))
          .intersect(Offset.zero & overlay.size);
      if (rect.isEmpty) rect = null;
    }
    if (_outline.value != rect) _outline.value = rect;
  }

  KeyEventResult _handleControlKey(KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final node = FocusManager.instance.primaryFocus;
    final editable = node?.context
        ?.findAncestorStateOfType<EditableTextState>();
    if (event is KeyRepeatEvent &&
        editable == null &&
        (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
      return KeyEventResult.handled;
    }
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => TraversalDirection.up,
      LogicalKeyboardKey.arrowDown => TraversalDirection.down,
      LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
      LogicalKeyboardKey.arrowRight => TraversalDirection.right,
      _ => null,
    };
    if (direction != null) _allowNestedPageTraversal(node?.context);
    if (editable == null) {
      // RadioGroup normally selects immediately on arrows. On TV, moving the
      // highlight must never commit a setting or dismiss a choice dialog.
      var inRadioGroup = false;
      if (direction != null) {
        node?.context?.visitAncestorElements((element) {
          inRadioGroup = element.widget is RadioGroup;
          return !inRadioGroup;
        });
      }
      if (inRadioGroup) {
        node!.focusInDirection(direction!);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (View.of(context).viewInsets.bottom > 0) {
      return KeyEventResult.ignored;
    }
    // After dismissing the Android keyboard, arrows leave the field. OK can
    // reopen it. While the keyboard is open, its normal text controls win.
    if (direction != null) {
      node!.focusInDirection(direction);
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
      editable.requestKeyboard();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _allowNestedPageTraversal(BuildContext? target) {
    // RouterOutlet creates nested Navigators whose page focus scopes stop at
    // their edges by default. Let arrows reach the surrounding navigation rail
    // or settings categories. Popup routes and their focus scopes stay local.
    while (target != null && target.mounted) {
      final route = ModalRoute.of(target);
      final pageContext = route?.subtreeContext;
      final navigator = route?.navigator;
      if (route is! PageRoute || pageContext == null || navigator == null) return;
      if (navigator.context.findAncestorStateOfType<NavigatorState>() == null) {
        return;
      }
      FocusScope.of(pageContext).directionalTraversalEdgeBehavior =
          TraversalEdgeBehavior.parentScope;
      target = navigator.context;
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_handleControlKey);
    FocusManager.instance.highlightStrategy = _previousStrategy!;
    _outline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    policy: ReadingOrderTraversalPolicy(
      requestFocusCallback:
          (node, {alignment, alignmentPolicy, duration, curve}) {
            node.requestFocus();
            final target = node.context;
            if (target != null) {
              unawaited(
                Scrollable.ensureVisible(
                  target,
                  alignment: 0.5,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                ),
              );
            }
          },
    ),
    child: Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.select, includeRepeats: false):
            ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter, includeRepeats: false):
            ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter, includeRepeats: false):
            ActivateIntent(),
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(navigationMode: NavigationMode.directional),
            child: widget.child,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _TvFocusPainter(_outline)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TvFocusPainter extends CustomPainter {
  _TvFocusPainter(this.outline) : super(repaint: outline);

  final ValueNotifier<Rect?> outline;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = outline.value;
    if (rect == null) return;
    final border = RRect.fromRectAndRadius(
      rect.deflate(2),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      border,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.black87,
    );
    canvas.drawRRect(
      border,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFFD54F),
    );
  }

  @override
  bool shouldRepaint(_TvFocusPainter oldDelegate) =>
      oldDelegate.outline != outline;
}
