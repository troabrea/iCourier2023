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

  int progresoActual() {
    if(disponible) {
      return 4;
    } else if(estatus.toUpperCase().contains("EMBARCADO") || estatus.toUpperCase().contains("EMPACADO")) {
      return 2;
    } else if(estatus.toUpperCase().contains("TRANSFERIDO") || estatus.toUpperCase().contains("EMPACADO")
         || estatus.toUpperCase().contains("TRANSFERIDO") || estatus.toUpperCase().contains("EMPACADO")
         || estatus.toUpperCase().contains("ADUANA") || estatus.toUpperCase().contains("TRANSITO")
         || estatus.toUpperCase().contains("DISTRIBUCION") || estatus.toUpperCase().contains("DISTRIBUCIÓN")
         || estatus.toUpperCase().contains("RECIBIDO AILA") || estatus.toUpperCase().contains("ALMACEN")) {
      return 3;
    }
    return 1;
  }

  double montoTotal() => double.tryParse(totalNeto.replaceAll(',', '')) ?? 0.00;

  DateTime fechaRecibido() => DateTime.tryParse(fecha.replaceAll(".", "-")) ?? DateTime(2000,1,1);

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
        paquetes.add(new Paquetes.fromJson(v));
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
    if (paquetes != null) {
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
        historia.add(new Historia.fromJson(v));
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
    if (historia != null) {
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
    var theDateTime = DateFormat("yyyy-MM-dd hh:mm:ss").parse( soloFecha() + " " + soloHora() );
    if(soloHora().contains("PM") && theDateTime.hour != 12)
      {
        theDateTime = theDateTime.add(const Duration(hours: 12));
      }
    if(soloHora().contains("AM") && theDateTime.hour == 12)
    {
      theDateTime = theDateTime.subtract(const Duration(hours: 12));
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
