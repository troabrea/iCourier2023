class PostAlertaModel
{

  String empresaId ;
  String sessionId ;
  String recepcionId ;
  double fob ;
  String facturaUrl;

  PostAlertaModel(
      this.empresaId,
      this.sessionId,
      this.recepcionId,
      this.fob,
      this.facturaUrl);

  Map<String, dynamic> toJson() => {
    "empresaId": empresaId,
    "sessionId" : sessionId,
    "recepcionId" : recepcionId,
    "fob" : fob,
    "facturaUrl" : facturaUrl
  };
}