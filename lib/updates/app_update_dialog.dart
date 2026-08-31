import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'app_update_coordinator.dart';

enum AppUpdateAction { later, update }

/// Shows the update prompt and prevents dismissal for required updates.
Future<AppUpdateAction?> showAppUpdateDialog(
  BuildContext context, {
  required AvailableAppUpdate update,
}) =>
    showDialog<AppUpdateAction>(
      context: context,
      barrierDismissible: !update.isRequired,
      useRootNavigator: true,
      builder: (context) => PopScope(
        canPop: !update.isRequired,
        child: AlertDialog(
          title: Text('actualizacion_disponible'.tr()),
          content: Text(
            (update.isRequired
                    ? 'actualizacion_requerida'
                    : 'nueva_version_desea_actualizar')
                .tr(
              args: [update.storeVersion, update.installedVersion],
            ),
          ),
          actions: [
            if (!update.isRequired)
              TextButton(
                onPressed: () => Navigator.of(context).pop(
                  AppUpdateAction.later,
                ),
                child: Text('quizas_despues'.tr()),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                AppUpdateAction.update,
              ),
              child: Text('actualizar'.tr()),
            ),
          ],
        ),
      ),
    );
