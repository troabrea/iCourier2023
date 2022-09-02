import 'dart:io';
import 'package:flutter_cache/flutter_cache.dart' as cache;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:get_it/get_it.dart';

import 'package:image_picker/image_picker.dart';
import 'package:navbar_router/navbar_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sampleapi/courier/bloc/courier_bloc.dart';
import 'package:sampleapi/preguntas/preguntas.dart';
import 'package:sampleapi/services/courierService.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:event/event.dart' as event;

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

  _AdicionalInfoPageState()
  {
    GetIt.I<event.Event<LoginChanged>>().subscribe((args)  {
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

    final info = await PackageInfo.fromPlatform();
    var account = (await cache.load('userAccount','')).toString();
    var name = (await cache.load('userName','')).toString();


    if (!mounted) return;

    setState(() {
      _versionNumber = info.version;
      _userAccount = account;
      _userName = name;
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
            InkWell(onTap: () {  Navigator.of(context, rootNavigator: false).push(MaterialPageRoute(
                builder: (context) =>
                    const ServiciosPage())); },
                child:  Card(child: ListTile(leading: Icon(Icons.miscellaneous_services, color: Theme.of(context).primaryColorDark), trailing: const Icon(Icons.chevron_right), title: const Text("Servicios"),))),
            InkWell(onTap: () {
              Navigator.of(context, rootNavigator: false).push(MaterialPageRoute(builder: (context)=> const PreguntasPage()));
            }, child:  Card(child: ListTile(leading: Icon(Icons.question_answer, color: Theme.of(context).primaryColorDark ), trailing: const Icon(Icons.chevron_right), title: const Text("Preguntas"),))),
            InkWell(
              onTap: () => {showAboutUs(context)},
              child: Card(child: ListTile(leading: Icon(Icons.info, color: Theme.of(context).primaryColorDark ), trailing:
                const Icon(Icons.expand_circle_down_outlined),
                title: const Text("Sobre Nosotros"),)),
            ),
            Spacer(),
            Text(_userName, style: Theme.of(context).textTheme.titleSmall?.copyWith(shadows: [Shadow(
                color: Theme.of(context).textTheme.titleSmall!.color!.withOpacity(0.3),
                offset: const Offset(3, 3),
                blurRadius: 10)]),),
            Text(_userAccount, style: Theme.of(context).textTheme.titleSmall?.copyWith(shadows: [Shadow(
                color: Theme.of(context).textTheme.titleSmall!.color!.withOpacity(0.3),
                offset: const Offset(3, 3),
                blurRadius: 10)]),),
            const SizedBox(height: 20,),
            Text("Versión: $_versionNumber", style: Theme.of(context).textTheme.titleSmall?.copyWith(shadows: [Shadow(
                color: Theme.of(context).textTheme.titleSmall!.color!.withOpacity(0.3),
                offset: const Offset(3, 3),
                blurRadius: 10)]),)
            ],),
        ),
      ));
  }

  Future<void> openInBrowser(Empresa empresa) async {
    var _url = Uri.parse(empresa.paginaWeb);
    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  Future<void> sendEmail(Empresa empresa) async {
    var email = empresa.correoVentas;
    var _url = Uri.parse("mailto://$email");
    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  Future<void> viewInFacebook(Empresa empresa) async {
    var facebook = empresa.facebook;

    String fbProtocolUrl;
    if (Platform.isIOS) {
      fbProtocolUrl = 'fb://profile/$facebook';
    } else {
      fbProtocolUrl = 'fb://page/$facebook';
    }

    String fallbackUrl = 'https://www.facebook.com/$facebook';

    var _url = Uri.parse(fbProtocolUrl);
    if (!await launchUrl(_url)) {
      _url = Uri.parse(fallbackUrl);
      if(!await launchUrl(_url))
        {
          throw 'Could not launch $_url';
        }
    }
  }

  Future<void> showAboutUs(
      BuildContext context) async {
    var courierService = RepositoryProvider.of<CourierService>(context);
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
                height: 400,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ImageSlideshow(  children: [
                    Column(
                      children: [
                        const SizedBox(height: 10,),
                        Text("Misión", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center,),
                        const SizedBox(height: 20,),
                        SingleChildScrollView(scrollDirection: Axis.vertical, child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: AutoSizeText(empresa.mision, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.justify, maxLines: 12, ),
                        )),
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 10,),
                        Text("Visión", style: Theme.of(context).textTheme.titleLarge,textAlign: TextAlign.center, ),
                        const SizedBox(height: 20,),
                        SingleChildScrollView(scrollDirection: Axis.vertical, child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: AutoSizeText(empresa.vision, style: Theme.of(context).textTheme.titleMedium,textAlign: TextAlign.justify, maxLines: 12,),
                        )),
                      ],
                    ),

                  ]),
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                IconButton(icon: const Icon(Icons.web), onPressed: () => { openInBrowser(empresa) },),
                IconButton(icon: const Icon(Icons.mail), onPressed: () => { sendEmail(empresa) },),
                IconButton(icon: const Icon(Icons.facebook), onPressed: () => { viewInFacebook(empresa) },),
              ],),
              const SizedBox(height: 15),
            ],
          );
        });
    //NavbarNotifier.hideBottomNavBar = false;
    GetIt.I<event.Event<ToogleBarEvent>>().broadcast(ToogleBarEvent(true));
  }
}
