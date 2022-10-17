import 'package:auto_size_text/auto_size_text.dart';
import 'package:empty_widget/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/prealertas_bloc.dart';
import '../services/model/prealerta_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PrealertasRealizadas extends StatefulWidget {
  const PrealertasRealizadas({Key? key}) : super(key: key);

  @override
  State<PrealertasRealizadas> createState() => _PrealertasRealizadasState();
}

class _PrealertasRealizadasState extends State<PrealertasRealizadas> {
  late ScrollController controller;
  final prealertasBloc = PrealertasBloc();
  final formatCurrency = NumberFormat.simpleCurrency(locale: "en-US");

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
        appBar: AppBar(
          title: const Text("Pre-Alertas"),
          leading:
              BackButton(color: Theme.of(context).appBarTheme.iconTheme?.color),
        ),
        body: BlocProvider(
            create: (context) => prealertasBloc..add(LoadPreAlertasEvent()),
            child: BlocBuilder<PrealertasBloc, PrealertasState>(
                builder: (context, state) {
              if (state is PrealertasLoadingState) {
                return const SafeArea(
                    child: Center(
                  child: CircularProgressIndicator(),
                ));
              }
              if (state is PrealertasErrorState) {
                return SafeArea(
                    child: Center(
                  child: InkWell(
                    onTap: () {
                      BlocProvider.of<PrealertasBloc>(context)
                          .add(LoadPreAlertasEvent());
                    },
                    child: Center(
                        child: Text(
                      "Ha ocurrido un error haga clic para reintentar.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    )),
                  ),
                ));
              }
              if (state is PrealertasEmptyState) {
                return SafeArea(
                    child: Center(
                      child: InkWell(
                        onTap: () {
                          BlocProvider.of<PrealertasBloc>(context)
                              .add(LoadPreAlertasEvent());
                        },
                        child: Center(
                            child: EmptyWidget(
                              hideBackgroundAnimation: true,
                              title: "No hay resultados",
                              subTitle: "No se encontraron pre-alertas recientes para su cuenta.",
                            )),
                      ),
                    ));
              }
              if (state is PrealertasLoadedState) {
                return SafeArea(
                    child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 65),
                  child: _buildListView(context, state.prealertas),
                ));
              }
              return Container();
            })));
  }

  Widget _buildListView(BuildContext context, List<PreAlertaDto> prealertas) {
    return ListView.builder(
        itemBuilder: (_, index) => Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: Theme.of(context).primaryColorDark)
          ),
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: InkWell(
                onTap: () async {
                  if(prealertas[index].facturaUrl.isNotEmpty)  {
                    try {
                      await launchUrl(Uri.parse(prealertas[index].facturaUrl));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ha ocurrido un error mostrando el documento adjunto.")));
                    }
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(prealertas[index].tracking,),
                        ),
                        if(prealertas[index].facturaUrl.isNotEmpty)
                          Icon(Icons.preview, size: 20, color: Theme.of(context).primaryColor, ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: AutoSizeText(prealertas[index].contenido, maxLines: 1,style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),)),
                        AutoSizeText.rich(
                            TextSpan(
                                text: prealertas[index].fechaEntrega
                            )
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: AutoSizeText(prealertas[index].enviaNombre,  maxLines: 1,)),
                        Text(formatCurrency.format(prealertas[index].fob), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),)
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: AutoSizeText(prealertas[index].agregadoEn,  maxLines: 1,)),
                        const SizedBox(width: 3,),
                        AutoSizeText(prealertas[index].agregadoPor,  maxLines: 1, style: Theme.of(context).textTheme.bodySmall,)
                      ],
                    ),
                  ],
                ),
              )),
        ),
        controller: controller,
        itemCount: prealertas.length);
  }
}
