class Mensaje {
  Mensaje({
    required this.registroId,
    required this.empresa,
    required this.fecha,
    required this.titulo,
    required this.contenido,
    required this.deleted,
    required this.read,
  });

  String registroId;
  String empresa;
  DateTime fecha;
  String titulo;
  String contenido;
  bool deleted;
  bool read;

  factory Mensaje.fromJson(Map<String, dynamic> json) => Mensaje(
        registroId: json["registroID"],
        empresa: json["empresa"],
        fecha: DateTime.parse(json["createdAt"]),
        titulo: json["titulo"],
        contenido: json["contenido"] ?? "",
        deleted: json["deleted"],
        read: false,
      );

  Map<String, dynamic> toJson() => {
        "registroID": registroId,
        "empresa": empresa,
        "fecha": fecha.toIso8601String(),
        "titulo": titulo,
        "contenido": contenido,
        "deleted": deleted,
      };
}
