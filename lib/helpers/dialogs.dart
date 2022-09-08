import 'package:flutter/material.dart';

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