import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:app_center_bundle_sdk/app_center_bundle_sdk.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/rendering.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/model/calculadora_model.dart';
import '../../services/model/notificarretiro_model.dart';
import '../../services/model/postalerta_model.dart';
import '../../services/model/prealerta_model.dart';
import 'package:azblob/azblob.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'model/banner.dart';
import 'model/empresa.dart';
import 'model/login_model.dart';
import 'model/noticia.dart';
import 'model/pregunta.dart';
import 'model/recepcion.dart';
import 'model/servicio.dart';
import 'model/sucursal.dart';

List<Noticia> noticiasFromJson(String str) =>
    List<Noticia>.from(json.decode(str).map((x) => Noticia.fromJson(x)));

String noticiasToJson(List<Noticia> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

List<Servicio> servicioFromJson(String str) =>
    List<Servicio>.from(json.decode(str).map((x) => Servicio.fromJson(x)));

String servicioToJson(List<Servicio> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

List<BannerImage> bannerFromJson(String str) => List<BannerImage>.from(
    json.decode(str).map((x) => BannerImage.fromJson(x)));

String bannerToJson(List<BannerImage> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

List<Sucursal> sucursalFromJson(String str) =>
    List<Sucursal>.from(json.decode(str).map((x) => Sucursal.fromJson(x)));

String sucursalToJson(List<Sucursal> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

List<Pregunta> preguntaFromJson(String str) => List<Pregunta>.from(json.decode(str).map((x) => Pregunta.fromJson(x)));

String preguntaToJson(List<Pregunta> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

Empresa empresaFromJson(String str) => Empresa.fromJson(json.decode(str));

String empresaToJson(Pregunta data) => json.encode(data.toJson());

List<CalculadoraResponse> calculadoraResponseFromJson(String str) => List<CalculadoraResponse>.from(json.decode(str).map((x) => CalculadoraResponse.fromJson(x)));

String calculadoraResponseToJson(List<CalculadoraResponse> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

String calculadoraRequestToJson(List<CalculadoraRequest> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

LoginResult loginResponseFromJson(String str) => LoginResult.fromJson(json.decode(str));

List<Recepcion> recepcionFromJson(String str) => List<Recepcion>.from(json.decode(str).map((x) => Recepcion.fromJson(x)));

LoginResult userProfileFromJson(String str) => LoginResult.fromJson(json.decode(str));

List<UserAccount> userAccountsFromJson(String str) => List<UserAccount>.from(json.decode(str).map((x) => UserAccount.fromJson(x)));
String userAccountsToJson(List<UserAccount> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CourierService {
  static const empresaId = "08811d51-77bb-4a5b-a908-7d887632307d"; // "ebb66ab7-db15-4267-9ef4-92abcb5273eb";//

  Future<List<Noticia>> getNoticias(bool ignoreCache) async {
    if(ignoreCache) {
      cache.destroy('noticias');
    }
    AppCenter.trackEventAsync("DOMEX_GET_NOTICIAS");
    var jsonData = await cache.remember('noticas', () async {
      final response = await get(Uri.parse(
          "https://icourierfunctions.azurewebsites.net/api/noticias/$empresaId?code=X3szWXfFCm2QfbebJIDsWIYGVxmqCJtPvIRgLK4cqzdxVQanXaJoaw=="));
      return response.body;
    }, 60 * 20);
    return noticiasFromJson(jsonData);
  }

  Future<List<Servicio>> getServicios(bool ignoreCache) async {
    if(ignoreCache) {
      cache.destroy('servicios');
    }
    AppCenter.trackEventAsync("DOMEX_GET_SERVICIOS");
    var jsonData = await cache.remember('servicios', () async {
      final response = await get(Uri.parse(
          "https://icourierfunctions.azurewebsites.net/api/servicios/$empresaId?code=g7YCaekeaJa8aTrOaovkPDOaMQ44pmmMcgkbs5QZJN8njhpxTQFJUw=="));
      return response.body;
    }, 60 * 20);
    return servicioFromJson(jsonData);
  }

  Future<List<BannerImage>> getBanners({bool hideIfLogged = false, bool ignoreCache = false}) async {
    if (hideIfLogged) {
      var sessionId = (await cache.load('sessionId', ''))
          .toString(); //  prefs.getString('sessionId');
      if (sessionId.isNotEmpty) {
        return <BannerImage>[].toList();
      }
    }
    if(ignoreCache) {
      cache.destroy('banners');
    }
    var jsonData = await cache.remember('banners', () async {
      final response = await get(Uri.parse(
          "https://icourierfunctions.azurewebsites.net/api/banners/$empresaId?code=OMjjM8DkJSlKfsKAoLEiC8W0nh1rDIvYVfLcuWQGXB1XVyqXD04/dw=="));
      return response.body;
    }, 60 * 20);
    return bannerFromJson(jsonData);
  }

  Future<List<Sucursal>> getSucursales(bool ignoreCache) async {
    if(ignoreCache) {
      cache.destroy('sucursales');
    }
    AppCenter.trackEventAsync("DOMEX_GET_SUCURSALES");
    var jsonData = await cache.remember('sucursales', () async {
      final response = await get(Uri.parse(
          "https://icourierfunctions.azurewebsites.net/api/sucursales/$empresaId?code=l9nBF9apVrNVHLBb4seWuVN1Do7HPlSIIaZhjMCq7IW3wNknz3gdJQ=="));
      return response.body;
    }, 60 * 20);
    return sucursalFromJson(jsonData);
  }

  Future<List<Pregunta>> getPreguntas(bool ignoreCache) async {
    if(ignoreCache) {
      cache.destroy('preguntas');
    }

    AppCenter.trackEventAsync("DOMEX_GET_PREGUNTAS");

    var jsonData = await cache.remember('preguntas', () async {
      final response = await get(Uri.parse(
          "https://icourierfunctions.azurewebsites.net/api/preguntas/$empresaId?code=UCr6KrTYCBAf8DKJ/7oGNoRVauZtPByH/ocWH/yFA5gh0j0ZxwR6ow=="));
      return response.body;
    }, 60 * 20);
    return preguntaFromJson(jsonData);
  }

  Future<Empresa> getEmpresa() async {
    var jsonData = await cache.remember('empresa', () async {
      final response = await get(Uri.parse(
          "https://icourierfunctions.azurewebsites.net/api/empresa/$empresaId?code=LZ6v34a6bVN5NQKM/I/IWUd9WujwKzrlWKJogP9EKKhQvapa7F5R0A=="));
      return response.body;
    });
    return empresaFromJson(jsonData);
  }

  Future<List<CalculadoraResponse>> getCalculadoraResult(double libras,
      double valor, {String producto = ""}) async {

    AppCenter.trackEventAsync("DOMEX_GET_CALCULADORA");

    final uri = Uri.parse(
        "https://icourierfunctions.azurewebsites.net/api/calculadora?code=UpOzDP0FHR4nhMaeqns1SzhmQuhFrzpZSlP1VVIui9HzAToeJ8ky5g==");
    final req = CalculadoraRequest(empresaId: empresaId,
        sessionId: "",
        producto: producto,
        libras: libras,
        valorFob: valor);
    final json = jsonEncode(req);
    final response = await post(uri, body: json);
    final result = calculadoraResponseFromJson(response.body);
    return result;
  }

  Future<LoginResult> getLoginResult(String usuario, String clave, {bool checkForNew = true}) async
  {
    final req = LoginRequest(
        empresaId: empresaId, userAccount: usuario, password: clave);
    final uri = Uri.parse(
        "https://icourierfunctions.azurewebsites.net/api/session?code=ZlU5duHfxMjRUctLShLI0cvvJWdvKnT79YBfGF8UgjPThX4Et6RKJA==");
    final json = jsonEncode(req);
    final response = await post(uri, body: json);
    var bodyStr = response.body;
    final result = loginResponseFromJson(bodyStr);
    if(result.sessionId.isNotEmpty && checkForNew) {
      await saveLoggedInState(result, usuario, clave);
      var storedAccounts = await getStoredAccounts();
      if(storedAccounts.isEmpty) {
        await addCurrentAccountToStore();
      } else {
        result.shouldAskToStore = (!storedAccounts.any((element) => element.userAccount == usuario));
      }
    }
    return result;
  }

  void clearCourierDataCache()
  {
    cache.destroy('recepciones');
  }

  Future<List<Recepcion>> getRecepciones(bool forceRefresh) async {
    if (forceRefresh) {
      cache.destroy('recepciones');
    }
    AppCenter.trackEventAsync("DOMEX_GET_RECEPCIONES");
    var jsonData = await cache.remember('recepciones', () async {
      var sessionId = (await cache.load('sessionId', ''))
          .toString(); //  prefs.getString('sessionId');
      if (sessionId == "") {
        return "[]";
      }
      final uri = Uri.parse(
          "https://icourierfunctions.azurewebsites.net/api/recepciones?code=bXIWbqplZhB58kuSsfo92xW7bG8SBoTzWdBzs3TjQeiQwvwo/q1laA==");
      final req = RecepcionRequest(empresaId: empresaId, sessionId: sessionId);
      final json = jsonEncode(req);
      final response = await post(uri, body: json);
      return response.body;
    }, 60 * 5);
    var result = recepcionFromJson(jsonData);
    result.sort((a, b) {
      return b.fechaRecibido().compareTo(a.fechaRecibido());
    });
    return result;
  }

  Future<List<Recepcion>> getHistoriaRecepciones(DateTime desde,
      DateTime hasta) async {
    var sessionId = (await cache.load('sessionId', ''))
        .toString(); //  prefs.getString('sessionId');
    if (sessionId == "") {
      return <Recepcion>[].toList();
    }

    var dateFormat = DateFormat("yyy-MM-dd");

    AppCenter.trackEventAsync("DOMEX_GET_HISTORIA");

    final uri = Uri.parse(
        "https://icourierfunctions.azurewebsites.net/api/historia?code=gerWGYCG2sXQyxgxx6QHTRFtWey7Ab/oJtEPHCQQ76qVwg3BMJvI4Q==");
    final req = ConsultaHistoricaRequest(empresaId: empresaId,
        sessionId: sessionId,
        desde: dateFormat.format(desde),
        hasta: dateFormat.format(hasta));
    final json = jsonEncode(req);
    final response = await post(uri, body: json);
    var result = recepcionFromJson(response.body);
    result.sort((a, b) {
      return b.fechaRecibido().compareTo(a.fechaRecibido());
    });
    return result;
  }

  Future<UserProfile> getUserProfile() async {
    var cuenta = await cache.load('userAccount', "");
    var nombre = await cache.load('userName', "");
    var email = await cache.load('userEmail', "");
    var sucursal = await cache.load('userSucursal', "");
    var foto = await cache.load('userFotoPerfil', "");

    return UserProfile(cuenta: cuenta,
        nombre: nombre,
        email: email,
        sucursal: sucursal,
        fotoPerfilUrl: foto);
  }

  Future<List<UserAccount>> getStoredAccounts() async {
    var data = await cache.load('storedAccounts');
    var list = data == null ? <UserAccount>[].toList() : userAccountsFromJson(data);
    return list;
  }

  Future<List<UserAccount>> addCurrentAccountToStore() async {
      var list = await getStoredAccounts();
      final sessionId = await cache.load('sessionId', "");
      final userAccount = await cache.load('userAccount', "");
      final password = await cache.load('userPassword', "");
      final userName = await cache.load('userName', "");
      var storedAccount = list.firstWhereOrNull((x) => x.userAccount == userAccount);
      if(storedAccount == null) {
        list.add(UserAccount(sessionId: sessionId, nombre: userName, userAccount: userAccount, password: password));
      } else {
        storedAccount.password = password;
        storedAccount.nombre = userName;
        storedAccount.sessionId = sessionId;
      }
      final data = userAccountsToJson(list);
      await cache.write('storedAccounts', data);
      return list;
  }

  Future<bool> switchUserAccount(String newAccount) async {
    var list = await getStoredAccounts();
    var storedAccount = list.firstWhereOrNull((x) => x.userAccount == newAccount);
    if(storedAccount == null) return false;
    var loginResult = await getLoginResult(storedAccount.userAccount, storedAccount.password, checkForNew: false);
    if(loginResult.sessionId.isEmpty) return false;
    await saveLoggedOutState();
    await saveLoggedInState(loginResult, storedAccount.userAccount, storedAccount.password);
    return true;
  }

  Future<void> saveLoggedInState(LoginResult loginResult, String userAccount, String userPassword) async {
    FirebaseMessaging.instance.subscribeToTopic("DOMEX_$userAccount");
    await cache.write('sessionId', loginResult.sessionId);
    await cache.write('userAccount', userAccount);
    await cache.write('userPassword', userPassword);
    await cache.write('userName', loginResult.nombre);
    await cache.write('userEmail', loginResult.email);
    await cache.write('userSucursal', loginResult.sucursal);
    await cache.write('userFotoPerfil', loginResult.fotoPerfilUrl);
    //
  }
  Future<void> saveLoggedOutState() async {
    var userAccount =  await cache.load('userAccount', "") as String;
    if(userAccount.isNotEmpty) {
      FirebaseMessaging.instance.unsubscribeFromTopic("DOMEX_$userAccount");
    }

    await cache.write('sessionId', "");
    await cache.write('userAccount', "");
    await cache.write('userName', "");
    await cache.write('userEmail', "");
    await cache.write('userSucursal', "");
    await cache.write('userFotoPerfil', "");


  }

  Future<void> launchOnlinePayment()  async {
    final empresa = await getEmpresa();
    final cuenta = await cache.load('userAccount', "");
    final password = await cache.load('userPassword', "");
    var url = empresa.urlServidor;
    url = url + "?UsuarioID=$cuenta&UsuarioPW=$password&UrlID=pagos&mn=0";
    url = Uri.encodeFull(url);
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<String> notificaRetiro()  async {
    final empresa = await getEmpresa();
    if(!empresa.hasNotifyModule) {return 'Funcionalidad no disponible.';}

    final codSucrusal = (await cache.load('userSucursal','')).toString();
    if(codSucrusal.isEmpty) {return 'Funcionalidad no disponible.';}

    var sucursal = (await getSucursales(false)).firstWhereOrNull((x) => x.codigo == codSucrusal);
    if(sucursal == null) return 'Funcinalidad no disponible';

    var sessionId = (await cache.load('sessionId', ''))
        .toString(); //  prefs.getString('sessionId');
    if (sessionId == "") {
      return 'Funcinalidad no disponible';
    }

    var cuenta = await cache.load('userAccount', "");
    if (cuenta == "") {
      return 'Funcinalidad no disponible';
    }

    var paquetes = (await getRecepciones(false)).map((e) => e.recepcionID).toList();
    if(paquetes.isEmpty) {
      return 'Funcinalidad no disponible';
    }



    if(empresa.minDistanceToNotify > 0) {
      var status = await Permission.locationWhenInUse.status;

      if (status.isDenied) {
        await Permission.locationWhenInUse.request();
      }

      if (await Permission.locationWhenInUse.isGranted) {
        Location location = Location();
        var locationData = await location.getLocation();
        var userLatitude = locationData.latitude ?? 0.00;
        var userLongitude = locationData.longitude ?? 0.00;
        var distance = calculateDistance(
            userLatitude,
            userLongitude,
            sucursal.latitud,
            sucursal.longitud) / 1000;

        if (distance < empresa.minDistanceToNotify) {
          return 'Debe estar a menos de ${empresa
              .minDistanceToNotify} metros de su sucursal de retiro para poder ejecutar esta operación.';
        }
      }
    }

    return '';

  }

  Future<bool> sendPreAlerta(PreAlertaModel preAlerta, XFile file) async {
    try {
      var sessionId = (await cache.load('sessionId', ''))
          .toString(); //  prefs.getString('sessionId');
      if (sessionId == "") {
        return false;
      }

      AppCenter.trackEventAsync("DOMEX_SEND_PREALERTA");

      var storage = AzureStorage.parse(
          'DefaultEndpointsProtocol=https;AccountName=barolitblobstorage;AccountKey=SQgzWYWHLYFscpvX2cuf9NI4ZPMPtfjEWVW3WEQ8qnKZh7ColquKRM5r0sj7EZXBAbv7D6HK9c7+kzziLEoI0w==;EndpointSuffix=core.windows.net');

      String fileName = Uuid().v1().toString() + File(file.path).uri.pathSegments.last;

      // var fileName = Uuid().v1().toString() + ".jpg";
      var azPath = "/icourier/$fileName";


      Uint8List bytes = await file.readAsBytes();
      await storage.putBlob(azPath, bodyBytes: bytes);
      //

      final uri = Uri.parse(
          "https://icourierfunctions.azurewebsites.net/api/prealerta?code=cxsYglMU8mj4ECTBek9NpgudSAuMh8aaZsG/oSYdmknJ/IhyNWGlwA==");

      var imageUrl = "https://barolitblobstorage.blob.core.windows.net/icourier/$fileName";

      var req = PreAlertaModel(
          empresaId,
          sessionId,
          preAlerta.transportista,
          preAlerta.tracking,
          preAlerta.fob,
          preAlerta.contenido,
          preAlerta.proveedor,
          preAlerta.fecha,
          imageUrl);
      final json = jsonEncode(req);
      final response = await post(uri, body: json);
      //
      return (response.statusCode >= 200 && response.statusCode < 299);
    } catch (ex) {
      return false;
    }
  }

  Future<bool> updateProfilePhoto(XFile file) async {
    try {
      var sessionId = (await cache.load('sessionId', ''))
        .toString();
      if (sessionId == "") {
        return false;
      }

      var cuenta = (await cache.load('userAccount', ''))
          .toString();
      if (cuenta == "") {
        return false;
      }

      AppCenter.trackEventAsync("DOMEX_UPDATE_PHOTO");

      var storage = AzureStorage.parse(
      'DefaultEndpointsProtocol=https;AccountName=barolitblobstorage;AccountKey=SQgzWYWHLYFscpvX2cuf9NI4ZPMPtfjEWVW3WEQ8qnKZh7ColquKRM5r0sj7EZXBAbv7D6HK9c7+kzziLEoI0w==;EndpointSuffix=core.windows.net');

      String fileName = Uuid().v1().toString() + File(file.path).uri.pathSegments.last;

      //var fileName = Uuid().v1().toString() + ".jpg";

      var azPath = "/icourier/$fileName";
      Uint8List bytes = await file.readAsBytes();
      await storage.putBlob(azPath, bodyBytes: bytes);
      final uri = Uri.parse("https://icourierfunctions.azurewebsites.net/api/updateprofilephoto?code=hQ8Sz4aQv6grvBj0P4z/MppLEDnRYNohAWqxdORRuDYTGzpGAwknxQ==");

      var imageUrl = "https://barolitblobstorage.blob.core.windows.net/icourier/$fileName";

      var req = UserProfileModel( cuenta: cuenta, empresaId: empresaId, photoUrl: imageUrl);

      final json = jsonEncode(req);
      final response = await post(uri, body: json);
      //
      var okResult = (response.statusCode >= 200 && response.statusCode < 299);
      if(okResult) {
        await cache.write('userFotoPerfil', imageUrl);
      }
      return okResult;
    } catch (ex) {
      return false;
    }
  }

  Future<bool> sendPostAlerta(PostAlertaModel postAlerta, XFile file) async {
    try {
      var sessionId = (await cache.load('sessionId', ''))
          .toString(); //  prefs.getString('sessionId');
      if (sessionId == "") {
        return false;
      }

      AppCenter.trackEventAsync("DOMEX_SEND_POSTALERTA");


      var storage = AzureStorage.parse(
          'DefaultEndpointsProtocol=https;AccountName=barolitblobstorage;AccountKey=SQgzWYWHLYFscpvX2cuf9NI4ZPMPtfjEWVW3WEQ8qnKZh7ColquKRM5r0sj7EZXBAbv7D6HK9c7+kzziLEoI0w==;EndpointSuffix=core.windows.net');

      String fileName = Uuid().v1().toString() + File(file.path).uri.pathSegments.last;

      //var fileName = Uuid().v1().toString() + ".jpg";

      var azPath = "/icourier/$fileName";
      Uint8List bytes = await file.readAsBytes();
      await storage.putBlob(azPath, bodyBytes: bytes);
      // https://barolitblobstorage.blob.core.windows.net/icourier/00001161-33a3-4cc7-8960-670b7ae47b30.jpg
      final uri = Uri.parse(
          "https://icourierfunctions.azurewebsites.net/api/prealerta?code=cxsYglMU8mj4ECTBek9NpgudSAuMh8aaZsG/oSYdmknJ/IhyNWGlwA==");

      var imageUrl = "https://barolitblobstorage.blob.core.windows.net/icourier/$fileName";

      var req = PostAlertaModel(
          empresaId,
          sessionId,
          postAlerta.recepcionId,
          postAlerta.fob,
          imageUrl
          );

      final json = jsonEncode(req);
      final response = await post(uri, body: json);
      //
      return (response.statusCode >= 200 && response.statusCode < 299);
    } catch (ex) {
      return false;
    }
  }
}
