import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/noticas/noticias.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent-tab-view.dart';
import '../../preguntas/preguntas.dart';
import '../../services/courier_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:event/event.dart' as event;

import '../apps/appinfo.dart';
import '../helpers/social_media_links.dart';
import '../services/app_events.dart';
import '../services/model/empresa.dart';
import '../servicios/servicios.dart';
import 'adicionalappbar.dart';

class AdicionalInfoPage extends StatefulWidget {
  const AdicionalInfoPage({Key? key}) : super(key: key);

  @override
  State<AdicionalInfoPage> createState() => _AdicionalInfoPageState();
}

class _AdicionalInfoPageState extends State<AdicionalInfoPage> {
  String _versionNumber = "";
  String _userAccount = "";
  String _userName = "";
  String _userSucursal = "";
  UserProfile? _userProfile;
  Empresa? _empresa;

  final appInfo = GetIt.I<AppInfo>();

  String registroUrl = "";
  String ruaUrl = "";
  String correoEmpleos = "";

  _AdicionalInfoPageState()
  {
    GetIt.I<event.Event<LoginChanged>>().subscribe((args)  {
      initPlatformState();
    });
    GetIt.I<event.Event<EmpresaRefreshFinished>>().subscribe((args)  {
      initPlatformState();
    });
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    //String versionNumber = "...";
    final userProfile = await GetIt.I<CourierService>().getUserProfile();
    final info = await PackageInfo.fromPlatform();
    _empresa = await GetIt.I<CourierService>().getEmpresa();
    registroUrl = await GetIt.I<CourierService>().empresaOptionValue("RegistroAdicional");
    ruaUrl = await GetIt.I<CourierService>().empresaOptionValue("RegistroRua");
    correoEmpleos = await GetIt.I<CourierService>().empresaOptionValue("CorreoEmpleos");
    if (!mounted) return;

    setState(() {
      _versionNumber = info.version;
      _userAccount = userProfile.cuenta;
      _userName = userProfile.nombre;
      _userSucursal = userProfile.nombreSucursal;
      _userProfile = userProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdicionalPageAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 65),
          child: ListView( children: [
            if(appInfo.metricsPrefixKey != "CARIBEPACK" && appInfo.metricsPrefixKey != "BMCARGO" && appInfo.metricsPrefixKey != "SWOOP")
              InkWell(onTap: () {
                pushNewScreen(context, screen: const ServiciosPage());
                // PersistentNavBarNavigator.pushNewScreen(context,screen: const ServiciosPage());
                // Navigator.of(context, rootNavigator: false).push(MaterialPageRoute( builder: (context) => const ServiciosPage()));
                },
                  child:  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), leading: Icon(Icons.miscellaneous_services, size: 20, color: Theme.of(context).colorScheme.secondary,), trailing: const Icon(Icons.chevron_right), title: Text("servicios".tr(), style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onBackground),),),
                  )),
            if(appInfo.metricsPrefixKey == "BMCARGO")
              InkWell(onTap: () {
                pushNewScreen(context, screen: const NoticiasPage());
                // PersistentNavBarNavigator.pushNewScreen(context,screen: const ServiciosPage());
                // Navigator.of(context, rootNavigator: false).push(MaterialPageRoute( builder: (context) => const ServiciosPage()));
              },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), leading: Icon(Icons.feed, size: 20, color: Theme.of(context).colorScheme.secondary,), trailing: const Icon(Icons.chevron_right), title: Text("noticias".tr(), style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onBackground),),),
                  )),
            if(appInfo.metricsPrefixKey == "CARIBEPACK")
              InkWell(onTap:  () async {
                await launchUrl(Uri.parse("https://caribetours.com.do/caribe-pack/tarifa-de-envios/"));
              },
                  child:  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), leading: Icon(Icons.price_check, size: 20, color: Theme.of(context).colorScheme.secondary), trailing: const Icon(Icons.chevron_right), title: Text("nuestras_tarifas".tr(), style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onBackground),),),
                  )),
            InkWell(onTap: () {
              pushNewScreen(context, screen: const PreguntasPage());
              // PersistentNavBarNavigator.pushNewScreen(context,screen: const PreguntasPage());
              // Navigator.of(context, rootNavigator: false).push(MaterialPageRoute(builder: (context)=> const PreguntasPage()));
            }, child:  Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), leading: Icon(Icons.question_answer, size: 20, color: Theme.of(context).colorScheme.secondary ), trailing: const Icon(Icons.chevron_right), title: Text("preguntas".tr(), style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onBackground),),),
            )),
            if(_empresa?.correoServicio != null && _empresa!.correoServicio.isNotEmpty)
              InkWell(
                onTap: () => { openExteralUrl(_empresa!.correoServicio)},
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), leading: Icon(Icons.contact_phone_outlined, size: 20 , color: Theme.of(context).colorScheme.secondary), trailing:
                  const Icon(Icons.launch),
                    title: Text("servicio_al_cliente".tr(), style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onBackground),),),
                ),
              ),
            if(_empresa?.twitter != null && _empresa!.twitter.isNotEmpty)
              InkWell(
                onTap: () => { openExteralUrl(_empresa!.twitter)},
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), leading: Icon(Icons.support, size: 20, color: Theme.of(context).colorScheme.secondary ), trailing:
                  const Icon(Icons.launch),
                    title: Text(appInfo.metricsPrefixKey == "BLUMBOX" ? "ticket_de_ayuda".tr() : "solicitar_soporte".tr(), style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onBackground),),),
                ),
              ),
            if(registroUrl.isNotEmpty && _userAccount.isEmpty)
              InkWell(
                onTap: () => { openExteralUrl(registroUrl)},
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), leading: Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.secondary ), trailing:
                  const Icon(Icons.person),
                    title: Text("registrate_aqui".tr(), style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onBackground),),),
                ),
              ),
            if(ruaUrl.isNotEmpty)
              InkWell(
                onTap: () => { openExteralUrl(ruaUrl)},
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), leading: Icon(Icons.airplanemode_active, size: 20, color: Theme.of(context).colorScheme.secondary ), trailing:
                  const Icon(Icons.web),
                    title: Text("registrate_rua".tr(), style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onBackground),),),
                ),
              ),
            if(correoEmpleos.isNotEmpty)
              InkWell(
                onTap: () => { openExteralUrl(correoEmpleos)},
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), leading: Icon(Icons.work, size: 20, color: Theme.of(context).colorScheme.secondary ), trailing:
                  const Icon(Icons.mail),
                    title: Text("empleate".tr(), style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onBackground),),),
                ),
              ),
            if( _empresa != null && (_empresa!.mision.isNotEmpty || _empresa!.vision.isNotEmpty ) )
            InkWell(
              onTap: () => {showAboutUs(context)},
              child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), leading: Icon(Icons.info, size: 20, color: Theme.of(context).colorScheme.secondary ), trailing:
                const Icon(Icons.expand_circle_down_outlined),
                title: Text("sobre_nosotros".tr(), style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onBackground),),),
            ),
            // const Spacer(),
            if(_empresa != null && _userProfile != null)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 15),
                child: SocialMediaLinks(empresa: _empresa!, userProfile: _userProfile!,),
              ),
            // if(_empresa != null)
            //   const Spacer(),
            if(_empresa != null)
            Center(
              child: AutoSizeText(_userName.isNotEmpty ? "$_userName ($_userAccount)" : "", maxLines: 1, minFontSize: 12, style: Theme.of(context).textTheme.bodyMedium?.copyWith(shadows: [Shadow(
                  color: Theme.of(context).textTheme.titleSmall!.color!.withOpacity(0.3),
                  offset: const Offset(2, 2),
                  blurRadius: 10)]),),
            ),
            // Text(_userAccount, style: Theme.of(context).textTheme.bodyMedium?.copyWith(shadows: [Shadow(
            //     color: Theme.of(context).textTheme.titleSmall!.color!.withOpacity(0.3),
            //     offset: const Offset(2, 2),
            //     blurRadius: 10)]),),

            // if(_userName.isNotEmpty && _empresa != null && _empresa!.dominio.toUpperCase() == "BOXPAQ")
            //   InkWell(
            //     onTap:  () =>  { openExteralUrl("https://boxpaq-online.iplus.com.do/lg-es/ma/MiCuenta.aspx") },
            //     child: Padding(
            //       padding: const EdgeInsets.symmetric(vertical: 8.0),
            //       child: Text('Borrar mi cuenta', style: Theme.of(context).textTheme.bodySmall?.copyWith(shadows: [Shadow(
            //           color: Theme.of(context).textTheme.titleSmall!.color!.withOpacity(0.3),
            //           offset: const Offset(2, 2),
            //           blurRadius: 10)]),),
            //     ),
            //   ),

            if(_userSucursal.isNotEmpty)
            Center(
              child: Text(_userSucursal, style: Theme.of(context).textTheme.bodyMedium?.copyWith(shadows: [Shadow(
                  color: Theme.of(context).textTheme.titleSmall!.color!.withOpacity(0.3),
                  offset: const Offset(2, 2),
                  blurRadius: 10)]),),
            ),
            const SizedBox(height: 10,),
            if(appInfo.additionalLocale.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(onPressed: () { context.setLocale(const Locale('es')); }, child: context.locale.languageCode == 'es' ? Text('Español', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),) : const Text('Español'),),
                  Icon(Icons.circle, color: Theme.of(context).dividerColor, size: 6,),
                  TextButton(onPressed: () { context.setLocale(const Locale('en')); }, child: context.locale.languageCode == 'en' ? Text('English', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),) : const Text('English'),),
                ],),
            if(_versionNumber.isNotEmpty)
            Center(
              child: Text("version_info".tr(args: [_versionNumber]), style: Theme.of(context).textTheme.bodySmall?.copyWith(shadows: [Shadow(
                  color: Theme.of(context).textTheme.titleSmall!.color!.withOpacity(0.3),
                  offset: const Offset(3, 3),
                  blurRadius: 10)]),),
            )
            ],),
        ),
      ));
  }

  Future<void> openExteralUrl(String url) async {
    if(url.contains('@')) {
      if(!url.contains('mailto:')) {
        url = "mailto:$url";
      }
    } else {
      if(!url.contains('http://') && !url.contains('https://')) {
        url = 'https://$url';
      }
    }

    var _url = Uri.parse(url);
    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  Future<void> showAboutUs(
      BuildContext context) async {
    var courierService = GetIt.I<CourierService>();
    var empresa = await courierService.getEmpresa();

    //NavbarNotifier.hideBottomNavBar = true;
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(false));
    await showModalBottomSheet(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        context: context,
        builder: (builder) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: ShapeDecoration(color: Theme.of(context).appBarTheme.backgroundColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                          child: Text(empresa.nombre,
                              style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).appBarTheme.foregroundColor))),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 475,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ImageSlideshow(
                  indicatorColor: empresa.vision.isNotEmpty && empresa.mision.isNotEmpty ? Theme.of(context).colorScheme.secondary : Colors.transparent,
                      children: [
                    if(empresa.mision.isNotEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 10,),
                        if(empresa.vision.isNotEmpty)
                        Text("mision".tr(), style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center,),
                        if(empresa.vision.isNotEmpty)
                        const SizedBox(height: 20,),
                        Expanded(
                          child: SingleChildScrollView(scrollDirection: Axis.vertical, child: Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 20.0),
                            child: Text(empresa.mision, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.justify, ),
                          )),
                        ),
                      ],
                    ),
                    if(empresa.vision.isNotEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 10,),
                        if(empresa.mision.isNotEmpty)
                        Text("vision".tr(), style: Theme.of(context).textTheme.titleLarge,textAlign: TextAlign.center, ),
                        if(empresa.mision.isNotEmpty)
                        const SizedBox(height: 20,),
                        Expanded(
                          child: SingleChildScrollView(scrollDirection: Axis.vertical, child: Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 20.0),
                            child: Text(empresa.vision, style: Theme.of(context).textTheme.bodyMedium,textAlign: TextAlign.justify,),
                          )),
                        ),
                      ],
                    ),

                  ]),
                ),
              ),
              //SocialMediaLinks(empresa: empresa,),
              const SizedBox(height: 20),
            ],
          );
        });
    //NavbarNotifier.hideBottomNavBar = false;
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(true));
  }
}
