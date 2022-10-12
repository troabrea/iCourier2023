import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:another_stepper/another_stepper.dart';
import 'package:another_stepper/dto/stepper_data.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:progress_stepper/progress_stepper.dart';
import '../../courier/paquete_tile.dart';

import 'package:im_stepper/stepper.dart';

import '../services/model/recepcion.dart';

class HistoricoPaquetePage extends StatelessWidget {
  final Recepcion recepcion;
  late List<Historia> historia;
  // final List<String> iconosProgreso = <String>['images/recibidomiami.svg','images/embarcado.svg','images/recibido.svg','images/disponible.svg'].toList();
  final List<IconData> iconsProgreso = <IconData>[Icons.warehouse, Icons.airplanemode_active_outlined, Icons.store, Icons.check_circle ].toList();
  final List<String> labelsProgreso = <String>['Origen','En ruta','Destino','Disponible'].toList();
  final formatDate = DateFormat("dd-MMM-yyyy HH:mm:ss");
  late List<StepperData> stepperData;
  HistoricoPaquetePage({Key? key, required this.recepcion}) : super(key: key)
  {
    historia = recepcion.paquetes.first.historia;
    historia.sort((a,b) => b.dateTime().compareTo(a.dateTime()));
    stepperData = historia.map((e) => StepperData(title: e.nombreEstatus, subtitle: formatDate.format(e.dateTime()))).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Historial de Paquete"),
          leading: BackButton( color: Theme.of(context).appBarTheme.iconTheme?.color),
        ),
        body: SafeArea(
            child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 65),
                child: Column(
                  children: [
                    Hero(transitionOnUserGestures: true, tag: recepcion, child: PaqueteTile(recepcion: recepcion)),
                    const SizedBox(height: 10,),
                    IconStepper( lineLength: 20, icons: [
                      Icon(iconsProgreso[0], color: recepcion.progresoActual() == 1 ? Colors.white : Colors.black,),
                      Icon(iconsProgreso[1], color: recepcion.progresoActual() == 2 ? Colors.white : Colors.black,),
                      Icon(iconsProgreso[2], color: recepcion.progresoActual() == 3 ? Colors.white : Colors.black,),
                      Icon(iconsProgreso[3], color: recepcion.progresoActual() == 4 ? Colors.white : Colors.black,),
                    ],  lineColor: Theme.of(context).primaryColorDark, enableNextPreviousButtons: false, enableStepTapping: false, activeStep: recepcion.progresoActual()-1,),
                    const SizedBox(height: 10,),
                    Expanded(
                      child: AnotherStepper(
                        titleTextStyle: Theme.of(context).textTheme.titleMedium!,
                      subtitleTextStyle: Theme.of(context).textTheme.bodySmall!,
                      stepperList: stepperData,
                      stepperDirection: Axis.vertical,
                      horizontalStepperHeight: 70,
                        dotWidget: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.all(Radius.circular(30))),
                          child: const Icon(Icons.check, color: Colors.white, size: 12,),
                        ),
                      gap: 25,
                      activeBarColor: Colors.green,
                      inActiveBarColor: Colors.grey,
                      activeIndex: 0,
                      barThickness: 3,
    ),
                    ),
                  ],
                ))));
  }
}
