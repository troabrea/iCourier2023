import 'package:event/event.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../adicional/appbrowser.dart';
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
  late Future<_AccountSwitcherData> _data;

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AccountSwitcherData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return BrandErrorState(onRetry: _reload);
        }
        if (!snapshot.hasData) {
          return const BrandSkeleton(rows: 3);
        }
        final data = snapshot.requireData;
        return AccountSwitcher(
          accounts: data.accounts,
          activeAccount: widget.userProfile.cuenta,
          onSelect: _switchAccount,
          onEdit: data.canEditProfile ? _editProfile : null,
          onDelete: _delete,
          onAdd: _logout,
        );
      },
    );
  }

  Future<_AccountSwitcherData> _loadData() async {
    final service = GetIt.I<CourierService>();
    final accounts = service.getStoredAccounts();
    final canEditProfile = service.canEditProfile();
    return _AccountSwitcherData(
      accounts: await accounts,
      canEditProfile: await canEditProfile,
    );
  }

  void _reload() {
    setState(() {
      _data = _loadData();
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

  Future<void> _editProfile(UserAccount account) async {
    if (account.userAccount != widget.userProfile.cuenta) {
      return;
    }

    final uri = await GetIt.I<CourierService>().getProfileEditUri();
    if (!mounted || uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_se_pudo_abrir_enlace'.tr())),
        );
      }
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    Navigator.of(context).pop();
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AppBrowser(
          initialUrl: uri.toString(),
          title: 'editar_perfil'.tr(),
        ),
      ),
    );
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

final class _AccountSwitcherData {
  const _AccountSwitcherData({
    required this.accounts,
    required this.canEditProfile,
  });

  final List<UserAccount> accounts;
  final bool canEditProfile;
}
