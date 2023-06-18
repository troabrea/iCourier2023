
class Puntos {
    double balance;
    String ultimaFecha;
    String urlCanjeo;

    Puntos({required this.balance, required this.ultimaFecha, required this.urlCanjeo});

    factory Puntos.empty() {
        return Puntos(balance: 0.00, ultimaFecha: "", urlCanjeo: "");
    }

    factory Puntos.fromJson(Map<String, dynamic> json) {
        return Puntos(
            balance: json['balance'],
            ultimaFecha: json['ultimaFecha'] ?? "",
            urlCanjeo: ""
        );
    }

    Map<String, dynamic> toJson() {
        final Map<String, dynamic> data = <String, dynamic>{};
        data['balance'] = balance;
        data['ultimaFecha'] = ultimaFecha;
        return data;
    }
}