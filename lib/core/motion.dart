import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ─────────────────────────────────────────────────────────────────────
/// Motion language for the boxy design:
/// - Fast, decelerating, precise. Nothing bouncy (sharp corners, sharp
///   motion), nothing slower than 450ms.
/// - Motion is feedback + entrance only — no idle loops.
/// - Everything honours the OS "remove animations" accessibility setting.
/// ─────────────────────────────────────────────────────────────────────

const Duration kMotionFast = Duration(milliseconds: 120); // micro-feedback
const Duration kMotion = Duration(milliseconds: 220); // entrances
const Duration kMotionSlow = Duration(milliseconds: 450); // number tweens
const Duration kMotionStagger = Duration(milliseconds: 35); // cascade step
const Curve kMotionCurve = Curves.easeOutCubic;

bool _disableAnimations(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Standard page transition: quick fade + ~12px rise.
/// Use in GoRoute pageBuilder instead of `builder`.
CustomTransitionPage<T> boxyPage<T>({
  required Widget child,
  bool fullscreenDialog = false,
}) {
  return CustomTransitionPage<T>(
    child: child,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: kMotion,
    reverseTransitionDuration: kMotionFast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: kMotionCurve,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Plays once when first inserted: fade in + rise [offset] px.
/// Give it a `key` when used in lists (see ReportsScreen) so items keep
/// their finished state across rebuilds.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    this.delay = Duration.zero,
    this.offset = 14.0,
    this.child,
  });

  final Duration delay;
  final double offset;
  final Widget? child;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kMotion,
  );
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: kMotionCurve,
  );
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (_disableAnimations(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Tactile press-down for large tap targets (cards, big buttons).
/// Scales to [pressedScale] while pressed, springs back on release.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, this.pressedScale = 0.985, this.child});

  final double pressedScale;
  final Widget? child;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed && !_disableAnimations(context)
        ? widget.pressedScale
        : 1.0;
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: scale,
        duration: _pressed ? kMotionFast : kMotion,
        curve: kMotionCurve,
        child: widget.child,
      ),
    );
  }
}

/// Number that tweens to new values when [value] changes (e.g. range
/// switch) and counts up from zero on first appearance. Style color
/// changes animate too. Pair with tabular figures for column alignment.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.duration = kMotionSlow,
    this.fractionDigits = 2,
  });

  final double value;
  final TextStyle style;
  final Duration duration;
  final int fractionDigits;

  @override
  Widget build(BuildContext context) {
    final d = _disableAnimations(context) ? Duration.zero : duration;
    return TweenAnimationBuilder<double>(
      // begin only affects first appearance; retargets animate from the
      // current value automatically.
      tween: Tween(begin: 0, end: value),
      duration: d,
      curve: kMotionCurve,
      builder: (context, v, _) => AnimatedDefaultTextStyle(
        duration: d,
        curve: kMotionCurve,
        style: style,
        child: Text(v.toStringAsFixed(fractionDigits)),
      ),
    );
  }
}
