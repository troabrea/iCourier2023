class Servicio {
  Servicio({
    required this.registroId,
    required this.empresa,
    required this.titulo,
    required this.resumen,
    required this.url,
    required this.orden,
    required this.deleted,
  });

  String registroId;
  String empresa;
  String titulo;
  String resumen;
  dynamic url;
  double orden;
  bool deleted;

  bool isExpanded = false;

  factory Servicio.fromJson(Map<String, dynamic> json) => Servicio(
        registroId: json["registroID"],
        empresa: json["empresa"],
        titulo: json["titulo"],
        resumen: json["resumen"],
        url: json["url"],
        orden: json["orden"].toDouble(),
        deleted: json["deleted"],
      );

  Map<String, dynamic> toJson() => {
        "registroID": registroId,
        "empresa": empresa,
        "titulo": titulo,
        "resumen": resumen,
        "url": url,
        "orden": orden,
        "deleted": deleted,
      };
}
