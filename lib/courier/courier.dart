import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_states.dart';
import '../theme/brand_config.dart';
import 'bloc/courier_bloc.dart';
import 'courier_dashboard.dart';

class CourierPage extends StatefulWidget {
  const CourierPage({super.key});

  @override
  State<CourierPage> createState() => _CourierPageState();
}

class _CourierPageState extends State<CourierPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  late final CourierBloc _bloc;
  late final BrandConfig _config;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _config = GetIt.I<BrandConfig>();
    _bloc = CourierBloc(CourierIsBusyState())..add(CheckLoggedEvent());
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<CourierBloc, CourierState>(
        builder: (context, state) {
          if (state is CourierIsBusyState) {
            return const Scaffold(body: BrandSkeleton(rows: 6));
          }
          if (state is CourierIsLoggedState) {
            return const CourierDashboard();
          }
          final loggedOut = state is CourierIsNotLoggedState ? state : null;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
                    children: [
                      SizedBox(
                        height: 120,
                        child: Image.asset(
                          _config.assets.logoWide,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'bienvenido'.tr(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'indique_credenciales'.tr(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _accountController,
                              textCapitalization: TextCapitalization.characters,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: 'codigo_de_cliente'.tr(),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (value) =>
                                  value?.trim().isEmpty ?? true
                                      ? 'requerido'.tr()
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'contraseña'.tr(),
                                prefixIcon: const Icon(Icons.key_outlined),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'requerido'.tr()
                                  : null,
                              onFieldSubmitted: (_) => _login(),
                            ),
                          ],
                        ),
                      ),
                      if (loggedOut?.showError ?? false) ...[
                        const SizedBox(height: 12),
                        Text(
                          'credenciales_invalidas'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _login,
                        child: Text('iniciar_sesión'.tr()),
                      ),
                      TextButton(
                        onPressed: () => _showPasswordHelp(context),
                        child: Text('lo_olvidaste'.tr()),
                      ),
                      if (loggedOut?.registerUrl.isNotEmpty ?? false)
                        OutlinedButton(
                          onPressed: () => _openRegistration(
                            loggedOut!.registerUrl,
                          ),
                          child: Text('registrate_aqui'.tr()),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _login() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    _bloc.add(
      TryLoginEvent(
        _accountController.text.trim(),
        _passwordController.text,
      ),
    );
  }

  Future<void> _openRegistration(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showPasswordHelp(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('recordar_contraseña'.tr()),
        content: Text('recordar_la_contraseña'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('aceptar'.tr()),
          ),
        ],
      ),
    );
  }
}
