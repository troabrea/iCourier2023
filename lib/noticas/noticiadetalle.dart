import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/model/noticia.dart';
import 'noticiasappbar.dart';

class NoticiaDetallePage extends StatelessWidget {
  final Noticia? noticia;
  // ignore: use_key_in_widget_constructors
  const NoticiaDetallePage({this.noticia});
  Future<void> _launchUrl() async {
    Uri _url = Uri.parse(noticia!.url);

    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: NoticiasAppBar(showBackButton: true,),
        body: Container( margin: const EdgeInsets.only(bottom: 65),
          child: Stack(children: [
            Container(
                padding: const EdgeInsets.only(left: 10.0),
                decoration: const BoxDecoration(
                  // image: DecorationImage(
                  //   image: AssetImage("images/fondo.png"),
                  //   fit: BoxFit.cover,
                  // ),
                )),
            Column(children: <Widget>[
              const Divider(
                height: 10,
                color: Colors.transparent,
              ),
              Hero( transitionOnUserGestures: true, tag: noticia!.registroId + '_' + noticia!.titulo,
                child: Text(
                  noticia!.titulo,
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(
                height: 10,
                color: Colors.transparent,
              ),
              Hero(transitionOnUserGestures: true, tag: noticia!.registroId + '_' + noticia!.fecha.toString(),
                child: Text(DateFormat("dd-MMM-yyyy").format(noticia!.fecha),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Text(
                          noticia!.contenido.isEmpty ? noticia!.resumen : noticia!.contenido,
                          textAlign: TextAlign.justify,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ))),
              const Divider(
                height: 10,
                color: Colors.transparent,
              ),
              if (noticia!.url.isNotEmpty)
                TextButton(
                    onPressed: () => {_launchUrl()}, child: const Text( 'Ver Mas...'
                    )),
              if (noticia!.url.isNotEmpty)
                const Divider(
                  height: 40,
                  color: Colors.transparent,
                ),
            ]),
          ]),
        ));
  }
}
