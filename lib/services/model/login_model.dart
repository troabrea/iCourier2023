class LoginRequest {
  LoginRequest({required this.empresaId, required this.userAccount, required this.password});
  String empresaId;
  String userAccount;
  String password;

  Map<String, dynamic> toJson() => {
    "empresaId": empresaId,
    "userAccount" : userAccount,
    "password": password
  };

}

class LoginResult {
  LoginResult({required this.sessionId, required this.nombre, required this.email, required this.telefono, required this.sucursal,required this.fotoPerfilUrl});
  String sessionId;
  String nombre;
  String email;
  String telefono;
  String sucursal;
  String fotoPerfilUrl;
  bool shouldAskToStore = false;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
    sessionId: json["sessionId"] ?? "",
    nombre: json["nombre"] ?? "",
    email: json["email"] ?? "",
    telefono: json["telefono"] ?? "",
    sucursal: json["sucursal"] ?? "",
    fotoPerfilUrl: json["fotoPerfilUrl"] ?? "",

  );
}

class UserProfile {
  UserProfile({required  this.cuenta, required this.nombre, required this.email,
    required this.sucursal,required this.fotoPerfilUrl,
    required this.direccionBuzon,
    this.emailSucursal = "",
    this.telefono = "",
    this.nombreSucursal = "",
    this.telefonoSucursal = "",
    this.whatsappSucursal = "",
    this.chatUrl = "",
  });
  String cuenta;
  String nombre;
  String email;
  String telefono;
  String sucursal;
  String fotoPerfilUrl;
  String nombreSucursal;
  String telefonoSucursal;
  String whatsappSucursal;
  String emailSucursal;
  String chatUrl;
  String direccionBuzon;
}

class UserAccount {
  UserAccount({required this.sessionId, required this.nombre, required this.userAccount, required this.password});
  String sessionId;
  String nombre;
  String userAccount;
  String password;

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
      sessionId: json["sessionId"] ?? "",
      nombre: json["nombre"] ?? "",
      userAccount: json["userAccount"] ?? "",
      password: json["password"] ?? ""
  );

  Map<String, dynamic> toJson() => {
    "sessionId": sessionId,
    "nombre": nombre,
    "userAccount" : userAccount,
    "password": password
  };

}

class UserProfileModel {
  String empresaId;
  String cuenta;
  String photoUrl;

  UserProfileModel({required this.empresaId, required this.cuenta, required this.photoUrl});

  Map<String, dynamic> toJson() => {
    "empresaId": empresaId,
    "cuenta": cuenta,
    "photoUrl" : photoUrl
  };

}

class PasswordResetModel {
  String account;
  String email;
  String empresaId;

  PasswordResetModel({required this.empresaId, required this.account, required this.email});

  Map<String, dynamic> toJson() => {
    "empresaId": empresaId,
    "account": account,
    "email" : email
  };

}