class Noticia {
  static final unknownPublishedAt = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  Noticia({
    required this.registroId,
    required this.empresa,
    required this.fecha,
    required this.titulo,
    required this.resumen,
    required this.contenido,
    required this.url,
    required this.deleted,
  });

  final String registroId;
  final String empresa;
  final DateTime fecha;
  final String titulo;
  final String resumen;
  final String contenido;
  final String url;
  final bool deleted;

  /// A stable-enough identity for Hero transitions even when a legacy CMS row
  /// arrives without its record id. The same object is passed to the detail
  /// route, so the fallback remains identical across both screens.
  String get heroIdentity =>
      registroId.isNotEmpty ? registroId : 'local-${identityHashCode(this)}';

  bool get hasPublishedDate => fecha != unknownPublishedAt;

  /// Article text without the small HTML subset emitted by the legacy CMS.
  String get plainContent => _plainText(contenido);

  String get summaryText => _plainText(resumen);

  /// A card still gets a useful excerpt when editors supplied body copy but
  /// left the dedicated summary field empty.
  String get previewText {
    final summary = summaryText;
    return summary.isNotEmpty ? summary : plainContent;
  }

  Uri? get externalUri {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    return uri;
  }

  factory Noticia.fromJson(Map<String, dynamic> json) {
    final rawDate = _text(json['fecha']);
    return Noticia(
      registroId: _text(json['registroID']),
      empresa: _text(json['empresa']),
      fecha: DateTime.tryParse(rawDate) ?? unknownPublishedAt,
      titulo: _text(json['titulo']),
      resumen: _text(json['resumen']),
      contenido: _text(json['contenido']),
      url: _text(json['url']),
      deleted: _boolean(json['deleted']),
    );
  }

  Map<String, dynamic> toJson() => {
        "registroID": registroId,
        "empresa": empresa,
        "fecha": fecha.toIso8601String(),
        "titulo": titulo,
        "resumen": resumen,
        "contenido": contenido,
        "url": url,
        "deleted": deleted,
      };
}

String _text(Object? value) => value?.toString().trim() ?? '';

bool _boolean(Object? value) =>
    value == true || value?.toString().toLowerCase() == 'true';

String _plainText(String value) => value
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll(RegExp(r'[ \t]+'), ' ')
    .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
    .trim();
