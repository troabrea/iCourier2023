import 'package:app_bar_with_search_switch/app_bar_with_search_switch.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/courier_service.dart';
import '../services/model/pregunta.dart';
import 'bloc/preguntas_bloc.dart';

class PreguntasAppBar extends StatefulWidget implements PreferredSizeWidget {
  const PreguntasAppBar({Key? key}) : super(key: key);

  @override
  State<PreguntasAppBar> createState() => _PreguntasAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _PreguntasAppBarState extends State<PreguntasAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Preguntas"),
    );
  }
}

class PreguntasPage extends StatefulWidget {
  const PreguntasPage({Key? key}) : super(key: key);

  @override
  State<PreguntasPage> createState() => _PreguntasPageState();
}

class _PreguntasPageState extends State<PreguntasPage> {
  late ScrollController controller;
  List<Pregunta> preguntas = <Pregunta>[].toList();
  String searchText = "";

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithSearchSwitch(
        fieldHintText: 'Buscar',
        keepAppBarColors: false,
        onChanged: (text) {
          setState(() {
            searchText = text;
          });
        },
        // onSubmitted: (text) {
        //   searchText.value = text;
        // },
        appBarBuilder: (context) {
          return AppBar(
            title: const Text("Preguntas"),
            automaticallyImplyLeading: false,
            leading: BackButton( color: Theme.of(context).appBarTheme.iconTheme?.color),
            actions: [
              IconButton(
                icon: Icon(Icons.whatsapp_rounded,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
                onPressed: ()  {
                  chatWithSucursal();
                },
              ),
              IconButton(onPressed: AppBarWithSearchSwitch.of(context)?.startSearch, icon: Icon(Icons.search, color: Theme.of(context).appBarTheme.foregroundColor,)),
            ],
          );
        },
      ),
      body: BlocProvider(
        create: (context) => PreguntasBloc(
          GetIt.I<CourierService>(),
        )..add(const LoadApiEvent()),
        child: BlocBuilder<PreguntasBloc, PreguntasState>(
          builder: (context, state) {
            if (state is PreguntasLoadingState) {
              return const SafeArea(child: Center(
                child: CircularProgressIndicator(),
              ));
            }
            if(state is PreguntasErrorState) {
              return SafeArea(child: Center(
                child: InkWell(onTap: () {
                  BlocProvider.of<PreguntasBloc>(context).add(const LoadApiEvent(ignoreCache: true));
                }, child: Center(child: Text("Ha ocurrido un error haga clic para reintentar.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge,)),),
              ));
            }
            if (state is PreguntasLoadedState) {
              preguntas = state.preguntas;
              if(searchText.isNotEmpty) {
                preguntas = preguntas.where((element) => element.titulo.toLowerCase().contains(searchText.toLowerCase()) || element.resumen.toLowerCase().contains(searchText.toLowerCase())).toList();
              }
              return SafeArea(
                child: Container(
                    padding: const EdgeInsets.fromLTRB(10,10,10,65),
                    child: _buildListView(context),
              ));
            }
            return Container();
          },
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    return ListView.builder(
                      itemBuilder: (_, index) => Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(color: Theme.of(context).primaryColorDark)),
                              child: ExpansionTile(
                            onExpansionChanged: ( (isExpanded)  => {
                              setState( ()  => {
                                preguntas[index].isExpanded = isExpanded
                              })
                            }),
                            expandedAlignment: Alignment.centerLeft,
                            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                            title: Row(
                              children: [
                                // CircleAvatar(child: Text(state.preguntas[index].orden.toStringAsFixed(0)),),
                                // SizedBox(width: 20,),
                                Expanded(
                                  child: preguntas[index].isExpanded ?
                                    AutoSizeText(
                                    preguntas[index].titulo,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 5,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium!,
                                    )
                                  :
                                  AutoSizeText(
                                    preguntas[index].titulo,
                                    overflow: TextOverflow.ellipsis,
                                    minFontSize: 16,
                                    maxLines: 2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!,
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Container(
                                  padding: const EdgeInsets.only(left: 5,right: 5,bottom: 5),
                                  child: Column(
                                    children: [
                                      const Divider(thickness: 2),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          preguntas[index].resumen,
                                          textAlign: TextAlign.justify,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                    ],
                                  )),
                            ]),
                      ),
                      controller: controller,
                      itemCount: preguntas.length);
  }

  Future<void> chatWithSucursal() async {
    var userProfile = await GetIt.I<CourierService>().getUserProfile();
    var whatsApp = userProfile.whatsappSucursal; // (await GetIt.I<CourierService>().getEmpresa()).telefonoVentas;
    if (whatsApp.isNotEmpty) {
      var _url = Uri.parse("whatsapp://send?phone=$whatsApp");
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    }
  }
}
