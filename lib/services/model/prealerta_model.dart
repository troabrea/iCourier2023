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
    "transpor" : transportista,
    "hasta" : tracking,
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