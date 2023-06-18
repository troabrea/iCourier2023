import 'package:flutter/material.dart';
import 'package:another_stepper/another_stepper.dart';
import 'package:another_stepper/dto/stepper_data.dart';
import 'package:intl/intl.dart';
import '../../courier/paquete_tile.dart';

import 'package:im_stepper/stepper.dart';

import '../services/model/recepcion.dart';

class HistoricoPaquetePage extends StatefulWidget {
  final Recepcion recepcion;
  const HistoricoPaquetePage({Key? key, required this.recepcion}) : super(key: key);

  @override
  State<HistoricoPaquetePage> createState() => _HistoricoPaquetePageState();
}

class _HistoricoPaquetePageState extends State<HistoricoPaquetePage> {
  late List<Historia> historia;
  late List<StepperData> stepperData;
  bool isLoaded = false;
  @override
  void initState() {
    super.initState();
    setState(() {
      historia = widget.recepcion.paquetes.first.historia;
      historia.sort((a,b) => b.dateTime().compareTo(a.dateTime()));

      isLoaded= true;
    });
  }

  List<StepperData> getStepperData(BuildContext context) {
    return historia.map((e) => StepperData(
        iconWidget: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.all(Radius.circular(24))),
          child: const Icon(Icons.check, color: Colors.white, size: 12,),
        ),
        title: StepperText(e.nombreEstatus, textStyle: Theme.of(context).textTheme.titleMedium),
        subtitle: StepperText(DateFormat("dd-MMM-yyyy").add_jms().format(e.dateTime())))).toList();
  }

  // final List<String> iconosProgreso = <String>['images/recibidomiami.svg','images/embarcado.svg','images/recibido.svg','images/disponible.svg'].toList();
  final List<IconData> iconsProgreso = <IconData>[Icons.warehouse, Icons.airplanemode_active_outlined, Icons.store, Icons.check_circle ].toList();
  final List<String> labelsProgreso = <String>['Origen','En ruta','Destino','Disponible'].toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Historial de Paquete"),
          leading: BackButton( color: Theme.of(context).appBarTheme.iconTheme?.color),
        ),
        body:SafeArea(
            child: !isLoaded ? const CircularProgressIndicator() :  Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 65),
                child: Column(
                  children: [
                    Hero(transitionOnUserGestures: true, tag: widget.recepcion, child: PaqueteTile(recepcion: widget.recepcion)),
                    const SizedBox(height: 10,),
                    IconStepper( lineLength: 20, icons: [
                      Icon(iconsProgreso[0], color: widget.recepcion.progresoActual() == 1 ? Colors.white : Colors.black,),
                      Icon(iconsProgreso[1], color: widget.recepcion.progresoActual() == 2 ? Colors.white : Colors.black,),
                      Icon(iconsProgreso[2], color: widget.recepcion.progresoActual() == 3 ? Colors.white : Colors.black,),
                      Icon(iconsProgreso[3], color: widget.recepcion.progresoActual() == 4 ? Colors.white : Colors.black,),
                    ],  lineColor: Theme.of(context).primaryColorDark, enableNextPreviousButtons: false, enableStepTapping: false, activeStep: widget.recepcion.progresoActual()-1,),
                    const SizedBox(height: 10,),
                    Expanded(
                      child: SingleChildScrollView(
                        child: AnotherStepper(
                        iconWidth: 30,
                        //   titleTextStyle: Theme.of(context).textTheme.titleMedium!,
                        // subtitleTextStyle: Theme.of(context).textTheme.bodySmall!,
                        stepperList: getStepperData(context),
                        stepperDirection: Axis.vertical,
                        iconHeight: 30,
                        verticalGap: 15,
                        // horizontalStepperHeight: 70,
                        //   dotWidget: Container(
                        //     padding: const EdgeInsets.all(2),
                        //     decoration: const BoxDecoration(
                        //         color: Colors.green,
                        //         borderRadius: BorderRadius.all(Radius.circular(30))),
                        //     child: const Icon(Icons.check, color: Colors.white, size: 12,),
                        //   ),
                        // gap: 25,
                        activeBarColor: Colors.green,
                        inActiveBarColor: Colors.grey,
                        activeIndex: 0,
                        barThickness: 3,
    ),
                      ),
                    ),
                  ],
                ))));
  }
}
