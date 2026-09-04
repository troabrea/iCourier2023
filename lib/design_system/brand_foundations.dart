import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/brand_elevation.dart';
import '../theme/brand_tokens.dart';

export '../theme/brand_elevation.dart';

/// Spacing scale shared by every brand (spec §2.3).
abstract final class BrandSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Shape constants that are fixed across brands.
///
/// Brand-controlled corners live in `BrandTokens.radiusSm/Md/Lg`; the values
/// here describe shapes whose geometry is part of the design language itself
/// and therefore identical for all 35 identities.
abstract final class BrandShape {
  /// Fully rounded ends, for chips, pills and circular buttons.
  static const double pill = 999;

  /// Bottom corners of the brand header.
  ///
  /// Kept shallow on purpose: the curve has to read as a shape without cutting
  /// far enough into a full-bleed banner underneath to eat its artwork.
  static const double headerSkirt = 18;

  /// Corner of the floating tab dock.
  static const double tabDock = 26;

  /// Top corners of a modal sheet.
  static const double sheet = 24;

  /// Rounded square behind a quick action or service glyph.
  static const double glyphTile = 12;

  /// Selection checkbox in the availability list.
  static const double checkbox = 6;

  /// Segment of the four-part package progress rail.
  static const double rail = 3;

  /// Card carrying the membership QR code.
  static const double qr = 12;
}

/// Brand glyphs, referenced by the same asset names the repository already uses.
///
/// Only single-tone artwork belongs here. `correo.svg`, `informacion.svg` and
/// `preguntas.svg` draw their detail as a white knockout over a solid shape, so
/// tinting them collapses the whole glyph into a filled blob; single-tone
/// equivalents are used in their place.
abstract final class BrandIcons {
  static const String receptions = 'images/recepciones.svg';
  static const String available = 'images/disponible.svg';
  static const String shipped = 'images/embarcado.svg';
  static const String atDestination = 'images/endestino.svg';
  static const String received = 'images/recibido.svg';
  static const String missingInvoice = 'images/sinfactura.svg';
  static const String prealert = 'images/prealerta.svg';
  static const String track = 'images/rastrearpaquete.svg';
  static const String calculator = 'images/calculadora.svg';
  static const String history = 'images/consultahistorica.svg';
  static const String news = 'images/noticias.svg';
  static const String branches = 'images/sucursales.svg';
  static const String information = 'images/transferenciasalida.svg';
  static const String whatsapp = 'images/whatsapp.svg';
  static const String services = 'images/servicios.svg';
  static const String questions = 'images/consultahistorica.svg';
  static const String uploadInvoice = 'images/subirfactura.svg';
  static const String refresh = 'images/refrescar.svg';
  static const String user = 'images/usuario.svg';
  static const String phone = 'images/telefono.svg';
  static const String email = 'images/arroba.svg';
  static const String schedule = 'images/horario.svg';
  static const String mapMarker = 'images/mapmarker.svg';
  static const String assistant = 'images/asistente.svg';
}

/// Renders a brand glyph as a tinted mask.
///
/// The asset supplies the silhouette only; the colour always comes from a
/// token, so the same file reads correctly on every brand and in both themes.
class BrandGlyph extends StatelessWidget {
  const BrandGlyph(
    this.asset, {
    super.key,
    required this.color,
    this.size = 24,
    this.semanticLabel,
  });

  final String asset;
  final Color color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        semanticsLabel: semanticLabel,
      );
}

/// The three stacked dots that open the "más" tab.
class BrandMoreGlyph extends StatelessWidget {
  const BrandMoreGlyph({super.key, required this.color, this.size = 29});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dot = size * 5 / 29;
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < 3; index++) ...[
            if (index > 0) SizedBox(height: dot * 0.8),
            Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rounded square holding a glyph over a wash of its own accent.
class BrandGlyphTile extends StatelessWidget {
  const BrandGlyphTile({
    super.key,
    required this.asset,
    this.accent,
    this.size = 38,
    this.glyphSize = 21,
    this.shape = BoxShape.rectangle,
  });

  final String asset;
  final Color? accent;
  final double size;
  final double glyphSize;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final color = accent ?? tokens.primary;
    final colors = tokens.softAccentPair(color);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.background,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(BrandShape.glyphTile)
            : null,
      ),
      child: BrandGlyph(asset, color: colors.foreground, size: glyphSize),
    );
  }
}

/// Unbacked glyph that identifies an action inside a surface row.
///
/// It follows the social-link treatment: the brand primary carries the mark
/// directly, with an accessible foreground fallback for dark surfaces and
/// pale brand palettes.
class BrandActionGlyph extends StatelessWidget {
  const BrandActionGlyph({
    super.key,
    required this.asset,
    this.accent,
  });

  /// Alignment box reserved by the action glyph.
  static const double boxSize = 44;

  /// Visual size of the unbacked action glyph.
  static const double glyphSize = 32;

  final String asset;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final preferred = accent ?? tokens.primary;
    final foreground = tokens.accessibleForeground(
      tokens.surface,
      preferred: preferred,
      minimumContrast: 3,
    );
    return SizedBox.square(
      dimension: boxSize,
      child: Center(
        child: BrandGlyph(asset, color: foreground, size: glyphSize),
      ),
    );
  }
}

/// Small capsule carrying a count or a status word.
class BrandPill extends StatelessWidget {
  const BrandPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.uppercase = false,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool uppercase;
  final double fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(BrandShape.pill),
      ),
      child: Text(
        uppercase ? label.toUpperCase() : label,
        style: tokens.body(
          fontSize,
          weight: FontWeight.w700,
          color: foreground,
          letterSpacing: uppercase ? fontSize * 0.05 : null,
        ),
      ),
    );
  }
}

/// Chevron pointing right, used on every drill-down row.
class BrandChevron extends StatelessWidget {
  const BrandChevron({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Icon(
        Icons.chevron_right,
        size: size + 6,
        color: color ?? context.brand.textMuted,
      );
}

/// Uppercase label that introduces a block of content.
class BrandSectionLabel extends StatelessWidget {
  const BrandSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
      child: Text(label.toUpperCase(), style: tokens.eyebrow(11)),
    );
  }
}

/// Card surface shared by list rows, forms and content blocks.
class BrandCard extends StatelessWidget {
  const BrandCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
    this.margin,
    this.color,
    this.borderColor,
    this.opacity = 1,
    this.shadow = false,
    this.clip = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Color? color;
  final Color? borderColor;
  final double opacity;
  final bool shadow;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final radius = BorderRadius.circular(tokens.radiusMd);
    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? tokens.surface,
        border: Border.all(color: borderColor ?? tokens.border),
        borderRadius: radius,
        boxShadow: shadow ? BrandElevation.card : null,
      ),
      child: clip
          ? ClipRRect(borderRadius: radius, child: child)
          : Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }
    if (opacity < 1) {
      content = Opacity(opacity: opacity, child: content);
    }
    return margin == null ? content : Padding(padding: margin!, child: content);
  }
}

/// Full-width primary action.
class BrandPrimaryButton extends StatelessWidget {
  const BrandPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
    this.pill = false,
    this.fontSize = 14,
    this.verticalPadding = 13,
    this.background,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final bool pill;
  final double fontSize;
  final double verticalPadding;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final fill = background ?? tokens.primary;
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: fill,
        foregroundColor: foreground ?? tokens.onAccent(fill),
        minimumSize: const Size(44, 44),
        // Horizontal padding is invisible when the button expands, but it is
        // what keeps the label off the edges when it wraps its content.
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: verticalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            pill ? BrandShape.pill : tokens.radiusSm,
          ),
        ),
        textStyle: tokens.body(fontSize, weight: FontWeight.w700),
      ),
      child: Text(label),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Full-width secondary action drawn as an outline.
class BrandOutlineButton extends StatelessWidget {
  const BrandOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
    this.pill = false,
    this.fontSize = 13,
    this.verticalPadding = 11,
    this.selected = false,
    this.foreground,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final bool pill;
  final double fontSize;
  final double verticalPadding;
  final bool selected;
  final Color? foreground;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final style = OutlinedButton.styleFrom(
      foregroundColor: foreground ?? (selected ? tokens.primary : tokens.text),
      backgroundColor: selected ? tokens.surfaceAlt : tokens.surface,
      minimumSize: const Size(44, 44),
      padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 12),
      side: BorderSide(
        color: selected ? tokens.primary : tokens.border,
        width: selected ? 2 : 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          pill ? BrandShape.pill : tokens.radiusSm,
        ),
      ),
      textStyle: tokens.body(fontSize, weight: FontWeight.w700),
    );
    final button = icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: icon!,
            label: Text(label),
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Labelled form field shared by both alert forms and the login screen.
class BrandField extends StatelessWidget {
  const BrandField({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.suffix,
    this.enabled = true,
    this.maxLines = 1,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final bool enabled;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: tokens.body(12,
                weight: FontWeight.w600, color: tokens.textMuted),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          enabled: enabled,
          maxLines: maxLines,
          style: tokens.body(14, weight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: tokens.body(14,
                weight: FontWeight.w500, color: tokens.textMuted),
            suffixIcon: suffix,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            filled: true,
            fillColor: tokens.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusSm),
              borderSide: BorderSide(color: tokens.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusSm),
              borderSide: BorderSide(color: tokens.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusSm),
              borderSide: BorderSide(color: tokens.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dashed drop target for invoice attachments.
class BrandDropZone extends StatelessWidget {
  const BrandDropZone({super.key, required this.label, this.onTap, this.child});

  final String label;
  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return GestureDetector(
      onTap: onTap,
      child: DottedBorderBox(
        child: Padding(
          padding: const EdgeInsets.all(BrandSpace.lg),
          child: child ??
              Text(
                label,
                textAlign: TextAlign.center,
                style: tokens.body(
                  13,
                  weight: FontWeight.w500,
                  color: tokens.textMuted,
                ),
              ),
        ),
      ),
    );
  }
}

/// Rounded rectangle drawn with a dashed brand border.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: tokens.border,
        radius: tokens.radiusMd,
      ),
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 6;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + 5;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
