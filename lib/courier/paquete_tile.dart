import 'dart:isolate';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/model/recepcion.dart';

class PaqueteTile extends StatelessWidget {
  final Recepcion recepcion;
  final formatCurrency = NumberFormat.simpleCurrency(locale: "en-US");
  final formatDate = DateFormat("dd-MMM-yyyy");
  PaqueteTile({Key? key, required this.recepcion}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: Theme.of(context).primaryColorDark)
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(recepcion.estatus,
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if(recepcion.disponible)
                    const Icon(Icons.check_circle, size: 20, color: Colors.green,)
                  else
                    if (recepcion.retenido)
                      const Icon(Icons.lock_outline, size: 20, color: Colors.red)
                    else
                      const Icon(Icons.access_time_filled, size: 20)
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text(recepcion.recepcionID)),
                  if(recepcion.disponible)
                    Text(formatCurrency.format(recepcion.montoTotal()), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),)
                ],
              ),
              Row(
                children: [
                  Expanded(child: AutoSizeText(recepcion.contenido,  maxLines: 1,)),
                  AutoSizeText.rich(
                    TextSpan(
                      text: recepcion.totalPeso,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(text: 'lbs.', style: Theme.of(context).textTheme.labelSmall)
                      ]
                    )
                  )
                ],
              ),
              Row(
                children: [
                  Expanded(child: AutoSizeText(recepcion.enviadoPor,  maxLines: 1,)),
                  const SizedBox(width: 3,),
                  AutoSizeText(formatDate.format(recepcion.fechaRecibido()),  maxLines: 1, style: Theme.of(context).textTheme.bodySmall,)
                ],
              ),
            ],
          )),
    );
  }
}
