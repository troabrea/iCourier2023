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
    this.hasAssistantModule = false,
    this.assistantSettings = "",
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

  /// Whether this courier pays for the assistant module.
  ///
  /// Carried over the wire as `hasChatBotModule`. That pair of columns was cut
  /// for a menu-driven chatbot that never shipped, and the API cannot grow new
  /// ones right now, so the assistant took the empty seats rather than waiting
  /// for a backend release. The names here describe what the fields mean today;
  /// only the mapping remembers where they came from.
  ///
  /// Defaults to off, here and in [Empresa.empty], because a record that is
  /// stale, partial, or older than the module must not hand a paid feature out
  /// for free.
  bool hasAssistantModule;

  /// The assistant's own record, as the portal saved it.
  ///
  /// Carried over the wire as `chatBotSettings`. A few couriers still hold the
  /// abandoned chatbot's record in that column — `BotName`, `ChatTextOptions`
  /// and friends. It parses to no service settings at all, which reads exactly
  /// like a courier who never filled the form in, so it needs no migration.
  ///
  /// Kept as the raw string the backend sent, exactly like [options]: parsing
  /// belongs to [AssistantSettings], and a record this model could not read
  /// must still survive a round trip through [toJson].
  String assistantSettings;

  DateTime get encuestaActiveUntil {
    if (pushHubName.isEmpty) {
      return DateTime(2000, 1, 1);
    }
    return DateTime.tryParse(pushHubName) ?? DateTime(2000, 1, 1);
  }

  String get encuestaUrl {
    if (pushHubEndpoint.isEmpty || !pushHubEndpoint.contains('/encuesta/')) {
      return '';
    }
    return pushHubEndpoint;
  }

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
      facebook: json["facebook"] ?? "",
      instagram: json["instagram"] ?? "",
      urlServidor: json["urlServidor"],
      webServiceUrl: json["webServiceURL"],
      registerUrl: json["registerURL"],
      tokenId: json["tokenID"],
      calculadoraDesde: json["calculadoraDesde"] ?? "",
      calculadoraHasta: json["calculadoraHasta"] ?? "",
      calculadoraProducto: json["calculadoraProducto"] ?? "",
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
      options: json["options"] ?? "",
      hasAssistantModule: json["hasChatBotModule"] as bool? ??
          json["hasAssistantModule"] as bool? ??
          false,
      assistantSettings:
          json["chatBotSettings"] ?? json["assistantSettings"] ?? "");

  factory Empresa.empty() => Empresa(
      registroId: "",
      nombre: "",
      dominio: "",
      mision: "",
      vision: "",
      correoServicio: "",
      correoVentas: "",
      paginaWeb: "",
      telefonoOficina: "",
      telefonoVentas: "",
      twitter: "",
      facebook: "",
      instagram: "",
      urlServidor: "",
      webServiceUrl: "",
      registerUrl: "",
      tokenId: "",
      calculadoraDesde: "",
      calculadoraHasta: "",
      calculadoraProducto: "",
      hasPointsModule: false,
      hasAutobuses: false,
      hasPreguntas: false,
      hasPaymentsModule: false,
      hasNotifyModule: false,
      hasDelivery: false,
      minDistanceToNotify: 0,
      erp: 0,
      deleted: false,
      clientId: "",
      clientSecret: "",
      pushHubEndpoint: "",
      pushHubName: "",
      options: "",
      hasAssistantModule: false,
      assistantSettings: "");

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
        "options": options,
        "hasChatBotModule": hasAssistantModule,
        "chatBotSettings": assistantSettings
      };
}
