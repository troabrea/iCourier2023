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
          onAdd: _logout,
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
    final remaining =
        await GetIt.I<CourierService>().removeAccountFromStore(account);
    // Nothing left to switch to, so there is no session to keep either.
    if (remaining.isEmpty) {
      _logout();
      return;
    }
    _reload();
  }

  /// Signing in with another account and signing out are the same move: both
  /// release the current session and land on the login screen.
  void _logout() {
    if (mounted) {
      context.pop();
    }
    GetIt.I<Event<LogoutRequested>>().broadcast(LogoutRequested());
  }
}
