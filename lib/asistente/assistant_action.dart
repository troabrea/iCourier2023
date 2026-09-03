import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../helpers/contact_action.dart';
import '../navigation/app_routes.dart';
import '../navigation/router_session.dart';
import '../services/courier_service.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
import 'assistant_avatar.dart';

/// Header fallback for the contact position the assistant used to occupy.
///
/// This position used to carry the branch WhatsApp on every screen. The
/// assistant now floats above the tab bar. Its former header position is
/// therefore empty while that floating access is available.
///
/// A customer with no session cannot be answered — the webhook resolves their
/// packages from it — so the button falls back to the contact channel it
/// replaced rather than disappearing from the public screens. A courier who
/// does not pay for the module falls back the same way: the position keeps
/// working, it simply leads to a person again.
class BrandAssistantAction extends StatelessWidget {
  const BrandAssistantAction({super.key, this.color});

  /// Defaults to the header foreground.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final session =
        GetIt.I.isRegistered<RouterSession>() ? GetIt.I<RouterSession>() : null;
    final courier = GetIt.I.isRegistered<CourierService>()
        ? GetIt.I<CourierService>()
        : null;
    if (session == null || courier == null) {
      return BrandContactAction(color: color);
    }
    // Both sources can settle after this button is first drawn, so it is built
    // against them rather than against a snapshot of them.
    return ListenableBuilder(
      listenable: Listenable.merge([session, courier.assistantEnabled]),
      builder: (context, _) =>
          session.isLoggedIn && courier.assistantEnabled.value
              ? const SizedBox.shrink()
              : BrandContactAction(color: color),
    );
  }
}

/// Floating assistant access shared by every tab root.
class BrandAssistantFloatingAction extends StatelessWidget {
  const BrandAssistantFloatingAction({super.key});

  @override
  Widget build(BuildContext context) {
    final session =
        GetIt.I.isRegistered<RouterSession>() ? GetIt.I<RouterSession>() : null;
    final courier = GetIt.I.isRegistered<CourierService>()
        ? GetIt.I<CourierService>()
        : null;
    if (session == null || courier == null) {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: Listenable.merge([
        session,
        courier.assistantEnabled,
        courier.assistantSettings,
      ]),
      builder: (context, _) {
        if (!session.isLoggedIn || !courier.assistantEnabled.value) {
          return const SizedBox.shrink();
        }
        final tokens = context.brand;
        final settings = courier.assistantSettings.value;
        final name = settings.displayName(GetIt.I<BrandConfig>().name);
        return FloatingActionButton(
          heroTag: null,
          onPressed: () => context.push(AppRoutes.assistant),
          tooltip: name,
          backgroundColor: tokens.surface,
          foregroundColor: tokens.primary,
          shape: CircleBorder(side: BorderSide(color: tokens.border)),
          clipBehavior: Clip.antiAlias,
          child: AssistantAvatarEntrance(
            child: Hero(
              tag: AssistantAvatar.heroTag,
              child: AssistantAvatar(
                avatarSvg: settings.avatarSvg,
                semanticLabel: name,
                size: 52,
                padding: settings.avatarSvg.isEmpty ? 5 : 1,
              ),
            ),
          ),
        );
      },
    );
  }
}
