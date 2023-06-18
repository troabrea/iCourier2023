class Empresa {
  Empresa({
    required this.registroId,
    required this.nombre,
    required this.dominio,
    required this.mision,
    required this.vision,
    required this.correoServicio,
    required this.correoVentas,
    required this.paginaWeb,
    required this.telefonoOficina,
    required this.telefonoVentas,
    required this.twitter,
    required this.facebook,
    required this.instagram,
    required this.urlServidor,
    required this.webServiceUrl,
    required this.registerUrl,
    required this.tokenId,
    required this.calculadoraDesde,
    required this.calculadoraHasta,
    required this.calculadoraProducto,
    required this.hasPointsModule,
    required this.hasAutobuses,
    required this.hasPreguntas,
    required this.hasPaymentsModule,
    required this.hasNotifyModule,
    required this.hasDelivery,
    required this.minDistanceToNotify,
    required this.erp,
    required this.deleted,
    required this.clientId,
    required this.clientSecret,
    required this.pushHubEndpoint,
    required this.pushHubName,
    required this.options,
  });

  String registroId;
  String nombre;
  String dominio;
  String mision;
  String vision;
  String correoServicio;
  String correoVentas;
  String paginaWeb;
  String telefonoOficina;
  String telefonoVentas;
  String twitter;
  String facebook;
  String instagram;
  String urlServidor;
  String webServiceUrl;
  String registerUrl;
  String tokenId;
  String calculadoraDesde;
  String calculadoraHasta;
  String calculadoraProducto;
  bool hasPointsModule;
  bool hasAutobuses;
  bool hasPreguntas;
  bool hasPaymentsModule;
  bool hasNotifyModule;
  bool hasDelivery;
  int minDistanceToNotify;
  int erp;
  bool deleted;
  String clientId;
  String clientSecret;
  String pushHubEndpoint;
  String pushHubName;
  String options;

  factory Empresa.fromJson(Map<String, dynamic> json) => Empresa(
    registroId: json["registroID"],
    nombre: json["nombre"],
    dominio: json["dominio"],
    mision: json["mision"] ?? "",
    vision: json["vision"] ?? "",
    correoServicio: json["correoServicio"] ?? "",
    correoVentas: json["correoVentas"] ?? "",
    paginaWeb: json["paginaWeb"] ?? "",
    telefonoOficina: json["telefonoOficina"] ?? "",
    telefonoVentas: json["telefonoVentas"] ?? "",
    twitter: json["twitter"] ?? "",
    facebook: json["facebook"]?? "",
    instagram: json["instagram"]?? "",
    urlServidor: json["urlServidor"],
    webServiceUrl: json["webServiceURL"],
    registerUrl: json["registerURL"],
    tokenId: json["tokenID"],
    calculadoraDesde: json["calculadoraDesde"],
    calculadoraHasta: json["calculadoraHasta"],
    calculadoraProducto: json["calculadoraProducto"],
    hasPointsModule: json["hasPointsModule"],
    hasAutobuses: json["hasAutobuses"],
    hasPreguntas: json["hasPreguntas"],
    hasPaymentsModule: json["hasPaymentsModule"],
    hasNotifyModule: json["hasNotifyModule"],
    hasDelivery: json["hasDelivery"],
    minDistanceToNotify: json["minDistanceToNotify"],
    erp: json["erp"],
    deleted: json["deleted"],
    clientId: json["clientId"] ?? "",
    clientSecret: json["clientSecret"] ?? "",
    pushHubEndpoint: json["pushHubEndpoint"] ?? "",
    pushHubName: json["pushHubName"] ?? "",
    options: json["options"] ?? ""
  );

  Map<String, dynamic> toJson() => {
    "registroID": registroId,
    "nombre": nombre,
    "dominio": dominio,
    "mision": mision,
    "vision": vision,
    "correoServicio": correoServicio,
    "correoVentas": correoVentas,
    "paginaWeb": paginaWeb,
    "telefonoOficina": telefonoOficina,
    "telefonoVentas": telefonoVentas,
    "twitter": twitter,
    "facebook": facebook,
    "instagram": instagram,
    "urlServidor": urlServidor,
    "webServiceURL": webServiceUrl,
    "registerURL": registerUrl,
    "tokenID": tokenId,
    "calculadoraDesde": calculadoraDesde,
    "calculadoraHasta": calculadoraHasta,
    "calculadoraProducto": calculadoraProducto,
    "hasPointsModule": hasPointsModule,
    "hasAutobuses": hasAutobuses,
    "hasPreguntas": hasPreguntas,
    "hasPaymentsModule": hasPaymentsModule,
    "hasNotifyModule": hasNotifyModule,
    "hasDelivery": hasDelivery,
    "minDistanceToNotify": minDistanceToNotify,
    "erp": erp,
    "deleted": deleted,
    "clientId": clientId,
    "clientSecret": clientSecret,
    "pushHubEndpoint": pushHubEndpoint,
    "pushHubName": pushHubName,
    "options" : options
  };
}
