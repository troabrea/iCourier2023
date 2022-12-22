class CalculadoraRequest {
  CalculadoraRequest({
    required this.empresaId,
    required this.sessionId,
    required this.producto,
    required this.libras,
    required this.valorFob,
  });

  String empresaId;
  String sessionId;
  String producto;
  double libras;
  double valorFob;

  Map<String, dynamic> toJson() => {
    "empresaId": empresaId,
    "sessionId" : sessionId,
    "producto": producto,
    "libras": libras,
    "valorFob": valorFob
  };
}

class CalculadoraResponse {
  CalculadoraResponse({
    required this.companiaId,
    required this.oficinaId,
    required this.transaccionId,
    required this.transaccionDetalleId,
    required this.productoId,
    required this.productoNombre,
    required this.almacenId,
    required this.cantidad,
    required this.unidadId,
    required this.piezas,
    required this.precio,
    required this.bruto,
    required this.pctDesc,
    required this.descuento,
    required this.pctImp,
    required this.impuesto,
    required this.neto,
    required this.monedaId,
    required this.comentario,
  });

  String companiaId;
  String oficinaId;
  String transaccionId;
  String transaccionDetalleId;
  String productoId;
  String productoNombre;
  String almacenId;
  double cantidad;
  String unidadId;
  double piezas;
  double precio;
  double bruto;
  double pctDesc;
  double descuento;
  double pctImp;
  double impuesto;
  double neto;
  String monedaId;
  String comentario;

  factory CalculadoraResponse.fromJson(Map<String, dynamic> json) => CalculadoraResponse(
    companiaId: json["companiaID"] ?? '',
    oficinaId: json["oficinaID"] ?? '',
    transaccionId: json["transaccionID"] ?? '',
    transaccionDetalleId: json["transaccionDetalleID"] ?? '',
    productoId: json["productoID"] ?? '',
    productoNombre: json["productoNombre"] ?? '',
    almacenId: json["almacenID"] ?? '',
    cantidad: json["cantidad"].toDouble(),
    unidadId: json["unidadID"] ?? '',
    piezas: json["piezas"].toDouble(),
    precio: json["precio"].toDouble(),
    bruto: json["bruto"].toDouble(),
    pctDesc: json["pctDesc"].toDouble(),
    descuento: json["descuento"].toDouble(),
    pctImp: json["pctImp"].toDouble(),
    impuesto: json["impuesto"].toDouble(),
    neto: json["neto"].toDouble(),
    monedaId: json["monedaID"] ?? '',
    comentario: json["comentario"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "companiaID": companiaId,
    "oficinaID": oficinaId,
    "transaccionID": transaccionId,
    "transaccionDetalleID": transaccionDetalleId,
    "productoID": productoId,
    "productoNombre": productoNombre,
    "almacenID": almacenId,
    "cantidad": cantidad,
    "unidadID": unidadId,
    "piezas": piezas,
    "precio": precio,
    "bruto": bruto,
    "pctDesc": pctDesc,
    "descuento": descuento,
    "pctImp": pctImp,
    "impuesto": impuesto,
    "neto": neto,
    "monedaID": monedaId,
    "comentario": comentario,
  };
}
