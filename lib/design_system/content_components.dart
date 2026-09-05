import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/branch_hours.dart';
import '../services/model/banner.dart';
import '../services/model/mensaje.dart';
import '../services/model/noticia.dart';
import '../services/model/sucursal.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
import 'brand_foundations.dart';

/// Shape used until the real artwork has been measured.
///
/// Banner dimensions vary per upload, so the carousel adopts the proportion of
/// the first image it loads instead of imposing one. These pieces carry their
/// own headline right up to the edge, and forcing them into a mismatched box
/// either ate the first characters or left thick bars.
const double bannerArtworkRatio = 1200 / 560;

/// Range a measured banner is allowed to take, so one malformed upload cannot
/// turn the strip into a sliver or a wall.
const double _minBannerRatio = 1.5;
const double _maxBannerRatio = 4;

/// Tallest a banner may get, as a share of the screen.
///
/// The strip has to share the first screen with the packages card and the tab
/// bar, so a square upload cannot be allowed to claim the whole fold.
const double _bannerViewportShare = 0.30;

/// Ceiling a banner may reach on this screen.
double maxBannerHeight(BuildContext context) =>
    MediaQuery.sizeOf(context).height * _bannerViewportShare;

/// Height the strip is expected to take at [width], for budgeting the space
/// around it before the carousel has laid itself out.
///
/// Uses the shape the CMS actually ships rather than the ceiling: reserving the
/// worst case would fold away the quick actions on screens that had room for
/// them all along.
double expectedBannerHeight(BuildContext context, double width) {
  final natural = width / bannerArtworkRatio;
  final ceiling = maxBannerHeight(context);
  return natural < ceiling ? natural : ceiling;
}

/// Colours of a banner's left and right edges along its top.
///
/// The first answer the backdrop can give, before the artwork it is washed
/// from has been decoded. Two colours are enough for that moment: the corners
/// of the header's skirt are the only part of the strip anyone sees, and each
/// one continues the side of the artwork it sits over.
@immutable
class BannerEdgeColors {
  const BannerEdgeColors(this.left, this.right);

  final Color left;
  final Color right;

  @override
  bool operator ==(Object other) =>
      other is BannerEdgeColors && other.left == left && other.right == right;

  @override
  int get hashCode => Object.hash(left, right);
}

/// Edge colours already read, keyed by url. Sampling costs a decode, and the
/// answer cannot change for a given image.
final Map<String, BannerEdgeColors> _bannerEdgeCache = {};

/// Width the backdrop wash is decoded at.
///
/// The wash carries colour, not detail, so it is stretched from a thumbnail
/// this small on purpose: blown up across the strip the bilinear filter turns
/// it into a soft field of the artwork's own colours, which is the whole
/// effect, and it costs one tiny decode instead of a blur every frame.
const int _bannerBackdropWidth = 8;

/// Reads the top-left and top-right colour of the artwork at [url].
///
/// Decodes a thumbnail rather than the full upload: the answer is an average
/// over a band of pixels, which survives the downscale, and a 48px decode costs
/// almost nothing next to a 1200px one.
Future<BannerEdgeColors?> readBannerEdgeColors(String url) async {
  if (url.isEmpty) {
    return null;
  }
  final known = _bannerEdgeCache[url];
  if (known != null) {
    return known;
  }
  final completer = Completer<ui.Image?>();
  final stream = ResizeImage(
    CachedNetworkImageProvider(url),
    width: 48,
    allowUpscaling: false,
  ).resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!completer.isCompleted) {
        completer.complete(info.image);
      }
      stream.removeListener(listener);
    },
    onError: (_, __) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  final image = await completer.future;
  if (image == null) {
    return null;
  }
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (pixels == null || image.width < 2 || image.height < 1) {
    return null;
  }
  // The strip continues the top of the artwork, so only the top band speaks
  // for it; a colour taken from halfway down would describe a different part
  // of the piece.
  final rows = (image.height * 0.25).ceil().clamp(1, image.height);
  final columns = (image.width * 0.04).ceil().clamp(1, image.width ~/ 2);
  final edges = BannerEdgeColors(
    _averageColor(pixels, image.width, rows, 0, columns),
    _averageColor(pixels, image.width, rows, image.width - columns, columns),
  );
  _bannerEdgeCache[url] = edges;
  return edges;
}

/// Averages a [columns] wide, [rows] tall block starting at [fromColumn].
Color _averageColor(
  ByteData pixels,
  int width,
  int rows,
  int fromColumn,
  int columns,
) {
  var red = 0;
  var green = 0;
  var blue = 0;
  var counted = 0;
  for (var y = 0; y < rows; y++) {
    for (var x = fromColumn; x < fromColumn + columns; x++) {
      final offset = (y * width + x) * 4;
      if (offset + 3 >= pixels.lengthInBytes) {
        continue;
      }
      // A transparent pixel has no colour to contribute; counting it would
      // drag the average towards black on artwork with a cut-out edge.
      if (pixels.getUint8(offset + 3) < 128) {
        continue;
      }
      red += pixels.getUint8(offset);
      green += pixels.getUint8(offset + 1);
      blue += pixels.getUint8(offset + 2);
      counted++;
    }
  }
  if (counted == 0) {
    return Colors.transparent;
  }
  return Color.fromARGB(
    255,
    red ~/ counted,
    green ~/ counted,
    blue ~/ counted,
  );
}

/// Full-bleed banner pager that advances on its own, endlessly.
///
/// The caption always sits on a bottom gradient so it stays legible over any
/// artwork, and a brand placeholder takes over when an image fails to load.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.banners,
    required this.config,
    this.aspectRatio = bannerArtworkRatio,
    this.onTap,
    this.autoScroll = true,
    this.interval = const Duration(seconds: 5),
    this.topBleed = 0,
  });

  final List<BannerImage> banners;
  final BrandConfig config;

  /// Height of a strip drawn above the artwork, on the backdrop's wash.
  ///
  /// A screen that paints behind a curved header passes the depth of the curve
  /// here: the strip fills the corners, and the artwork below it keeps every
  /// pixel it was uploaded with.
  final double topBleed;

  /// Shape of the strip. The carousel sizes itself from the width it is given
  /// instead of a fixed height, so it holds on any screen. Defaults to
  /// [bannerArtworkRatio]; pass 16/9 once the CMS ships art in that shape.
  final double aspectRatio;
  final ValueChanged<BannerImage>? onTap;

  /// Advances to the next banner on a timer, wrapping past the last one.
  final bool autoScroll;
  final Duration interval;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  /// The pager runs over a virtually unbounded range and maps back onto the
  /// banner list, so advancing past the last one continues into the first
  /// without a visible jump backwards.
  static const _origin = 10000;

  late final PageController _controller;
  Timer? _timer;

  /// Proportion of the artwork itself, once it has been decoded.
  double? _measured;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  /// Banner the pager is showing, so the backdrop wears its colours.
  int _page = 0;
  BannerEdgeColors? _edges;

  /// Artwork the backdrop is washed from: whichever banner is on screen.
  String get _showing => widget.banners.isEmpty
      ? ''
      : widget.banners[_page % widget.banners.length].url;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _origin);
    _restartTimer();
    _measureArtwork();
    _readEdges();
  }

  /// Reads the edge colours of the banner on screen.
  Future<void> _readEdges() async {
    final url = _showing;
    if (url.isEmpty) {
      return;
    }
    final edges = await readBannerEdgeColors(url);
    if (!mounted || edges == null) {
      return;
    }
    setState(() => _edges = edges);
  }

  /// Reads the natural proportion of the first banner so the strip matches it.
  void _measureArtwork() {
    final url = widget.banners.isEmpty ? '' : widget.banners.first.url;
    if (url.isEmpty) {
      return;
    }
    _detachStream();
    final listener = ImageStreamListener((info, _) {
      final ratio = info.image.width / info.image.height;
      if (!mounted || ratio.isNaN || ratio <= 0) {
        return;
      }
      setState(() {
        _measured = ratio.clamp(_minBannerRatio, _maxBannerRatio);
      });
    }, onError: (_, __) {});
    _listener = listener;
    _stream = CachedNetworkImageProvider(url).resolve(ImageConfiguration.empty)
      ..addListener(listener);
  }

  void _detachStream() {
    final listener = _listener;
    if (listener != null) {
      _stream?.removeListener(listener);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void didUpdateWidget(BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoScroll != widget.autoScroll ||
        oldWidget.interval != widget.interval ||
        oldWidget.banners.length != widget.banners.length) {
      _restartTimer();
    }
    final first = widget.banners.isEmpty ? '' : widget.banners.first.url;
    final was = oldWidget.banners.isEmpty ? '' : oldWidget.banners.first.url;
    if (first != was) {
      _measureArtwork();
      _readEdges();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!widget.autoScroll || widget.banners.length < 2) {
      return;
    }
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Holds the timer while the customer is dragging, then resumes it.
  bool _onUserScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _timer?.cancel();
    } else if (notification is ScrollEndNotification) {
      _restartTimer();
    }
    return false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _detachStream();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }
    return _backdrop(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.topBleed > 0) SizedBox(height: widget.topBleed),
          _pager(context),
        ],
      ),
    );
  }

  /// Wash of the banner's own colours behind the whole strip.
  ///
  /// The artwork is fitted and never cropped, so two things around it have to
  /// be filled: the bars each side of a piece that does not match the pager's
  /// shape, and the bleed above it that reaches into the header's curve. They
  /// used to be filled by two different things — a brand gradient and a pair
  /// of sampled colours — which is why the corners showed a wedge wherever the
  /// two disagreed. One backdrop behind both cannot disagree with itself.
  ///
  /// It is the banner itself, covered and stretched from a thumbnail, so the
  /// corners read as a soft continuation of the piece rather than as a colour
  /// that happens to be near it. The edge colours stay as the ground under it,
  /// for the moment before the thumbnail is decoded and for artwork that never
  /// loads at all.
  Widget _backdrop(BuildContext context, {required Widget child}) {
    final edges = _edges;
    final url = _showing;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            edges?.left ?? context.brand.bg,
            edges?.right ?? context.brand.bg,
          ],
        ),
        image: url.isEmpty
            ? null
            : DecorationImage(
                image: ResizeImage(
                  CachedNetworkImageProvider(url),
                  width: _bannerBackdropWidth,
                  allowUpscaling: false,
                ),
                fit: BoxFit.cover,
                // Pinned to the top so the header's corners keep showing the
                // top of the piece. Covering a box taller than the artwork
                // otherwise crops towards the middle, and the corners would
                // start describing a part of the banner nowhere near them.
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.medium,
                // A wash that cannot be fetched leaves the edge colours
                // showing, which is what the strip looked like before it.
                onError: (_, __) {},
              ),
      ),
      child: child,
    );
  }

  Widget _pager(BuildContext context) {
    return ConstrainedBox(
      // The banner has to stay on screen next to the packages card and the tab
      // bar, so the artwork cannot be the one deciding how tall it gets. Taller
      // art is cropped from the centre rather than pushing the page around.
      constraints: BoxConstraints(maxHeight: maxBannerHeight(context)),
      child: AspectRatio(
        aspectRatio: _measured ?? widget.aspectRatio,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onUserScroll,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) {
              // The backdrop is washed from whichever banner is on screen, so
              // the page has to be state and not just a note to the sampler.
              setState(() => _page = index);
              _readEdges();
            },
            itemBuilder: (context, index) {
              final banner = widget.banners[index % widget.banners.length];
              return GestureDetector(
                onTap:
                    widget.onTap == null ? null : () => widget.onTap!(banner),
                child: _BannerArtwork(
                  url: banner.url,
                  caption: banner.descripcion,
                  config: widget.config,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BannerArtwork extends StatelessWidget {
  const _BannerArtwork({
    required this.url,
    required this.caption,
    required this.config,
  });

  final String url;

  /// Only drawn on the placeholder: when the brand artwork loads it already
  /// carries its own message, so overlaying the description would duplicate it.
  final String caption;
  final BrandConfig config;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    Widget placeholder() => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-1, -1),
              end: const Alignment(1, 1),
              colors: [tokens.primary, tokens.headerGradientEnd],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(BrandSpace.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (config.assets.logoWide.isNotEmpty)
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        config.assets.logoWide,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                if (caption.trim().isNotEmpty)
                  Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.head(22, color: tokens.onScrim),
                  ),
              ],
            ),
          ),
        );

    if (url.isEmpty) {
      return placeholder();
    }
    // Fitted, never cropped: whatever the upload measures, the whole piece is
    // visible. Nothing is drawn behind it, so the carousel's backdrop fills
    // whatever the fit leaves over and the piece sits on its own colours. The
    // placeholder is kept for artwork that is missing or refuses to load,
    // where there is no piece to sit on and its caption is the only message
    // left to show.
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (context, _) => const SizedBox.shrink(),
      errorWidget: (context, _, __) => placeholder(),
    );
  }
}

/// Distance to a branch, in the units that keep the number readable.
///
/// Under a kilometre the figure is worth more in metres: "0,4 km" reads as an
/// abstraction where "400 m" reads as a walk.
String formatBranchDistance(BuildContext context, double kilometres) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  if (kilometres < 1) {
    return '${NumberFormat('#,##0', locale).format(kilometres * 1000)} m';
  }
  return '${NumberFormat('#,##0.0', locale).format(kilometres)} km';
}

/// Sentence describing where a branch stands against the clock.
String branchStatusLabel(BuildContext context, BranchStatus status) {
  switch (status.state) {
    case BranchOpenState.open:
      return 'abierto_cierra_a_las'
          .tr(args: [_clock(context, status.closesAt!)]);
    case BranchOpenState.closingSoon:
      return 'cierra_en_minutos'.tr(args: ['${status.minutesToClose}']);
    case BranchOpenState.closed:
      final opensAt = status.opensAt;
      if (opensAt == null) {
        return 'cerrado_ahora'.tr();
      }
      final clock = _clock(context, opensAt);
      return switch (status.opensInDays) {
        0 => 'cerrado_abre_a_las'.tr(args: [clock]),
        1 => 'cerrado_abre_manana'.tr(args: [clock]),
        _ => 'cerrado_abre_el_dia'.tr(
            args: ['dia_${status.opensOnWeekday}'.tr(), clock],
          ),
      };
  }
}

/// Colour that carries the branch state, from the brand's own status ramp.
Color branchStatusColor(BrandTokens tokens, BranchOpenState state) =>
    switch (state) {
      BranchOpenState.open => tokens.success,
      BranchOpenState.closingSoon => tokens.warning,
      BranchOpenState.closed => tokens.textMuted,
    };

/// Renders a minute of the day the way the customer's own device would.
String _clock(BuildContext context, int minutes) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: minutes ~/ 60 % 24, minute: minutes % 60),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

/// Branch summary row: address, opening hours and phone, each with a glyph.
///
/// Distance is set as a badge rather than as another line of prose. The
/// customer's default branch keeps that badge filled as part of its highlight.
/// The branches, as one continuous list rather than a stack of cards.
///
/// A card per branch made every row announce itself as a separate object, which
/// is nine identical announcements on a screen whose job is comparison. One
/// surface with hairlines lets the eye run down the column and read the
/// distances against each other.
class BranchList extends StatelessWidget {
  const BranchList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final radius = BorderRadius.circular(tokens.radiusMd);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0)
                Divider(height: 1, thickness: 1, color: tokens.border),
              children[index],
            ],
          ],
        ),
      ),
    );
  }
}

/// One branch inside [BranchList]: address, opening state and phone.
///
/// The row carries two separate intents. Tapping the body is the cheap one — it
/// moves the map and nothing else — while the trailing control is the one that
/// opens the sheet. Splitting them is what lets a tap on the body mean "show me
/// where this is" without also burying the map under a panel.
class BranchRow extends StatelessWidget {
  const BranchRow({
    super.key,
    required this.branch,
    this.onTap,
    this.onMore,
    this.distanceKm,
    this.isFavorite = false,
    this.focused = false,
    this.at,
  });

  final Sucursal branch;

  /// Moves the map to this branch, or back out when it is already there.
  final VoidCallback? onTap;

  /// Opens the branch detail.
  final VoidCallback? onMore;

  /// Distance from the customer, when location is available.
  final double? distanceKm;

  /// Whether this is the customer's default branch.
  final bool isFavorite;

  /// Whether the map is currently held on this branch.
  final bool focused;

  /// Moment the opening state is read against. Injectable so a test can pin the
  /// clock instead of rendering whatever the day happens to be.
  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final distance = distanceKm;
    final status =
        BranchHours.parse(branch.horario)?.statusAt(at ?? DateTime.now());
    // The default branch outranks the focus tint: the account preference is a
    // lasting property, while being framed on the map is momentary.
    final background = isFavorite
        ? Color.alphaBlend(tokens.accentWash(tokens.primary), tokens.surface)
        : focused
            ? tokens.surfaceAlt
            : null;
    return Semantics(
      container: true,
      label: isFavorite
          ? '${branch.nombre}. ${'sucursal_predeterminada'.tr()}'
          : branch.nombre,
      // Read after the branch name, so the gesture announces what it does.
      // Tapping a row used to open a detail, which needed no explaining; now it
      // moves a map the reader may not be able to see.
      onTapHint: 'ver_en_mapa'.tr(),
      child: Material(
        color: background ?? tokens.surface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            // Asymmetric on purpose: the trailing control is pinned to the 44pt
            // touch minimum, and that height already supplies the breathing
            // room above the name that a symmetric inset would then double.
            padding: const EdgeInsets.fromLTRB(15, 3, 6, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        branch.nombre,
                        style: tokens.body(
                          14,
                          weight: FontWeight.w700,
                          color: tokens.primary,
                        ),
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(width: BrandSpace.xs),
                      _DistancePill(
                        label: formatBranchDistance(context, distance),
                        filled: isFavorite,
                      ),
                    ],
                    _MoreButton(onTap: onMore),
                  ],
                ),
                if (isFavorite) ...[
                  const SizedBox(height: 3),
                  Text(
                    // Plain text, not the brand accent: this sits on a wash of
                    // that same accent, and the preference is already carried
                    // by the tinted row and the filled badge.
                    'sucursal_predeterminada'.tr(),
                    style: tokens.body(11, weight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BranchLine(
                        glyph: BrandIcons.mapMarker,
                        value: branch.direccion,
                      ),
                      if (status != null)
                        _BranchLine(
                          glyph: BrandIcons.schedule,
                          value: branchStatusLabel(context, status),
                          weight: FontWeight.w600,
                          accent: branchStatusColor(tokens, status.state),
                        )
                      else
                        _BranchLine(
                          glyph: BrandIcons.schedule,
                          value: branch.horario,
                          muted: true,
                        ),
                      _BranchLine(
                        glyph: BrandIcons.phone,
                        value: branch.telefonoOficina,
                        muted: true,
                        weight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Trailing control that opens the branch detail.
///
/// Drawn as the system's own stacked dots rather than a chevron: a chevron
/// promises this row leads somewhere, and now it does not — tapping the row
/// moves the map. Dots promise actions, which is what the sheet holds.
class _MoreButton extends StatelessWidget {
  const _MoreButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Semantics(
      button: true,
      label: 'ver_detalle'.tr(),
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: BrandMoreGlyph(color: tokens.textMuted, size: 17),
          ),
        ),
      ),
    );
  }
}

/// Distance badge, filled when it belongs to the default branch.
class _DistancePill extends StatelessWidget {
  const _DistancePill({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    // Filled, `onPrimary` already carries the label: the config resolves it to
    // a legible foreground over the brand's own primary. Over the wash there is
    // no such guarantee, and the accent cannot carry its own tint — a pale
    // primary like cainca's #C2DEFF drops to 1.3:1 against it — so the label
    // falls back to plain text and the accent stays on the glyph.
    final foreground = filled ? tokens.onPrimary : tokens.text;
    final background =
        filled ? tokens.primary : tokens.accentWash(tokens.primary);
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(BrandShape.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandGlyph(
            BrandIcons.mapMarker,
            color: filled ? foreground : tokens.primary,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: tokens.body(11, weight: FontWeight.w700, color: foreground),
          ),
        ],
      ),
    );
  }
}

class _BranchLine extends StatelessWidget {
  const _BranchLine({
    required this.glyph,
    required this.value,
    this.muted = false,
    this.weight = FontWeight.w400,
    this.accent,
  });

  final String glyph;
  final String value;
  final bool muted;
  final FontWeight weight;

  /// Tints the glyph and the value together, for a line that carries a state.
  final Color? accent;

  /// Caps the row's height so the list stays comparable.
  ///
  /// Real records run long — one branch stores two counters with different
  /// hours across three lines — and letting a single row grow to twice its
  /// neighbours breaks the column the grouped list exists to create. The sheet
  /// behind the row's own control still prints the value whole.
  static const int _maxLines = 2;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: BrandGlyph(
              glyph,
              color: accent ?? tokens.textMuted,
              size: 14,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              value,
              maxLines: _maxLines,
              overflow: TextOverflow.ellipsis,
              style: tokens.body(
                12,
                weight: weight,
                color: accent ?? (muted ? tokens.textMuted : tokens.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Map pinned to the top of the branches screen.
///
/// [focused] drives the camera: selecting a branch in the list flies the map to
/// it instead of leaving the customer to find the pin themselves.
class BranchMap extends StatefulWidget {
  const BranchMap({
    super.key,
    required this.branches,
    this.onSelect,
    this.focused,
    this.here,
    this.showMyLocation = true,
  });

  final List<Sucursal> branches;
  final ValueChanged<Sucursal>? onSelect;
  final Sucursal? focused;

  /// Customer position, when it is known. Drives the control that brings the
  /// camera back to it after a branch has pulled it away.
  final ({double latitude, double longitude})? here;

  /// Whether the map may draw its own position layer.
  ///
  /// Deliberately not tied to [here]: the blue dot is the platform's, and it is
  /// useful from the moment the permission exists, well before this screen has
  /// resolved a fix precise enough to measure distances with.
  final bool showMyLocation;

  static const double heightFactor = 0.3;

  /// Zoom used when the whole network is in view, and when one branch is.
  static const double overviewZoom = 11;
  static const double focusedZoom = 15.5;

  @override
  State<BranchMap> createState() => _BranchMapState();
}

class _BranchMapState extends State<BranchMap> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(BranchMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focused = widget.focused;
    if (focused?.registroId == oldWidget.focused?.registroId) {
      return;
    }
    if (focused == null) {
      _pullBack();
    } else {
      _focus(focused);
    }
  }

  void _focus(Sucursal branch) {
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(branch.latitud, branch.longitud),
          zoom: BranchMap.focusedZoom,
        ),
      ),
    );
  }

  /// Returns to the framing the screen opened with, so a second tap on the
  /// branch already held undoes the first rather than doing nothing.
  void _pullBack() {
    if (widget.branches.isEmpty) {
      return;
    }
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(_overview(widget.branches.first)),
    );
  }

  static CameraPosition _overview(Sucursal branch) => CameraPosition(
        target: LatLng(branch.latitud, branch.longitud),
        zoom: BranchMap.overviewZoom,
      );

  void _recenter() {
    final here = widget.here;
    if (here == null) {
      return;
    }
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(here.latitude, here.longitude),
          zoom: BranchMap.overviewZoom + 1,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final height = MediaQuery.sizeOf(context).height * BranchMap.heightFactor;
    if (widget.branches.isEmpty) {
      return SizedBox(
        height: height,
        child: ColoredBox(
          color: tokens.surfaceAlt,
          child: Center(
            child: BrandGlyph(
              BrandIcons.branches,
              color: tokens.border,
              size: 52,
            ),
          ),
        ),
      );
    }
    final first = widget.focused ?? widget.branches.first;
    // Google's palette only exposes markers by hue, which is enough to take the
    // whole network out of its default red and into the brand's own colour.
    final hue = HSVColor.fromColor(tokens.primary).hue;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: widget.focused == null
                  ? _overview(first)
                  : CameraPosition(
                      target: LatLng(first.latitud, first.longitud),
                      zoom: BranchMap.focusedZoom,
                    ),
              onMapCreated: (controller) {
                _controller = controller;
                final focused = widget.focused;
                if (focused != null) {
                  _focus(focused);
                }
              },
              markers: widget.branches
                  .map(
                    (branch) => Marker(
                      markerId: MarkerId(branch.registroId),
                      position: LatLng(branch.latitud, branch.longitud),
                      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
                      zIndexInt: branch.registroId == widget.focused?.registroId
                          ? 2
                          : 1,
                      infoWindow: InfoWindow(title: branch.nombre),
                      onTap: () => widget.onSelect?.call(branch),
                    ),
                  )
                  .toSet(),
              myLocationEnabled: widget.showMyLocation,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          if (widget.here != null)
            Positioned(
              right: BrandSpace.sm,
              bottom: BrandSpace.sm,
              child: _MapControl(onTap: _recenter),
            ),
        ],
      ),
    );
  }
}

/// Disc control floating over the map.
class _MapControl extends StatelessWidget {
  const _MapControl({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Semantics(
      button: true,
      label: 'mi_ubicacion'.tr(),
      child: Material(
        color: tokens.surface,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.my_location, size: 19, color: tokens.primary),
          ),
        ),
      ),
    );
  }
}

/// Service summary that progressively reveals its description and action.
class ServiceCard extends StatefulWidget {
  const ServiceCard({
    super.key,
    required this.title,
    required this.description,
    this.glyph = BrandIcons.services,
    this.onOpenDetails,
    this.initiallyExpanded = false,
  });

  final String title;
  final String description;
  final String glyph;
  final VoidCallback? onOpenDetails;
  final bool initiallyExpanded;

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  late bool _open = widget.initiallyExpanded;

  bool get _hasDetails =>
      widget.description.trim().isNotEmpty || widget.onOpenDetails != null;

  @override
  void didUpdateWidget(ServiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _open = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 240);
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.description.trim().isNotEmpty)
          Text(
            widget.description,
            style: tokens.body(13, color: tokens.textMuted, height: 1.5),
          ),
        if (widget.onOpenDetails != null) ...[
          if (widget.description.trim().isNotEmpty)
            const SizedBox(height: BrandSpace.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              hint: 'abre_enlace_externo'.tr(),
              child: TextButton.icon(
                onPressed: widget.onOpenDetails,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text('ver_detalle'.tr()),
                style: TextButton.styleFrom(
                  foregroundColor: tokens.primary,
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: BrandSpace.xs,
                  ),
                  textStyle: tokens.body(13, weight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    return BrandCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      borderColor: _open ? tokens.primary : tokens.border,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: _hasDetails,
            expanded: _hasDetails ? _open : null,
            hint: _hasDetails
                ? (_open
                        ? 'ocultar_detalles_servicio'
                        : 'mostrar_detalles_servicio')
                    .tr()
                : null,
            child: InkWell(
              onTap: _hasDetails ? () => setState(() => _open = !_open) : null,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    BrandActionGlyph(asset: widget.glyph),
                    const SizedBox(width: BrandSpace.sm),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: tokens.body(14, weight: FontWeight.w700),
                      ),
                    ),
                    if (_hasDetails) ...[
                      const SizedBox(width: BrandSpace.xs),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: tokens.accentWash(tokens.primary),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 22,
                            color: tokens.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              alignment: Alignment.topCenter,
              duration: duration,
              curve: Curves.easeOutCubic,
              child: _open && _hasDetails
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        15 + BrandActionGlyph.boxSize + BrandSpace.sm,
                        0,
                        15,
                        12,
                      ),
                      child: body,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Question and answer that expands in place.
class FaqAccordion extends StatefulWidget {
  const FaqAccordion({
    super.key,
    required this.question,
    required this.answer,
    this.initiallyExpanded = false,
  });

  final String question;
  final String answer;
  final bool initiallyExpanded;

  @override
  State<FaqAccordion> createState() => _FaqAccordionState();
}

class _FaqAccordionState extends State<FaqAccordion> {
  late bool _open = widget.initiallyExpanded;

  @override
  void didUpdateWidget(FaqAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _open = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 220);
    return BrandCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      borderColor: _open ? tokens.primary : tokens.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            hint: (_open ? 'ocultar_respuesta' : 'mostrar_respuesta').tr(),
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: tokens.body(13, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: BrandSpace.xs),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tokens.accentWash(tokens.primary),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 22,
                          color: tokens.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              alignment: Alignment.topCenter,
              duration: duration,
              curve: Curves.easeOutCubic,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 59, 16),
                      child: Text(
                        widget.answer,
                        style: tokens.body(
                          13,
                          color: tokens.textMuted,
                          height: 1.5,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tag shared by a news title on the list and on its detail, so the headline
/// flies between the two instead of cutting.
String newsHeroTag(String registroId) => 'news-title-$registroId';

String formatNewsDate(BuildContext context, Noticia news) {
  if (!news.hasPublishedDate) {
    return '';
  }
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(news.fecha);
}

/// News summary card; the title carries the brand primary.
class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.news, this.onTap});

  final Noticia news;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final title = news.titulo.isEmpty ? 'noticias'.tr() : news.titulo;
    final preview = news.previewText;
    final date = formatNewsDate(context, news);
    return BrandCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _NewsDateStamp(news: news),
          const SizedBox(width: BrandSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: newsHeroTag(news.heroIdentity),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tokens.body(
                        14,
                        weight: FontWeight.w700,
                        color: tokens.primary,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: tokens.body(11, color: tokens.textMuted),
                  ),
                ],
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    preview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.body(13, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: BrandSpace.xs),
            const BrandChevron(),
          ],
        ],
      ),
    );
  }
}

class _NewsDateStamp extends StatelessWidget {
  const _NewsDateStamp({required this.news});

  final Noticia news;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    if (!news.hasPublishedDate) {
      return const BrandGlyphTile(
        asset: BrandIcons.news,
        size: 50,
        glyphSize: 24,
      );
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Container(
      width: 50,
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      decoration: BoxDecoration(
        color: tokens.accentWash(tokens.primary),
        borderRadius: BorderRadius.circular(BrandShape.glyphTile),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${news.fecha.day}',
              style: tokens.head(20, color: tokens.primary)),
          Text(
            DateFormat.MMM(locale).format(news.fecha).toUpperCase(),
            maxLines: 1,
            style: tokens.eyebrow(9, color: tokens.primary),
          ),
        ],
      ),
    );
  }
}

/// Message row; unread messages sit on `surfaceAlt`.
class MessageRow extends StatelessWidget {
  const MessageRow({super.key, required this.message, this.onTap});

  final Mensaje message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      onTap: onTap,
      color: message.read ? tokens.surface : tokens.surfaceAlt,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  message.titulo,
                  style: tokens.body(14, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: BrandSpace.xs),
              Text(
                DateFormat('dd-MMM-yyyy').format(message.fecha),
                style: tokens.body(11, color: tokens.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            message.contenido,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: tokens.body(13, color: tokens.textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}
