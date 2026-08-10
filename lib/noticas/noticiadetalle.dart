import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/core_components.dart';
import '../services/model/noticia.dart';

class NoticiaDetallePage extends StatelessWidget {
  const NoticiaDetallePage({super.key, required this.noticia});

  final Noticia noticia;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenHeader(title: noticia.titulo),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              DateFormat.yMMMMd().format(noticia.fecha),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 12),
            Text(noticia.resumen,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SelectableText(
              noticia.contenido.replaceAll(RegExp(r'<[^>]*>'), ' '),
            ),
            if (noticia.url.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  final uri = Uri.tryParse(noticia.url);
                  if (uri != null &&
                      (uri.scheme == 'https' || uri.scheme == 'http')) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: Text(noticia.url),
              ),
          ],
        ),
      ),
    );
  }
}
