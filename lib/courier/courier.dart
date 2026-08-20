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
  final _accountFocus = FocusNode();
  final _passwordFocus = FocusNode();
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
    _accountFocus.dispose();
    _passwordFocus.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<CourierBloc, CourierState>(
          builder: (context, state) {
            if (state is CourierIsLoggedState) {
              return const CourierDashboard();
            }
            if (state is CourierIsBusyState) {
              return _LoginLoadingScreen(config: _config);
            }

            final loggedOut = state is CourierIsNotLoggedState ? state : null;
            final submitting = state is CourierIsSubmittingState ? state : null;
            return _LoginScreen(
              config: _config,
              formKey: _formKey,
              accountController: _accountController,
              passwordController: _passwordController,
              accountFocus: _accountFocus,
              passwordFocus: _passwordFocus,
              obscurePassword: _obscurePassword,
              isSubmitting: submitting != null,
              showError: loggedOut?.showError ?? false,
              registerUrl:
                  loggedOut?.registerUrl ?? submitting?.registerUrl ?? '',
              onTogglePassword: () => setState(
                () => _obscurePassword = !_obscurePassword,
              ),
              onLogin: _login,
              onPasswordHelp: () => _showPasswordHelp(context),
              onRegister: _openRegistration,
            );
          },
        ),
      );

  void _login() {
    FocusManager.instance.primaryFocus?.unfocus();
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

class _LoginScreen extends StatelessWidget {
  const _LoginScreen({
    required this.config,
    required this.formKey,
    required this.accountController,
    required this.passwordController,
    required this.accountFocus,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.showError,
    required this.registerUrl,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onPasswordHelp,
    required this.onRegister,
  });

  final BrandConfig config;
  final GlobalKey<FormState> formKey;
  final TextEditingController accountController;
  final TextEditingController passwordController;
  final FocusNode accountFocus;
  final FocusNode passwordFocus;
  final bool obscurePassword;
  final bool isSubmitting;
  final bool showError;
  final String registerUrl;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onPasswordHelp;
  final ValueChanged<String> onRegister;

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        body: _LoginFrame(
          config: config,
          child: BrandManifestReveal(
            duration: const Duration(milliseconds: 420),
            child: _LoginPanel(
              formKey: formKey,
              accountController: accountController,
              passwordController: passwordController,
              accountFocus: accountFocus,
              passwordFocus: passwordFocus,
              obscurePassword: obscurePassword,
              isSubmitting: isSubmitting,
              showError: showError,
              registerUrl: registerUrl,
              onTogglePassword: onTogglePassword,
              onLogin: onLogin,
              onPasswordHelp: onPasswordHelp,
              onRegister: onRegister,
            ),
          ),
        ),
      );
}

class _LoginLoadingScreen extends StatelessWidget {
  const _LoginLoadingScreen({required this.config});

  final BrandConfig config;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Scaffold(
      body: _LoginFrame(
        config: config,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            boxShadow: BrandElevation.card,
          ),
          child: const Padding(
            padding: EdgeInsets.all(BrandSpace.xl),
            child: BrandSkeleton(rows: 4),
          ),
        ),
      ),
    );
  }
}

class _LoginFrame extends StatelessWidget {
  const _LoginFrame({required this.config, required this.child});

  final BrandConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return ColoredBox(
      color: tokens.bg,
      child: Stack(
        children: [
          Positioned.fill(child: _LoginBackground(tokens: tokens)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  BrandSpace.lg,
                  BrandSpace.lg,
                  BrandSpace.lg,
                  BrandSpace.xxl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - BrandSpace.xxl * 2,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BrandMark(config: config),
                          const SizedBox(height: BrandSpace.lg),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground({required this.tokens});

  final BrandTokens tokens;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tokens.primary,
                    tokens.headerGradientEnd,
                    tokens.bg,
                  ],
                  stops: const [0, 0.34, 0.62],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 330,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ParcelRoutePainter(color: tokens.onPrimary),
              ),
            ),
          ),
        ],
      );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.config});

  final BrandConfig config;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final brandAsset = config.assets.logoMark.isNotEmpty
        ? config.assets.logoMark
        : config.assets.logoWide;
    return Semantics(
      label: config.name,
      header: true,
      child: Column(
        children: [
          Container(
            width: 116,
            height: 96,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.logoBackdrop,
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              boxShadow: BrandElevation.dock,
            ),
            child: brandAsset.isEmpty
                ? Center(
                    child: Text(
                      config.name.characters.first.toUpperCase(),
                      style: tokens.head(34, color: tokens.primary),
                    ),
                  )
                : Image.asset(brandAsset, fit: BoxFit.contain),
          ),
          const SizedBox(height: BrandSpace.sm),
          ExcludeSemantics(
            child: Text(
              config.name,
              textAlign: TextAlign.center,
              style: tokens.head(22, color: tokens.onPrimary, height: 1.1),
            ),
          ),
          if (config.tagline.isNotEmpty) ...[
            const SizedBox(height: BrandSpace.xxs),
            Text(
              config.tagline,
              textAlign: TextAlign.center,
              style: tokens.body(
                12,
                color: tokens.onPrimary.withValues(alpha: 0.86),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.formKey,
    required this.accountController,
    required this.passwordController,
    required this.accountFocus,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.showError,
    required this.registerUrl,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onPasswordHelp,
    required this.onRegister,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController accountController;
  final TextEditingController passwordController;
  final FocusNode accountFocus;
  final FocusNode passwordFocus;
  final bool obscurePassword;
  final bool isSubmitting;
  final bool showError;
  final String registerUrl;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onPasswordHelp;
  final ValueChanged<String> onRegister;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        boxShadow: BrandElevation.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BrandSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('bienvenido'.tr(), style: tokens.head(24)),
            ),
            const SizedBox(height: BrandSpace.xs),
            Text(
              'indique_credenciales'.tr(),
              style: tokens.body(
                14,
                color: tokens.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: BrandSpace.xl),
            Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  _LoginField(
                    key: const Key('login-account-field'),
                    controller: accountController,
                    focusNode: accountFocus,
                    label: 'codigo_de_cliente'.tr(),
                    prefixIcon: Icons.person_outline_rounded,
                    capitalize: true,
                    enabled: !isSubmitting,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    onSubmitted: (_) => passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: BrandSpace.sm),
                  _LoginField(
                    key: const Key('login-password-field'),
                    controller: passwordController,
                    focusNode: passwordFocus,
                    label: 'contraseña'.tr(),
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: obscurePassword,
                    enabled: !isSubmitting,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => isSubmitting ? null : onLogin(),
                    suffix: IconButton(
                      onPressed: isSubmitting ? null : onTogglePassword,
                      tooltip: (obscurePassword
                              ? 'mostrar_contraseña'
                              : 'ocultar_contraseña')
                          .tr(),
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showError) ...[
              const SizedBox(height: BrandSpace.sm),
              _LoginError(message: 'credenciales_invalidas'.tr()),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isSubmitting ? null : onPasswordHelp,
                child: Text(_cleanPrompt('lo_olvidaste'.tr())),
              ),
            ),
            const SizedBox(height: BrandSpace.sm),
            _LoginButton(isLoading: isSubmitting, onPressed: onLogin),
            if (registerUrl.isNotEmpty) ...[
              const SizedBox(height: BrandSpace.sm),
              _RegisterPrompt(onTap: () => onRegister(registerUrl)),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.prefixIcon,
    required this.enabled,
    required this.textInputAction,
    this.autofillHints,
    this.obscure = false,
    this.capitalize = false,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData prefixIcon;
  final bool enabled;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscure;
  final bool capitalize;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final radius = BorderRadius.circular(tokens.radiusSm);
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: autofillHints,
      textCapitalization:
          capitalize ? TextCapitalization.characters : TextCapitalization.none,
      textInputAction: textInputAction,
      style: tokens.body(15, weight: FontWeight.w500),
      onFieldSubmitted: onSubmitted,
      validator: (value) =>
          (value?.trim().isEmpty ?? true) ? 'requerido'.tr() : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: tokens.body(14, color: tokens.textMuted),
        floatingLabelStyle: tokens.body(
          13,
          weight: FontWeight.w600,
          // The outline carries the brand focus color. The floating label sits
          // on the panel surface, so its foreground must resolve against that
          // surface instead of inheriting a potentially low-contrast primary.
          color: tokens.text,
        ),
        prefixIcon: Icon(prefixIcon, size: 21),
        suffixIcon: suffix,
        filled: true,
        fillColor: enabled ? tokens.surfaceAlt : tokens.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BrandSpace.md,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: tokens.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: tokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: tokens.danger, width: 2),
        ),
      ),
    );
  }
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Semantics(
      key: const Key('login-error'),
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.accentWash(tokens.danger, 0.09),
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
        child: Padding(
          padding: const EdgeInsets.all(BrandSpace.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, color: tokens.danger, size: 20),
              const SizedBox(width: BrandSpace.xs),
              Expanded(
                child: Text(
                  message,
                  style: tokens.body(
                    13,
                    weight: FontWeight.w600,
                    color: tokens.danger,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return SizedBox(
      height: 52,
      child: FilledButton(
        key: const Key('login-submit-button'),
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onAccent(tokens.primary),
          disabledBackgroundColor: tokens.primary.withValues(alpha: 0.72),
          disabledForegroundColor: tokens.onAccent(tokens.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusSm),
          ),
          textStyle: tokens.body(15, weight: FontWeight.w700),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? Row(
                  key: const ValueKey('login-loading'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tokens.onAccent(tokens.primary),
                      ),
                    ),
                    const SizedBox(width: BrandSpace.sm),
                    Flexible(
                      child: Text(
                        'verificando_credenciales'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Text(
                  'iniciar_sesión'.tr(),
                  key: const ValueKey('login-idle'),
                ),
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
    final intro = _cleanPrompt('no_eres_cliente'.tr());
    final action = 'conoce_mas_aqui'.tr();
    return Semantics(
      button: true,
      label: '$intro $action',
      child: TextButton(
        onPressed: onTap,
        child: ExcludeSemantics(
          child: Text.rich(
            TextSpan(
              text: '$intro ',
              style: tokens.body(13, color: tokens.textMuted),
              children: [
                TextSpan(
                  text: action,
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
        ),
      ),
    );
  }
}

class _ParcelRoutePainter extends CustomPainter {
  const _ParcelRoutePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final route = Path()
      ..moveTo(-18, size.height * 0.28)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.05,
        size.width * 0.48,
        size.height * 0.56,
        size.width * 0.78,
        size.height * 0.24,
      )
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.08,
        size.width + 24,
        size.height * 0.2,
      );
    final routePaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final metric in route.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 8).clamp(0, metric.length)),
          routePaint,
        );
        distance += 15;
      }
    }

    final nodePaint = Paint()..color = color.withValues(alpha: 0.16);
    canvas
      ..drawCircle(Offset(size.width * 0.16, 36), 72, nodePaint)
      ..drawCircle(Offset(size.width * 0.92, 196), 94, nodePaint)
      ..drawCircle(
        Offset(size.width * 0.2, size.height * 0.22),
        4,
        Paint()..color = color.withValues(alpha: 0.72),
      )
      ..drawCircle(
        Offset(size.width * 0.78, size.height * 0.24),
        4,
        Paint()..color = color.withValues(alpha: 0.72),
      );
  }

  @override
  bool shouldRepaint(_ParcelRoutePainter oldDelegate) =>
      oldDelegate.color != color;
}

String _cleanPrompt(String value) =>
    value.replaceFirst(RegExp(r'\s*-\s*$'), '').trim();
