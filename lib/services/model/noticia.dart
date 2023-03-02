class Noticia {
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

  String registroId;
  String empresa;
  DateTime fecha;
  String titulo;
  String resumen;
  String contenido;
  String url;
  bool deleted;

  factory Noticia.fromJson(Map<String, dynamic> json) => Noticia(
        registroId: json["registroID"],
        empresa: json["empresa"],
        fecha: DateTime.parse(json["fecha"]),
        titulo: json["titulo"],
        resumen: json["resumen"],
        contenido: json["contenido"] ?? "",
        url: json["url"] ?? "",
        deleted: json["deleted"],
      );

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
