import 'package:flutter/material.dart';

/// Elevation presets shared by every brand (spec §2.3).
///
/// The design language allows exactly one soft shadow for cards and one for
/// floating surfaces; the hero and dock variants are the two floating cases.
/// The values are neutral blacks by design, so they stay identical across the
/// 35 identities and are declared here rather than in a widget.
abstract final class BrandElevation {
  /// `0 1px 2px rgba(0,0,0,.03)` — resting list and content cards.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// `0 12px 30px rgba(0,0,0,.13), 0 2px 6px rgba(0,0,0,.05)` — the home card
  /// that overlaps the brand header.
  static const List<BoxShadow> hero = [
    BoxShadow(
      color: Color(0x21000000),
      blurRadius: 30,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x0d000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// `0 8px 24px rgba(0,0,0,.10)` — the floating tab dock.
  static const List<BoxShadow> dock = [
    BoxShadow(
      color: Color(0x1a000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Glow under the raised home button, tinted with the brand primary.
  static List<BoxShadow> homeButton(Color primary) => [
        BoxShadow(
          color: primary.withValues(alpha: 0.45),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}
