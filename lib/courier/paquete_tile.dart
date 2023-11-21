
import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../services/model/recepcion.dart';

class PaqueteTile extends StatelessWidget {
  final Recepcion recepcion;
  final appInfo = GetIt.I<AppInfo>();
  final List<IconData> iconsProgreso = <IconData>[Icons.warehouse, Icons.airplanemode_active_outlined, Icons.store, Icons.check_circle, Icons.motorcycle ].toList();
  final formatCurrency = NumberFormat.simpleCurrency(locale: "en-US");
  final formatDate = DateFormat("dd-MMM-yyyy");
  PaqueteTile({Key? key, required this.recepcion}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: Theme.of(context).dividerColor)
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: recepcion.retenido && !recepcion.disponible ?
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text(recepcion.recepcionID,)),
                          const Icon(Icons.lock_outline, size: 20, color: Colors.red),
                        ],)
                        : Text(recepcion.recepcionID,),
                  ),
                  if(!recepcion.disponible)
                  CircularPercentIndicator(
                    radius: 14.0,
                    lineWidth: 4.0,
                    percent: recepcion.progresoActual() / 4,
                    center: Icon(iconsProgreso[recepcion.progresoActual() -1], size: 16, ),
                    progressColor: Theme.of(context).primaryColor,
                  ),
                  if(recepcion.disponible)
                    Icon(iconsProgreso[recepcion.progresoActual() -1], size: 20, color: Theme.of(context).colorScheme.primary, ),
                  //Icon(iconsProgreso[0], size: 20, color: Theme.of(context).primaryColor,),
                  // if(recepcion.disponible)
                  //   const Icon(Icons.check_circle, size: 20, color: Colors.green,)
                  // else
                  //   if (recepcion.retenido)
                  //     const Icon(Icons.lock_outline, size: 20, color: Colors.red)
                  //   else
                  //     const Icon(Icons.access_time_filled, size: 20)
                ],
              ),
              Row(
                children: [
                  Expanded(child: AutoSizeText(recepcion.contenido, maxLines: 1,style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),)),
                  AutoSizeText.rich(
                      TextSpan(
                          text: recepcion.totalPeso,
                          children: [
                            TextSpan(text: 'lbs'.tr(), style: Theme.of(context).textTheme.labelSmall)
                          ]
                      )
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: AutoSizeText(recepcion.suplidor,  maxLines: 1,)),
                  if(recepcion.disponible)
                    Text(formatCurrency.format(recepcion.montoTotal()), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),)
                ],
              ),
              if(appInfo.metricsPrefixKey == "TLS")
                Row(
                  children: [
                    Expanded(child: AutoSizeText(recepcion.estatus,  maxLines: 2,)),
                    const SizedBox(width: 3,),
                    AutoSizeText(formatDate.format(recepcion.fechaRecibido()),  maxLines: 1, style: Theme.of(context).textTheme.bodySmall,)
                  ],
                ),
              if(appInfo.metricsPrefixKey != "TLS")
              Row(
                children: [
                  Expanded(child: AutoSizeText(recepcion.enviadoPor,  maxLines: 2,)),
                  const SizedBox(width: 3,),
                  AutoSizeText(formatDate.format(recepcion.fechaRecibido()),  maxLines: 1, style: Theme.of(context).textTheme.bodySmall,)
                ],
              ),
            ],
          )),
    );
  }
}
