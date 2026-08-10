import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../services/model/banner.dart';
import '../services/model/mensaje.dart';
import '../services/model/noticia.dart';
import '../services/model/sucursal.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.banners,
    required this.config,
  });

  final List<BannerImage> banners;
  final BrandConfig config;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.banners.length,
        itemBuilder: (context, index) {
          final banner = widget.banners[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: banner.url,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => DecoratedBox(
                      decoration: BoxDecoration(color: tokens.surfaceAlt),
                      child: Image.asset(widget.config.assets.logoWide),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          tokens.sheetBackdrop.withValues(alpha: 0),
                          tokens.text.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        banner.descripcion,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: tokens.surface),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class BranchCard extends StatelessWidget {
  const BranchCard({
    super.key,
    required this.branch,
    this.onTap,
    this.onCall,
    this.onWhatsApp,
    this.onDirections,
  });

  final Sucursal branch;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(branch.nombre,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(branch.direccion),
              if (branch.horario.isNotEmpty) Text(branch.horario),
              if (branch.telefonoOficina.isNotEmpty)
                Text(branch.telefonoOficina),
              const SizedBox(height: 8),
              Wrap(
                children: [
                  IconButton(
                      onPressed: onCall, icon: const Icon(Icons.call_outlined)),
                  IconButton(
                    onPressed: onWhatsApp,
                    icon: const Icon(Icons.chat_bubble_outline),
                  ),
                  IconButton(
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BranchMap extends StatelessWidget {
  const BranchMap({super.key, required this.branches, this.onSelect});

  final List<Sucursal> branches;
  final ValueChanged<Sucursal>? onSelect;

  @override
  Widget build(BuildContext context) {
    if (branches.isEmpty) {
      return const SizedBox.shrink();
    }
    final first = branches.first;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.brand.radiusLg),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(first.latitud, first.longitud),
            zoom: 11,
          ),
          markers: branches
              .map(
                (branch) => Marker(
                  markerId: MarkerId(branch.registroId),
                  position: LatLng(branch.latitud, branch.longitud),
                  infoWindow: InfoWindow(title: branch.nombre),
                  onTap: () => onSelect?.call(branch),
                ),
              )
              .toSet(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.title,
    required this.description,
    this.imageUrl,
    this.onTap,
  });

  final String title;
  final String description;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      title: title,
      description: description,
      imageUrl: imageUrl,
      onTap: onTap,
    );
  }
}

class FaqAccordion extends StatelessWidget {
  const FaqAccordion({
    super.key,
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(title: Text(question), children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(answer)),
      ]),
    );
  }
}

class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.news, this.onTap});

  final Noticia news;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      title: news.titulo,
      description: news.resumen,
      onTap: onTap,
      footer: DateFormat.yMMMd().format(news.fecha),
    );
  }
}

class MessageRow extends StatelessWidget {
  const MessageRow({super.key, required this.message, this.onTap});

  final Mensaje message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Material(
      color: message.read ? tokens.surfaceAlt : tokens.surface,
      child: ListTile(
        onTap: onTap,
        title: Text(
          message.titulo,
          style: message.read
              ? null
              : const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(message.contenido, maxLines: 2),
        trailing: Text(DateFormat.MMMd().format(message.fecha)),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.title,
    required this.description,
    this.imageUrl,
    this.footer,
    this.onTap,
  });

  final String title;
  final String description;
  final String? imageUrl;
  final String? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl?.isNotEmpty ?? false)
              AspectRatio(
                aspectRatio: 16 / 9,
                child:
                    CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(description),
                  if (footer != null) ...[
                    const SizedBox(height: 8),
                    Text(footer!,
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
