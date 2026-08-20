import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../design_system/brand_foundations.dart';
import '../helpers/contact_action.dart';
import '../navigation/app_routes.dart';
import '../navigation/router_session.dart';
import '../theme/brand_tokens.dart';

/// Header action that opens the assistant.
///
/// This position used to carry the branch WhatsApp on every screen. The
/// assistant answers the same questions without leaving the app, so it takes
/// the position and WhatsApp moves one tap deeper, to the assistant's own
/// header.
///
/// A customer with no session cannot be answered — the webhook resolves their
/// packages from it — so the button falls back to the contact channel it
/// replaced rather than disappearing from the public screens.
class BrandAssistantAction extends StatelessWidget {
  const BrandAssistantAction({super.key, this.color});

  /// Defaults to the header foreground.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final session = GetIt.I.isRegistered<RouterSession>()
        ? GetIt.I<RouterSession>()
        : null;
    if (session == null) {
      return BrandContactAction(color: color);
    }
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => session.isLoggedIn
          ? _AssistantButton(color: color)
          : BrandContactAction(color: color),
    );
  }
}

class _AssistantButton extends StatelessWidget {
  const _AssistantButton({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () => context.push(AppRoutes.assistant),
        tooltip: 'asistente'.tr(),
        icon: BrandGlyph(
          BrandIcons.assistant,
          color: color ?? context.brand.onPrimary,
          size: 22,
        ),
      );
}
