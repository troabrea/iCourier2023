import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';

/// Delay for one item in a bounded manifest-style entrance sequence.
///
/// The cap keeps a long backend list from turning motion into latency while
/// preserving the sense that the first visible items arrived in order.
Duration brandManifestDelay(int index, {int startMilliseconds = 0}) => Duration(
      milliseconds: startMilliseconds + math.min(index, 6) * 55,
    );

/// Reveals loaded content as if it passed through a branded parcel scanner.
///
/// A diagonal mask carries the spatial change while a short primary/secondary
/// beam marks its edge. The effect runs once for this widget identity, stops
/// completely after arrival, and resolves immediately when reduced motion is
/// requested by the operating system.
final class BrandManifestReveal extends StatefulWidget {
  const BrandManifestReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 620),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<BrandManifestReveal> createState() => _BrandManifestRevealState();
}

class _BrandManifestRevealState extends State<BrandManifestReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _delay;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    if (media.disableAnimations || media.accessibleNavigation) {
      _delay?.cancel();
      _controller.value = 1;
      _scheduled = true;
      return;
    }
    if (_scheduled) {
      return;
    }
    _scheduled = true;
    if (widget.delay == Duration.zero) {
      _controller.forward();
      return;
    }
    _delay = Timer(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final direction = Directionality.of(context);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        if (_controller.value >= 1) {
          return child!;
        }
        final progress = Curves.easeOutExpo.transform(_controller.value);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipPath(
              clipper: _ManifestClipper(
                progress: progress,
                direction: direction,
              ),
              child: child,
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ScannerBeamPainter(
                    progress: progress,
                    direction: direction,
                    primary: tokens.primary,
                    secondary: tokens.secondary,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _ManifestClipper extends CustomClipper<Path> {
  const _ManifestClipper({
    required this.progress,
    required this.direction,
  });

  final double progress;
  final TextDirection direction;

  @override
  Path getClip(Size size) {
    final edge = size.width * progress;
    const rake = 14.0;
    if (direction == TextDirection.rtl) {
      return Path()
        ..moveTo(size.width, 0)
        ..lineTo(math.max(size.width - edge - rake, 0), 0)
        ..lineTo(math.max(size.width - edge + rake, 0), size.height)
        ..lineTo(size.width, size.height)
        ..close();
    }
    return Path()
      ..moveTo(0, 0)
      ..lineTo(math.min(edge + rake, size.width), 0)
      ..lineTo(math.min(math.max(edge - rake, 0), size.width), size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_ManifestClipper oldClipper) =>
      oldClipper.progress != progress || oldClipper.direction != direction;
}

final class _ScannerBeamPainter extends CustomPainter {
  const _ScannerBeamPainter({
    required this.progress,
    required this.direction,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final TextDirection direction;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) {
      return;
    }
    final x = direction == TextDirection.rtl
        ? size.width * (1 - progress)
        : size.width * progress;
    final fade = math.sin(progress * math.pi).clamp(0.0, 1.0).toDouble();
    final glowBottom = math.max(size.height - 4, 4).toDouble();
    final beamBottom = math.max(size.height - 1, 1).toDouble();
    final glow = Paint()
      ..color = primary.withValues(alpha: 0.16 * fade)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final beam = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primary.withValues(alpha: 0),
          primary.withValues(alpha: 0.95 * fade),
          secondary.withValues(alpha: 0.95 * fade),
          secondary.withValues(alpha: 0),
        ],
        stops: const [0, 0.28, 0.72, 1],
      ).createShader(Rect.fromLTWH(x - 1, 0, 2, size.height))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset(x, 4), Offset(x, glowBottom), glow)
      ..drawLine(Offset(x, 1), Offset(x, beamBottom), beam);
  }

  @override
  bool shouldRepaint(_ScannerBeamPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.direction != direction ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary;
}
