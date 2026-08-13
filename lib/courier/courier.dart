import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/motion_components.dart';
import '../design_system/overlay_components.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
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
    final tokens = context.brand;
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<CourierBloc, CourierState>(
        builder: (context, state) {
          if (state is CourierIsBusyState) {
            return Scaffold(
              backgroundColor: tokens.bg,
              body: const BrandSkeleton(rows: 6),
            );
          }
          if (state is CourierIsLoggedState) {
            return const CourierDashboard();
          }
          final loggedOut = state is CourierIsNotLoggedState ? state : null;
          return Scaffold(
            backgroundColor: tokens.bg,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: BrandManifestReveal(
                    duration: const Duration(milliseconds: 760),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: BrandSpace.xxl,
                      ),
                      children: [
                        _BrandMark(config: _config),
                        const SizedBox(height: 28),
                        Text('bienvenido'.tr(), style: tokens.head(18)),
                        const SizedBox(height: BrandSpace.xxs),
                        Text(
                          'indique_credenciales'.tr(),
                          style: tokens.body(13, color: tokens.textMuted),
                        ),
                        const SizedBox(height: BrandSpace.md),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _LoginField(
                                controller: _accountController,
                                hint: 'codigo_de_cliente'.tr(),
                                capitalize: true,
                              ),
                              const SizedBox(height: 10),
                              _LoginField(
                                controller: _passwordController,
                                hint: 'contraseña'.tr(),
                                obscure: _obscurePassword,
                                onSubmitted: (_) => _login(),
                                suffix: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 18,
                                    color: tokens.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (loggedOut?.showError ?? false) ...[
                          const SizedBox(height: BrandSpace.xs),
                          Text(
                            'credenciales_invalidas'.tr(),
                            style: tokens.body(
                              12,
                              weight: FontWeight.w600,
                              color: tokens.danger,
                            ),
                          ),
                        ],
                        const SizedBox(height: BrandSpace.xs),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => _showPasswordHelp(context),
                            child: Text(
                              'lo_olvidaste'.tr(),
                              style: tokens.body(
                                12,
                                weight: FontWeight.w600,
                                color: tokens.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: BrandSpace.md),
                        BrandPrimaryButton(
                          label: 'iniciar_sesión'.tr(),
                          fontSize: 15,
                          verticalPadding: 14,
                          onPressed: _login,
                        ),
                        if (loggedOut?.registerUrl.isNotEmpty ?? false) ...[
                          const SizedBox(height: 14),
                          _RegisterPrompt(
                            onTap: () => _openRegistration(
                              loggedOut!.registerUrl,
                            ),
                          ),
                        ],
                      ],
                    ),
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
    await showBrandSheet<void>(
      context,
      child: BrandSheet(
        title: 'recordar_contraseña'.tr(),
        subtitle: 'recordar_la_contraseña'.tr(),
        children: [
          BrandPrimaryButton(
            label: 'aceptar'.tr(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Brand logo, name and tagline stacked above the credentials form.
class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.config});

  final BrandConfig config;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Column(
      children: [
        if (config.assets.logoWide.isEmpty)
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.primary,
              borderRadius: BorderRadius.circular(tokens.radiusLg),
            ),
            child: Text(
              config.name.characters.first.toUpperCase(),
              style: tokens.head(26, color: tokens.onAccent(tokens.primary)),
            ),
          )
        else
          SizedBox(
            height: 96,
            child: Image.asset(config.assets.logoWide, fit: BoxFit.contain),
          ),
        const SizedBox(height: BrandSpace.xs),
        Text(config.name, style: tokens.head(22)),
        if (config.tagline.isNotEmpty) ...[
          const SizedBox(height: BrandSpace.xxs),
          Text(
            config.tagline,
            textAlign: TextAlign.center,
            style: tokens.body(12, color: tokens.textMuted),
          ),
        ],
      ],
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.capitalize = false,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool capitalize;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      autocorrect: !capitalize,
      textCapitalization:
          capitalize ? TextCapitalization.characters : TextCapitalization.none,
      style: tokens.body(14, weight: FontWeight.w500),
      onFieldSubmitted: onSubmitted,
      validator: (value) =>
          (value?.trim().isEmpty ?? true) ? 'requerido'.tr() : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: tokens.body(
          14,
          weight: FontWeight.w500,
          color: tokens.textMuted,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: tokens.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          borderSide: BorderSide(color: tokens.primary, width: 2),
        ),
      ),
    );
  }
}

class _RegisterPrompt extends StatelessWidget {
  const _RegisterPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return GestureDetector(
      onTap: onTap,
      child: Text.rich(
        TextSpan(
          text: 'no_eres_cliente'.tr(),
          style: tokens.body(13, color: tokens.textMuted),
          children: [
            TextSpan(
              text: 'conoce_mas_aqui'.tr(),
              style: tokens.body(
                13,
                weight: FontWeight.w700,
                color: tokens.primary,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
