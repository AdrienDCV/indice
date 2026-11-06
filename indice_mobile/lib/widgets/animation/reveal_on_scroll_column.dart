import 'dart:async';

import 'package:flutter/material.dart';

class RevealOnScrollColumn extends StatefulWidget {
  const RevealOnScrollColumn({
    super.key,
    required this.children,
    this.spacing = 0,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  static bool isRevealed(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RevealedScope>()?.revealed ??
      true;

  @override
  State<RevealOnScrollColumn> createState() => _RevealOnScrollColumnState();
}

class _RevealOnScrollColumnState extends State<RevealOnScrollColumn>
    with TickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 400);
  static const _delay = Duration(milliseconds: 80);
  static const _offset = 16.0;

  final List<GlobalKey> _keys = [];
  final List<AnimationController> _controllers = [];
  final Set<int> _scheduled = {};
  final List<Timer> _timers = [];
  ScrollableState? _scrollable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollable?.position.removeListener(_scheduleReveal);
    _scrollable = Scrollable.maybeOf(context);
    _scrollable?.position.addListener(_scheduleReveal);
    _addControllers();
  }

  @override
  void didUpdateWidget(RevealOnScrollColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    _addControllers();
  }

  @override
  void dispose() {
    _scrollable?.position.removeListener(_scheduleReveal);
    for (final timer in _timers) {
      timer.cancel();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addControllers() {
    final revealed =
        _controllers.isNotEmpty || MediaQuery.disableAnimationsOf(context);
    while (_controllers.length < widget.children.length) {
      _keys.add(GlobalKey());
      _controllers.add(
        AnimationController(
          vsync: this,
          duration: _duration,
          value: revealed ? 1 : 0,
        ),
      );
    }
    _scheduleReveal();
  }

  void _scheduleReveal() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _revealVisibleChildren(),
    );
  }

  void _revealVisibleChildren() {
    if (!mounted) return;
    final viewport = _scrollable?.context.findRenderObject() as RenderBox?;
    var queued = 0;
    for (final (index, controller) in _controllers.indexed) {
      if (!controller.isDismissed || _scheduled.contains(index)) continue;
      if (!_isVisible(_keys[index], viewport)) continue;
      _scheduled.add(index);
      _timers.add(Timer(_delay * queued, controller.forward));
      queued++;
    }
  }

  bool _isVisible(GlobalKey key, RenderBox? viewport) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    if (viewport == null) return true;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    return top < viewport.size.height && top + box.size.height > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: widget.spacing,
      crossAxisAlignment: widget.crossAxisAlignment,
      children: [
        for (final (index, child) in widget.children.indexed)
          KeyedSubtree(
            key: _keys[index],
            child: AnimatedBuilder(
              animation: _controllers[index],
              builder: (context, child) {
                final controller = _controllers[index];
                final progress = Curves.easeOutCubic.transform(
                  controller.value,
                );
                return Opacity(
                  opacity: progress,
                  child: Transform.translate(
                    offset: Offset(0, _offset * (1 - progress)),
                    child: _RevealedScope(
                      revealed: !controller.isDismissed,
                      child: child!,
                    ),
                  ),
                );
              },
              child: child,
            ),
          ),
      ],
    );
  }
}

class _RevealedScope extends InheritedWidget {
  const _RevealedScope({required this.revealed, required super.child});

  final bool revealed;

  @override
  bool updateShouldNotify(_RevealedScope oldWidget) =>
      revealed != oldWidget.revealed;
}
