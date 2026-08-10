import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_states.dart';
import '../design_system/overlay_components.dart';
import '../services/app_events.dart';
import '../services/courier_service.dart';
import '../services/model/login_model.dart';

/// Linked accounts, presented with the same switcher the brand header opens.
///
/// It renders as a sheet body, so the route and the header entry point share
/// one implementation instead of drifting apart.
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
          return const BrandSkeleton(rows: 3);
        }
        return AccountSwitcher(
          accounts: snapshot.requireData,
          activeAccount: widget.userProfile.cuenta,
          onSelect: _switchAccount,
          onDelete: _delete,
          onAdd: _addAccount,
          onLogout: _logout,
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

  Future<void> _delete(UserAccount account) async {
    await GetIt.I<CourierService>().removeAccountFromStore(account);
    _reload();
  }

  /// Adding an account means signing in with it, so the session is released.
  void _addAccount() {
    GetIt.I<Event<LogoutRequested>>().broadcast(LogoutRequested());
  }

  void _logout() {
    GetIt.I<Event<LogoutRequested>>().broadcast(LogoutRequested());
  }
}
