import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import '../../preguntas/preguntas.dart';
import '../../services/courier_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:event/event.dart' as event;

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
  Empresa? _empresa;

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
    var userProfile = await GetIt.I<CourierService>().getUserProfile();
    final info = await PackageInfo.fromPlatform();
    _empresa = await GetIt.I<CourierService>().getEmpresa();

    if (!mounted) return;

    setState(() {
      _versionNumber = info.version;
      _userAccount = userProfile.cuenta;
      _userName = userProfile.nombre;
      _userSucursal = userProfile.nombreSucursal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdicionalPageAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 65),
          child: Column(children: [
            InkWell(onTap: () {
              PersistentNavBarNavigator.pushNewScreen(context,screen: const ServiciosPage());
              // Navigator.of(context, rootNavigator: false).push(MaterialPageRoute( builder: (context) => const ServiciosPage()));
              },
                child:  Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), child: ListTile(leading: Icon(Icons.miscellaneous_services, color: Theme.of(context).primaryColorDark), trailing: const Icon(Icons.chevron_right), title: const Text("Servicios"),))),
            InkWell(onTap: () {
              PersistentNavBarNavigator.pushNewScreen(context,screen: const PreguntasPage());
              // Navigator.of(context, rootNavigator: false).push(MaterialPageRoute(builder: (context)=> const PreguntasPage()));
            }, child:  Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), child: ListTile(leading: Icon(Icons.question_answer, color: Theme.of(context).primaryColorDark ), trailing: const Icon(Icons.chevron_right), title: const Text("Preguntas"),))),
            if(_empresa?.correoServicio != null)
              InkWell(
                onTap: () => { openExteralUrl(_empresa!.correoServicio)},
                child: Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), child: ListTile(leading: Icon(Icons.contact_phone_outlined, color: Theme.of(context).primaryColorDark ), trailing:
                const Icon(Icons.launch),
                  title: const Text("Servicio al Cliente"),)),
              ),
            if(_empresa?.twitter != null)
              InkWell(
                onTap: () => { openExteralUrl(_empresa!.twitter)},
                child: Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), child: ListTile(leading: Icon(Icons.support, color: Theme.of(context).primaryColorDark ), trailing:
                const Icon(Icons.launch),
                  title: const Text("Solicitar Soporte"),)),
              ),
            InkWell(
              onTap: () => {showAboutUs(context)},
              child: Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)), child: ListTile(leading: Icon(Icons.info, color: Theme.of(context).primaryColorDark ), trailing:
                const Icon(Icons.expand_circle_down_outlined),
                title: const Text("Sobre Nosotros"),)),
            ),
            const Spacer(),
            if(_empresa != null)
              SocialMediaLinks(empresa: _empresa!),
            if(_empresa != null)
              const Spacer(),
            if(_empresa != null)
            AutoSizeText(_userName.isNotEmpty ? "$_userName ($_userAccount)" : "", maxLines: 1, minFontSize: 12, style: Theme.of(context).textTheme.bodyMedium?.copyWith(shadows: [Shadow(
                color: Theme.of(context).textTheme.titleSmall!.color!.withOpacity(0.3),
                offset: const Offset(2, 2),
                blurRadius: 10)]),),
            // Text(_userAccount, style: Theme.of(context).textTheme.bodyMedium?.copyWith(shadows: [Shadow(
            //     color: Theme.of(context).textTheme.titleSmall!.color!.withOpacity(0.3),
            //     offset: const Offset(2, 2),
            //     blurRadius: 10)]),),

            Text(_userSucursal, style: Theme.of(context).textTheme.bodyMedium?.copyWith(shadows: [Shadow(
                color: Theme.of(context).textTheme.titleSmall!.color!.withOpacity(0.3),
                offset: const Offset(2, 2),
                blurRadius: 10)]),),
            const SizedBox(height: 10,),
            if(_versionNumber.isNotEmpty)
            Text("Versión: $_versionNumber", style: Theme.of(context).textTheme.bodySmall?.copyWith(shadows: [Shadow(
                color: Theme.of(context).textTheme.titleSmall!.color!.withOpacity(0.3),
                offset: const Offset(3, 3),
                blurRadius: 10)]),)
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
                  child: ImageSlideshow(  children: [
                    Column(
                      children: [
                        const SizedBox(height: 10,),
                        Text("Misión", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center,),
                        const SizedBox(height: 20,),
                        Expanded(
                          child: SingleChildScrollView(scrollDirection: Axis.vertical, child: Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 20.0),
                            child: Text(empresa.mision, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.justify, ),
                          )),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 10,),
                        Text("Visión", style: Theme.of(context).textTheme.titleLarge,textAlign: TextAlign.center, ),
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
