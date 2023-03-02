class SolicitarDomicilioModel
{

  final String empresaId ;
  final String sessionId ;
  final List<String> paquetes ;

  SolicitarDomicilioModel(
      this.empresaId,
      this.sessionId,
      this.paquetes);

  Map<String, dynamic> toJson() => {
    "empresaId": empresaId,
    "sessionId" : sessionId,
    "paquetes" : paquetes
  };
}