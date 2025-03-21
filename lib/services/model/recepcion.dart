import 'package:intl/intl.dart';

class ConsultaHistoricaRequest
{
  ConsultaHistoricaRequest({
    required this.empresaId,
    required this.sessionId,
    required this.desde,
    required this.hasta
  });
  String empresaId;
  String sessionId;
  String desde;
  String hasta;

  Map<String, dynamic> toJson() => {
    "empresaId": empresaId,
    "sessionId" : sessionId,
    "desde" : desde,
    "hasta" : hasta
  };
}


class RecepcionRequest
{
  RecepcionRequest({
    required this.empresaId,
    required this.sessionId
  });
  String empresaId;
  String sessionId;

  Map<String, dynamic> toJson() => {
    "empresaId": empresaId,
    "sessionId" : sessionId
  };
}

class Recepcion {
  late String recepcionID;
  late String fecha;
  late String producto;
  late String suplidor;
  late int cantidadPaquetes;
  late String contenido;
  late String enviadoPor;
  late String totalPeso;
  late String totalVolumen;
  late String totalNeto;
  late String estatus;
  late bool retenido;
  late bool disponible;
  late List<Paquetes> paquetes;
  late String fotoPaqueteSmallUrl;
  late String fotoPaqueteUrl;
  late String fotoFacturaUrl;
  late String fechaHora;
  late int progreso;
  late String numeroRastreo;
  bool selected = false;

  int progresoActual() {
    if(estatus.toUpperCase() == "ENTREGADO AL CLIENTE" || estatus.toUpperCase() == "DELIVERED") {
      return 4;
    }
    if(estatus.toUpperCase() == "ENTREGADO" || estatus.toUpperCase() == "BILLED COUNTER") {
      return 4;
    }
    if(disponible && progreso == 4) {
      return 5;
    }
    if(disponible) {
      return 4;
    } else if(estatus.toUpperCase().contains("EMBARCADO") || estatus.toUpperCase().contains("EMPACADO") ||
        estatus.toUpperCase().contains("EMBARCADO") || estatus.toUpperCase().contains("EMPACADO") ||
        estatus.toUpperCase().contains("SHIPMENT SENT")
    ) {
      return 2;
    } else if(estatus.toUpperCase().contains("TRANSFERIDO") || estatus.toUpperCase().contains("EMPACADO")
         || estatus.toUpperCase().contains("TRANSFERIDO") || estatus.toUpperCase().contains("EMPACADO")
         || estatus.toUpperCase().contains("ADUANA") || estatus.toUpperCase().contains("TRANSITO")
         || estatus.toUpperCase().contains("DISTRIBUCION") || estatus.toUpperCase().contains("DISTRIBUCIÓN")
         || estatus.toUpperCase().contains("RECIBIDO AILA") || estatus.toUpperCase().contains("ALMACEN")
         || estatus.toUpperCase().contains("CUSTOM") || estatus.toUpperCase().contains("(DISTRIBUTION CENTER)")
        || estatus.toUpperCase().contains("PACKED") || estatus.toUpperCase().contains("OUTGOING TRANSFER")
    ) {
      return 3;
    }
    return 1;
  }

  double montoTotal() => double.tryParse(totalNeto.replaceAll(',', '')) ?? 0.00;

  DateTime fechaRecibido() => DateTime.tryParse(fecha.replaceAll(".", "-").replaceAll("/", "-")) ?? DateTime(2000,1,1);

  Recepcion(
      { required this.recepcionID,
        required this.fecha,
        required this.producto,
        required this.suplidor,
        required this.cantidadPaquetes,
        required this.contenido,
        required this.enviadoPor,
        required this.totalPeso,
        required this.totalVolumen,
        required this.totalNeto,
        required this.estatus,
        required this.retenido,
        required this.disponible,
        required this.paquetes,
        required this.fotoPaqueteSmallUrl,
        required this.fotoPaqueteUrl,
        required this.fotoFacturaUrl,
        required this.fechaHora,
        required this.progreso,
        required this.numeroRastreo});

  Recepcion.fromJson(Map<String, dynamic> json) {
    print("${json['recepcionID']} - ${json["totalNeto"]}");
    recepcionID = json['recepcionID'] ?? "";
    fecha = json['fecha'] ?? "";
    producto = json['producto'] ?? "";
    suplidor = json['suplidor'] ?? "";
    cantidadPaquetes = json['cantidadPaquetes'] ?? 0;
    contenido = json['contenido']  ?? "";
    enviadoPor = json['enviadoPor']  ?? "";
    totalPeso = json['totalPeso'] ?? "";
    totalVolumen = json['totalVolumen']  ?? "" ;
    totalNeto = json['totalNeto']  ?? "";
    estatus = json['estatus']  ?? "";
    retenido = json['retenido'] ?? false;
    disponible = json['disponible'] ?? false;
    if (json['paquetes'] != null) {
      paquetes = <Paquetes>[];
      json['paquetes'].forEach((v) {
        paquetes.add(Paquetes.fromJson(v));
      });
    }
    fotoPaqueteSmallUrl = json['fotoPaqueteSmallUrl']  ?? "";
    fotoPaqueteUrl = json['fotoPaqueteUrl']  ?? "";
    fotoFacturaUrl = json['fotoFacturaUrl']  ?? "";
    fechaHora = json['fechaHora']  ?? "";
    progreso = json['progreso']  ?? 0;
    numeroRastreo = json['numeroRastreo']  ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['recepcionID'] = recepcionID;
    data['fecha'] = fecha;
    data['producto'] = producto;
    data['suplidor'] = suplidor;
    data['cantidadPaquetes'] = cantidadPaquetes;
    data['contenido'] = contenido;
    data['enviadoPor'] = enviadoPor;
    data['totalPeso'] = totalPeso;
    data['totalVolumen'] = totalVolumen;
    data['totalNeto'] = totalNeto;
    data['estatus'] = estatus;
    data['retenido'] = retenido;
    data['disponible'] = disponible;
    if (paquetes.isNotEmpty) {
      data['paquetes'] = paquetes.map((v) => v.toJson()).toList();
    }
    data['fotoPaqueteSmallUrl'] = fotoPaqueteSmallUrl;
    data['fotoPaqueteUrl'] = fotoPaqueteUrl;
    data['fotoFacturaUrl'] = fotoFacturaUrl;
    data['fechaHora'] = fechaHora;
    data['progreso'] = progreso;
    data['numeroRastreo'] = numeroRastreo;
    return data;
  }
}

class Paquetes {
  late String paqueteID;
  late String recepcionID;
  late String suplidor;
  late String libras;
  late String mercancia;
  late String rastreo;
  late String status;
  late String urlTracking;
  late List<Historia> historia;

  Paquetes(
      { required this.paqueteID,
        required this.recepcionID,
        required this.suplidor,
        required this.libras,
        required this.mercancia,
        required this.rastreo,
        required this.status,
        required this.urlTracking,
        required this.historia});

  Paquetes.fromJson(Map<String, dynamic> json) {
    paqueteID = json['paqueteID'] ?? "";
    recepcionID = json['recepcionID'] ?? "";
    suplidor = json['suplidor'] ?? "";
    libras = json['libras'] ?? "";
    mercancia = json['mercancia'] ?? "";
    rastreo = json['rastreo'] ?? "";
    status = json['status'] ?? "";
    urlTracking = json['urlTracking'] ?? "";
    if (json['historia'] != null) {
      historia = <Historia>[];
      json['historia'].forEach((v) {
        historia.add(Historia.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['paqueteID'] = paqueteID;
    data['recepcionID'] = recepcionID;
    data['suplidor'] = suplidor;
    data['libras'] = libras;
    data['mercancia'] = mercancia;
    data['rastreo'] = rastreo;
    data['status'] = status;
    data['urlTracking'] = urlTracking;
    if (historia.isNotEmpty) {
      data['historia'] = historia.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Historia {
  late String paqueteID;
  late String nombreEstatus;
  late String fecha;
  late String ciudad;
  late String fechaHora;

  String soloFecha() => fecha.split("|").first.trimLeft().trimRight().replaceAll(".", "-");
  String soloHora() => fecha.split("|").last.trimLeft().trimRight();


  DateTime dateTime()
  {
    var horaPart = soloHora().replaceAll(" AM","").replaceAll(" PM", "");
    if(horaPart.length == 5) {
      horaPart = horaPart + ":00";
    }
    // 2022-12-16T18:59:51.58
    var theDateTime = fechaHora.contains("T") ? DateFormat("yyyy-MM-ddTHH:mm:ss").parse(fechaHora) : DateFormat("yyyy-MM-dd HH:mm:ss").parse( soloFecha() + " " + horaPart );
    if(!fechaHora.contains("T")) {
      if (soloHora().contains("PM") && theDateTime.hour != 12) {
        theDateTime = theDateTime.add(const Duration(hours: 12));
      }
      if (soloHora().contains("AM") && theDateTime.hour == 12) {
        theDateTime = theDateTime.subtract(const Duration(hours: 12));
      }
    }
    return theDateTime;
  }


  Historia(
      { required this.paqueteID,
        required this.nombreEstatus,
        required this.fecha,
        required this.ciudad,
        required this.fechaHora});

  Historia.fromJson(Map<String, dynamic> json) {
    paqueteID = json['paqueteID'] ?? "";
    nombreEstatus = json['nombreEstatus']  ?? "";
    fecha = json['fecha'] ?? "";
    ciudad = json['ciudad'] ?? "";
    fechaHora = json['fechaHora'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['paqueteID'] = paqueteID;
    data['nombreEstatus'] = nombreEstatus;
    data['fecha'] = fecha;
    data['ciudad'] = ciudad;
    data['fechaHora'] = fechaHora;
    return data;
  }
}
