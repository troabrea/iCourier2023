import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:get_it/get_it.dart';
import '../../noticas/bloc/noticias_bloc.dart';
import '../../noticas/noticiadetalle.dart';
import '../../services/courierService.dart';
import 'package:intl/intl.dart';
import 'package:event/event.dart' as event;
import '../services/app_events.dart';
import '../services/model/banner.dart';
import '../services/model/noticia.dart';
import 'noticiasappbar.dart';

class NoticiasPage extends StatefulWidget {
  const NoticiasPage({Key? key}) : super(key: key);

  @override
  State<NoticiasPage> createState() => _NoticiasPageState();
}

class _NoticiasPageState extends State<NoticiasPage> {

  final ScrollController controller = ScrollController();
  final noticiasBloc = NoticiasBloc(GetIt.I<CourierService>());
  var lastRefresh = DateTime.now();
  _NoticiasPageState() {
    GetIt.I<event.Event<NoticiasDataRefreshRequested>>().subscribe((args)  {
      if(DateTime.now().difference(lastRefresh).inMinutes >= 5) {
        noticiasBloc.add(LoadApiEvent());
        lastRefresh = DateTime.now();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NoticiasAppBar(),
      body: BlocProvider(
        create: (context) => noticiasBloc..add(LoadApiEvent()),
        child: BlocBuilder<NoticiasBloc, NoticiasState>(
          builder: (context, state) {
            if (state is NoticiasLoadingState) {
              return const SafeArea(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if(state is NoticiasErrorState) {
              return SafeArea(child: Center(
                child: InkWell(onTap: () {
                  BlocProvider.of<NoticiasBloc>(context).add(LoadApiEvent(ignoreCache: true));
                }, child: Center(child: Text("Ha ocurrido un error haga clic para reintentar.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge,)),),
              ));
            }
            if (state is NoticiasLoadedState) {
              return SafeArea(
                child: Container( margin: const EdgeInsets.only(bottom: 65),
                  child: Column(children: [
                    if(state.banners.isNotEmpty)
                      buildSlideShow(context, state.banners),
                    Expanded(child: buildListView(context, state.noticias))
                  ]),
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

  Widget buildSlideShow(BuildContext context, List<BannerImage> banners)
  {
    return ImageSlideshow(height: 145, indicatorRadius: 0, children: banners.map((e) =>
        CachedNetworkImage(
          imageUrl: e.url,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.fill,
              ),
            )),
          progressIndicatorBuilder: (context, url, downloadProgress) =>
              Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),).toList(), autoPlayInterval: 5000, isLoop: true,);
  }

  Widget buildListView(BuildContext context, List<Noticia> noticias) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: ListView.builder(
          itemBuilder: (_, index) => GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: false).push(MaterialPageRoute(
                    builder: (context) =>
                        NoticiaDetallePage(noticia: noticias[index])));
              },
              child: noticiaTile(context, noticias[index])),
          controller: controller,
          itemCount: noticias.length),
    );
  }

  Widget noticiaTile(BuildContext context, Noticia noticia) {
    return Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: Theme.of(context).primaryColorDark)
        ),
        child: Container(
            margin: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(noticia.titulo,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
                Text(DateFormat("dd-MMM-yyyy").format(noticia.fecha),
                    style: Theme.of(context).textTheme.titleSmall),
                Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Text(noticia.resumen,
                        style: Theme.of(context).textTheme.bodyMedium)),

              ],
            )));
  }
}
