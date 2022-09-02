class NotificarRetiroModel
{

  final String empresaId ;
  final String sessionId ;
  final String usuario ;
  final List<String> paquetes ;

  NotificarRetiroModel(
      this.empresaId,
      this.sessionId,
      this.usuario,
      this.paquetes);

  Map<String, dynamic> toJson() => {
    "empresaId": empresaId,
    "sessionId" : sessionId,
    "usuario" : usuario,
    "paquetes" : paquetes
  };
}