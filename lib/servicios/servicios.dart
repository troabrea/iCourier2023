import 'package:app_bar_with_search_switch/app_bar_with_search_switch.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../services/courierService.dart';
import '../services/model/servicio.dart';
import 'bloc/servicios_bloc.dart';

class ServiciosPage extends StatefulWidget {
  const ServiciosPage({Key? key}) : super(key: key);

  @override
  State<ServiciosPage> createState() => _ServiciosPageState();
}

class _ServiciosPageState extends State<ServiciosPage> {

  final ScrollController controller = ScrollController();

  List<Servicio> servicios = <Servicio>[].toList();
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
            title: const Text("Servicios"),
            actions: const [
              AppBarSearchButton(),
              // or
              // IconButton(onPressed: AppBarWithSearchSwitch.of(context)?startSearch, icon: Icon(Icons.search)),
            ],
          );
        },
      ),
      body: BlocProvider(
        create: (context) => ServiciosBloc(
          GetIt.I<CourierService>(),
        )..add(LoadApiEvent()),
        child: BlocBuilder<ServiciosBloc, ServiciosState>(
          builder: (context, state) {
            if (state is ServiciosLoadingState) {
              return const SafeArea(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (state is ServiciosLoadedState) {
              servicios = state.servicios;
              if(searchText.isNotEmpty) {
                servicios = servicios.where((element) => element.titulo.contains(searchText) || element.resumen.contains(searchText)).toList();
              }
              return SafeArea(
                child: Container(
                    padding: const EdgeInsets.fromLTRB(5,10,5,65),
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
                                      // CircleAvatar(child: Text(state.servicios[index].orden.toStringAsFixed(0)),),
                                      // Text(state.servicios[index].orden.toStringAsFixed(0), style: Theme.of(context).textTheme.titleLarge,),
                                      // const SizedBox(width: 10,),
                                      Expanded(
                                        child: AutoSizeText(
                                          servicios[index].titulo,
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
                                              servicios[index].resumen,
                                              textAlign: TextAlign.justify,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ],
                                        )),
                                  ]),
                          controller: controller,
                          itemCount: servicios.length),
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
