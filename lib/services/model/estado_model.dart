class EstadoResponse {
  EstadoResponse({
    required this.documento,
    required this.fecha,
    required this.balance,
    required this.diasVencidos,
  });

  String documento;
  String fecha;
  double balance;
  int diasVencidos;

  String soloFecha() {
    if (!fecha.contains("12:00:00 AM")) {
      return fecha;
    }
    var result = fecha.replaceAll("12:00:00 AM", "");
    var parts = result.split("/");
    if(parts.length == 3) {
      result = parts[1] + '-' + parts[0] + '-' + parts[2];
    }
    return result;
  }


  factory EstadoResponse.fromJson(Map<String, dynamic> json) => EstadoResponse(
    documento: json["documento"],
    fecha: json["fecha"],
    balance: json["balance"],
    diasVencidos: json["diasVencidos"]
  );
}
