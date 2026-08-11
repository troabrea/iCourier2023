import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/model/banner.dart';
import '../services/model/mensaje.dart';
import '../services/model/noticia.dart';
import '../services/model/sucursal.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
import 'brand_foundations.dart';

/// Full-bleed banner pager that advances on its own, endlessly.
///
/// The caption always sits on a bottom gradient so it stays legible over any
/// artwork, and a brand placeholder takes over when an image fails to load.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.banners,
    required this.config,
    this.height = 230,
    this.onTap,
    this.autoScroll = true,
    this.interval = const Duration(seconds: 5),
  });

  final List<BannerImage> banners;
  final BrandConfig config;
  final double height;
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
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _origin);
    _restartTimer();
  }

  @override
  void didUpdateWidget(BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoScroll != widget.autoScroll ||
        oldWidget.interval != widget.interval ||
        oldWidget.banners.length != widget.banners.length) {
      _restartTimer();
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onUserScroll,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (page) => setState(
                () => _page = page % widget.banners.length,
              ),
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
          if (widget.banners.length > 1)
            Positioned(
              bottom: BrandSpace.sm,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BrandSpace.xs,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.scrimBottom,
                    borderRadius: BorderRadius.circular(BrandShape.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0;
                          index < widget.banners.length;
                          index++)
                        Container(
                          width: index == _page ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: tokens.onScrim.withValues(
                              alpha: index == _page ? 0.95 : 0.45,
                            ),
                            borderRadius:
                                BorderRadius.circular(BrandShape.pill),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) => ColoredBox(color: tokens.surfaceAlt),
      errorWidget: (context, _, __) => placeholder(),
    );
  }
}

/// Branch summary row: address, opening hours and phone, each with a glyph.
class BranchCard extends StatelessWidget {
  const BranchCard({
    super.key,
    required this.branch,
    this.onTap,
    this.distance,
  });

  final Sucursal branch;
  final VoidCallback? onTap;

  /// Optional distance from the customer, when location is available.
  final String? distance;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
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
                Text(
                  distance!,
                  style: tokens.body(11, color: tokens.textMuted),
                ),
              ],
              const SizedBox(width: BrandSpace.xs),
              const BrandChevron(),
            ],
          ),
          const SizedBox(height: 9),
          _BranchLine(glyph: BrandIcons.mapMarker, value: branch.direccion),
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
    );
  }
}

class _BranchLine extends StatelessWidget {
  const _BranchLine({
    required this.glyph,
    required this.value,
    this.muted = false,
    this.weight = FontWeight.w400,
  });

  final String glyph;
  final String value;
  final bool muted;
  final FontWeight weight;

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
            child: BrandGlyph(glyph, color: tokens.textMuted, size: 14),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              value,
              style: tokens.body(
                12,
                weight: weight,
                color: muted ? tokens.textMuted : tokens.text,
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
  });

  final List<Sucursal> branches;
  final ValueChanged<Sucursal>? onSelect;
  final Sucursal? focused;

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
    if (focused != null && focused.registroId != oldWidget.focused?.registroId) {
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
        child: ColoredBox(color: tokens.surfaceAlt),
      );
    }
    final first = widget.focused ?? widget.branches.first;
    return SizedBox(
      height: height,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(first.latitud, first.longitud),
          zoom: widget.focused == null
              ? BranchMap.overviewZoom
              : BranchMap.focusedZoom,
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
                infoWindow: InfoWindow(title: branch.nombre),
                onTap: () => widget.onSelect?.call(branch),
              ),
            )
            .toSet(),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }
}

/// Service row with its glyph on a wash of the brand primary.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.title,
    required this.description,
    this.glyph = BrandIcons.services,
    this.imageUrl,
    this.onTap,
  });

  final String title;
  final String description;
  final String glyph;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandGlyphTile(asset: glyph, glyphSize: 20),
          const SizedBox(width: BrandSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tokens.body(14, weight: FontWeight.w700)),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: tokens.body(12, color: tokens.textMuted),
                  ),
                ],
              ],
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
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
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
                    Text(
                      _open ? '–' : '+',
                      style: tokens.body(
                        16,
                        weight: FontWeight.w700,
                        color: tokens.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 14),
              child: Text(
                widget.answer,
                style: tokens.body(13, color: tokens.textMuted, height: 1.5),
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

/// News summary card; the title carries the brand primary.
class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.news, this.onTap});

  final Noticia news;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: newsHeroTag(news.registroId),
            child: Material(
              type: MaterialType.transparency,
              child: Text(
                news.titulo,
                style: tokens.body(
                  14,
                  weight: FontWeight.w700,
                  color: tokens.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            DateFormat('dd-MMM-yyyy').format(news.fecha),
            style: tokens.body(11, color: tokens.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            news.resumen,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: tokens.body(13, height: 1.45),
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
