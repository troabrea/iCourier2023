import 'package:easy_localization/easy_localization.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_states.dart';
import '../services/app_events.dart';
import '../services/courier_service.dart';
import '../services/model/login_model.dart';

class CuentasUsuario extends StatefulWidget {
  const CuentasUsuario({super.key, required this.userProfile});

  final UserProfile userProfile;

  @override
  State<CuentasUsuario> createState() => _CuentasUsuarioState();
}

class _CuentasUsuarioState extends State<CuentasUsuario> {
  late Future<List<UserAccount>> _accounts;

  @override
  void initState() {
    super.initState();
    _accounts = GetIt.I<CourierService>().getStoredAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserAccount>>(
      future: _accounts,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return BrandErrorState(onRetry: _reload);
        }
        if (!snapshot.hasData) {
          return const BrandSkeleton();
        }
        final accounts = snapshot.requireData;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (accounts.isEmpty)
              const BrandEmptyState(messageKey: 'sus_cuentas')
            else
              for (final account in accounts)
                Card(
                  child: ListTile(
                    onTap: () => _switchAccount(account),
                    leading: Icon(
                      account.userAccount == widget.userProfile.cuenta
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: Text(account.nombre),
                    subtitle: Text(account.userAccount),
                    trailing: IconButton(
                      tooltip: 'confirme_borrar_cuenta'.tr(),
                      onPressed: () => _confirmDelete(account),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                GetIt.I<Event<LogoutRequested>>().broadcast(LogoutRequested());
              },
              icon: const Icon(Icons.add),
              label: Text('agregar_cuenta'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _reload() {
    setState(() {
      _accounts = GetIt.I<CourierService>().getStoredAccounts();
    });
  }

  Future<void> _switchAccount(UserAccount account) async {
    if (account.userAccount == widget.userProfile.cuenta) {
      return;
    }
    final success =
        await GetIt.I<CourierService>().switchUserAccount(account.userAccount);
    if (!success) {
      return;
    }
    GetIt.I<Event<LoginChanged>>().broadcast(
      LoginChanged(true, account.userAccount, account.nombre),
    );
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _confirmDelete(UserAccount account) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('confirme'.tr()),
            content: Text('confirme_borrar_cuenta'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('no'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('si'.tr()),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    await GetIt.I<CourierService>().removeAccountFromStore(account);
    _reload();
  }
}
