final class Servicio {
  Servicio({
    required this.registroId,
    required this.empresa,
    required this.titulo,
    required this.resumen,
    Object? detailsUrl,
    @Deprecated('Use detailsUrl instead.') Object? url,
    required this.orden,
    required this.deleted,
  }) : detailsUrl = _firstText([detailsUrl, url]);

  final String registroId;
  final String empresa;
  final String titulo;
  final String resumen;
  final String detailsUrl;
  final double orden;
  final bool deleted;

  @Deprecated('Use detailsUrl instead.')
  String get url => detailsUrl;

  /// Valid external destination supplied by the services CMS.
  Uri? get externalDetailsUri {
    final uri = Uri.tryParse(detailsUrl);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    return uri;
  }

  factory Servicio.fromJson(Map<String, dynamic> json) => Servicio(
        registroId: _text(json['registroID']),
        empresa: _text(json['empresa']),
        titulo: _text(json['titulo']),
        resumen: _text(json['resumen']),
        detailsUrl: _firstText([
          json['details_url'],
          json['detailsUrl'],
          json['url'],
        ]),
        orden: (json['orden'] as num?)?.toDouble() ?? 0,
        deleted: _boolean(json['deleted']),
      );

  Map<String, dynamic> toJson() => {
        'registroID': registroId,
        'empresa': empresa,
        'titulo': titulo,
        'resumen': resumen,
        'details_url': detailsUrl,
        // Kept while older consumers still read the pre-CMS field name.
        'url': detailsUrl,
        'orden': orden,
        'deleted': deleted,
      };
}

String _text(Object? value) => value?.toString().trim() ?? '';

String _firstText(Iterable<Object?> values) {
  for (final value in values) {
    final text = _text(value);
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

bool _boolean(Object? value) =>
    value == true || value?.toString().toLowerCase() == 'true';
