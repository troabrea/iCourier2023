import 'package:app_bar_with_search_switch/app_bar_with_search_switch.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../adicional/adicional.dart';
import '../services/courierService.dart';
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
  final ScrollController controller = ScrollController();
  List<Pregunta> preguntas = <Pregunta>[].toList();
  String searchText = "";
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
            actions: const [
              AppBarSearchButton( ),
              // or
              // IconButton(onPressed: AppBarWithSearchSwitch.of(context)?startSearch, icon: Icon(Icons.search)),
            ],
          );
        },
      ),
      body: BlocProvider(
        create: (context) => PreguntasBloc(
          RepositoryProvider.of<CourierService>(context),
        )..add(LoadApiEvent()),
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
                  BlocProvider.of<PreguntasBloc>(context).add(LoadApiEvent(ignoreCache: true));
                }, child: Center(child: Text("Ha ocurrido un error haga clic para reintentar.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge,)),),
              ));
            }
            if (state is PreguntasLoadedState) {
              preguntas = state.preguntas;
              if(searchText.isNotEmpty) {
                preguntas = preguntas.where((element) => element.titulo.contains(searchText) || element.resumen.contains(searchText)).toList();
              }
              return SafeArea(
                child: Container(
                    padding: const EdgeInsets.fromLTRB(10,10,10,65),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: Theme.of(context).primaryColorDark)
                      ),
                      child: ListView.builder(
                          itemBuilder: (_, index) => ExpansionTile(
                              expandedAlignment: Alignment.centerLeft,
                              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                              title: Row(
                                children: [
                                  // CircleAvatar(child: Text(state.preguntas[index].orden.toStringAsFixed(0)),),
                                  // SizedBox(width: 20,),
                                  Expanded(
                                    child: AutoSizeText(
                                      preguntas[index].titulo,
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
                                        Text(
                                          preguntas[index].resumen,
                                          textAlign: TextAlign.justify,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ],
                                    )),
                              ]),
                          controller: controller,
                          itemCount: preguntas.length),
                    )),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
}