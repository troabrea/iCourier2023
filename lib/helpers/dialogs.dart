import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:icourier/services/model/recepcion.dart';
import 'package:intl/intl.dart';

Future<bool> confirmDialog(BuildContext context, String message, String okButtonText, String cancelButtonText) async {
  var dlgResult = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        actionsAlignment: MainAxisAlignment.spaceBetween,
        title: Text('Confirme',
            style: Theme.of(context).textTheme.titleLarge),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => {Navigator.pop(context, true)},
            child: Text(okButtonText),
          ),
          ElevatedButton(
            onPressed: () => {Navigator.pop(context, false)},
            child: Text(cancelButtonText),
          ),
        ]));

  return dlgResult ?? false;
}

Future<String> optionsDialog(BuildContext context, String message, List<String> optionsText) async {
  var dlgResult = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceBetween,
          title: Text('Seleccione',
              style: Theme.of(context).textTheme.titleLarge),
          content: Text(message),
          actions: optionsText.map((e) => ElevatedButton(onPressed: () => {
            Navigator.pop(context,e)
          }, child: Text(e))).toList(),
      )
  );

  return dlgResult ?? "Cancelar";
}

Future<List<String>> domicilioDialog(BuildContext context, String message, String okButtonText, String cancelButtonText, List<Recepcion> disponibles) async {
  var toSend = <Recepcion,String>{};
  toSend.addEntries( disponibles.map((e) => MapEntry(e, "Y")) );

  var dlgResult = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceBetween,
          title: Text(message,
              style: Theme.of(context).textTheme.titleLarge),
          content: SizedBox(height: 300,width: 500,
            child: DisponiblePicker(toSend: toSend, disponibles: disponibles),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => { Navigator.pop(context, DomiclioConfirm(toSend, disponibles)) },
              child: Text(okButtonText),
            ),
            ElevatedButton(
              onPressed: () => {Navigator.pop(context, <String>[].toList())},
              child: Text(cancelButtonText),
            ),
          ]));

  return dlgResult ?? <String>[].toList();
}

List<String> DomiclioConfirm(Map<Recepcion, String> toSend, List<Recepcion> disponibles) {
  var paquetes = <String>[].toList();
  disponibles.forEach((element) {
    if(toSend[element] == "Y") {
      paquetes.add(element.recepcionID);
    }
  });
  return paquetes;
}

class DisponiblePicker extends StatefulWidget {
  const DisponiblePicker({
    Key? key,
    required this.toSend,
    required this.disponibles
  }) : super(key: key);

  final Map<Recepcion, String> toSend;
  final List<Recepcion> disponibles;
  @override
  State<DisponiblePicker> createState() => _DisponiblePickerState();
}

class _DisponiblePickerState extends State<DisponiblePicker> {
  final formatCurrency = NumberFormat.simpleCurrency(locale: "en-US");
  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemCount: widget.disponibles.length,
        itemBuilder: (_, int index) =>
            CheckboxListTile(enabled: false, value: widget.toSend[widget.disponibles[index]] == "Y",
            contentPadding: EdgeInsets.zero,
            title: AutoSizeText(widget.disponibles[index].contenido, maxLines: 1, style: Theme.of(context).textTheme.bodyMedium,),
            subtitle: Row(children: [
              Expanded(child: AutoSizeText(widget.disponibles[index].recepcionID, maxLines: 1, style: Theme.of(context).textTheme.bodyMedium,)),
              const SizedBox(width: 5,),
              AutoSizeText(formatCurrency.format(widget.disponibles[index].montoTotal()), maxLines: 1, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right,)
            ],),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (bool? value) {
              setState(() {
                widget.toSend[widget.disponibles[index]] = value != null && value ? "Y" : "";
              });
            }));
  }
}