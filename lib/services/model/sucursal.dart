class Sucursal {
  Sucursal({
    required this.registroId,
    required this.empresa,
    required this.nombre,
    required this.codigo,
    required this.direccion,
    required this.ciudad,
    required this.pais,
    required this.horario,
    required this.telefonoOficina,
    required this.telefonoVentas,
    required this.email,
    required this.imagenId,
    required this.latitud,
    required this.longitud,
    required this.orden,
    required this.deleted,
  });

  String registroId;
  String empresa;
  String nombre;
  String codigo;
  String direccion;
  String ciudad;
  String pais;
  String horario;
  String telefonoOficina;
  String telefonoVentas;
  String email;
  String imagenId;
  double latitud;
  double longitud;
  double orden;
  bool deleted;
  bool isFavorite = false;

  int get buzonSortOrder => int.tryParse(imagenId) != null ? int.parse(imagenId) : 0;

  factory Sucursal.fromJson(Map<String, dynamic> json) => Sucursal(
        registroId: json["registroID"],
        empresa: json["empresa"],
        nombre: json["nombre"],
        codigo: json["codigo"] ?? "",
        direccion: json["direccion"] ?? "",
        ciudad: json["ciudad"] ?? "",
        pais: json["pais"] ?? "",
        horario: json["horario"] ?? "",
        telefonoOficina: json["telefonoOficina"] ?? "",
        telefonoVentas: json["telefonoVentas"] ?? "",
        email: json["email"] ?? "",
        imagenId: json["imagenId"] ?? "",
        latitud: json["latitud"].toDouble(),
        longitud: json["longitud"].toDouble(),
        orden: json["orden"],
        deleted: json["deleted"],
      );

  Map<String, dynamic> toJson() => {
        "registroID": registroId,
        "empresa": empresa,
        "nombre": nombre,
        "codigo": codigo,
        "direccion": direccion,
        "ciudad": ciudad,
        "pais": pais,
        "horario": horario,
        "telefonoOficina": telefonoOficina,
        "telefonoVentas": telefonoVentas,
        "email": email,
        "imagenId": imagenId,
        "latitud": latitud,
        "longitud": longitud,
        "orden": orden,
        "deleted": deleted,
      };
}
