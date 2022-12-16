class PreAlertaModel
{

  String empresaId ;
  String sessionId ;
  String transportista ;
  String tracking ;
  double fob ;
  String contenido;
  String proveedor ;
  String fecha ;
  String facturaUrl;

  PreAlertaModel(
      this.empresaId,
      this.sessionId,
      this.transportista,
      this.tracking,
      this.fob,
      this.contenido,
      this.proveedor,
      this.fecha,
      this.facturaUrl);

  Map<String, dynamic> toJson() => {
    "empresaId": empresaId,
    "sessionId" : sessionId,
    "transportista" : transportista,
    "tracking" : tracking,
    "fob" : fob,
    "contenido" : contenido,
    "proveedor" : proveedor,
    "fecha" : fecha,
    "facturaUrl" : facturaUrl
  };
}

/*
public class NotificarRetiroModel
    {
        public string EmpresaId { get; set; }
        public string SessionId { get; set; }
        public string Usuario { get; set; }
        public List<String> Paquetes { get; set; }
    }

    public class SolicitudDomicilioModel
    {
        public string EmpresaId { get; set; }
        public string SessionId { get; set; }
        public List<String> Paquetes { get; set; }
    }
 */

class PreAlertaDto {
  String transportistaId;
  String enviaNombre;
  String tracking;
  String contenido;
  String facturaUrl;
  String fechaEntrega;
  String comentario;
  String facturaTexto;
  String agregadoPor;
  String agregadoEn;
  double fob;

  PreAlertaDto({
    required this.transportistaId,
    required this.enviaNombre,
    required this.tracking,
    required this.contenido,
    required this.facturaUrl,
    required this.fechaEntrega,
    required this.comentario,
    required this.facturaTexto,
    required this.agregadoPor,
    required this.agregadoEn,
    required this.fob
  });

  factory PreAlertaDto.fromJson(Map<String, dynamic> json) => PreAlertaDto(
    transportistaId: json["transportistaID"] ?? "",
    enviaNombre: json["enviaNombre"] ?? "",
    tracking: json["tracking"] ?? "",
    contenido: json["contenido"] ?? "",
    facturaUrl: json["facturaUrl"] ?? "",
    fechaEntrega: json["fechaEntrega"] ?? "",
    comentario: json["comentario"] ?? "",
    facturaTexto: json["facturaTexto"] ?? "",
    agregadoPor: json["agregadoPor"] ?? "",
    agregadoEn: json["agregadoEn"] ?? "",
    fob: json["fob"] ?? 0
  );

}