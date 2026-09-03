import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design_system/brand_foundations.dart';
import '../theme/brand_tokens.dart';

/// Circular artwork that identifies the configured assistant.
///
/// The backend sanitizes the raw SVG. Rendering still degrades to the bundled
/// assistant glyph when a stale or malformed record reaches the app.
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({
    super.key,
    required this.avatarSvg,
    required this.semanticLabel,
    this.size = 52,
    this.padding = 6,
    this.backgroundColor,
    this.fallbackColor,
  });

  /// Shared-element identity between the dock and the welcome screen.
  static const String heroTag = 'assistant-avatar';

  final String avatarSvg;
  final String semanticLabel;
  final double size;
  final double padding;
  final Color? backgroundColor;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final fallback = _fallback(tokens);
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: backgroundColor ?? tokens.surface,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: avatarSvg.isEmpty
              ? fallback
              : SvgPicture.string(
                  avatarSvg,
                  width: size - padding * 2,
                  height: size - padding * 2,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stackTrace) => fallback,
                ),
        ),
      ),
    );
  }

  Widget _fallback(BrandTokens tokens) => BrandGlyph(
        BrandIcons.assistant,
        color: fallbackColor ?? tokens.primary,
        size: size * 0.64,
      );
}

/// Plays a single, bounded entrance gesture around an assistant avatar.
///
/// The child always starts and ends at rest, so layout and hit testing remain
/// stable. Customers who request reduced motion see the final state directly.
class AssistantAvatarEntrance extends StatefulWidget {
  const AssistantAvatarEntrance({
    super.key,
    required this.child,
    this.rotate = false,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.peakScale = 1.12,
  });

  final Widget child;
  final bool rotate;
  final Duration delay;
  final Duration duration;
  final double peakScale;

  @override
  State<AssistantAvatarEntrance> createState() =>
      _AssistantAvatarEntranceState();
}

class _AssistantAvatarEntranceState extends State<AssistantAvatarEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 1, end: widget.peakScale).chain(
        CurveTween(curve: Curves.easeOutCubic),
      ),
      weight: 42,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: widget.peakScale, end: 1).chain(
        CurveTween(curve: Curves.easeOutCubic),
      ),
      weight: 58,
    ),
  ]).animate(_controller);
  Timer? _delayTimer;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) {
      return;
    }
    _scheduled = true;
    final media = MediaQuery.maybeOf(context);
    if ((media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false)) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
      return;
    }
    _delayTimer = Timer(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) => Transform.rotate(
          angle: widget.rotate
              ? Curves.easeInOutCubic.transform(_controller.value) * math.pi * 2
              : 0,
          child: Transform.scale(scale: _scale.value, child: child),
        ),
      );
}
