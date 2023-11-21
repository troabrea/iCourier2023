
import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../services/model/recepcion.dart';

class FacturaTile extends StatelessWidget {
  final Recepcion recepcion;
  final appInfo = GetIt.I<AppInfo>();
  final List<IconData> iconsProgreso = <IconData>[Icons.warehouse, Icons.airplanemode_active_outlined, Icons.store, Icons.check_circle, Icons.motorcycle ].toList();
  final formatCurrency = NumberFormat.simpleCurrency(locale: "en-US");
  final formatDate = DateFormat("dd-MMM-yyyy");
  FacturaTile({Key? key, required this.recepcion}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: Theme.of(context).dividerColor)
            )
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
                    Text(formatCurrency.format(recepcion.montoTotal()), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),),
                    if(recepcion.selected)
                      Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary,),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: AutoSizeText.rich(
                          TextSpan(
                              text: recepcion.totalPeso,
                              children: [
                                TextSpan(text: 'lbs'.tr(), style: Theme.of(context).textTheme.labelSmall)
                              ]
                          )
                      ),
                    ),
                    AutoSizeText(recepcion.fecha,  maxLines: 1, style: Theme.of(context).textTheme.bodySmall,)
                  ],
                ),
              ],
            )),
      ),
    );
  }
}
