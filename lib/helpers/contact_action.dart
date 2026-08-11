import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/courier_service.dart';
import '../services/model/login_model.dart';
import '../theme/brand_tokens.dart';

/// The contact channel configured for an account, if any.
///
/// WhatsApp wins; the brand chat is the fallback when the branch has no
/// number, exactly as the original app bar behaved. Resolving it in one place
/// keeps the icon and the destination from drifting apart between the home
/// header and the tab headers.
({IconData icon, Future<void> Function() open})? resolveContactChannel(
  UserProfile? profile,
) {
  final whatsapp = profile?.whatsappSucursal.trim() ?? '';
  final chat = profile?.chatUrl.trim() ?? '';

  if (whatsapp.isNotEmpty) {
    final normalized = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    return (
      icon: FontAwesomeIcons.whatsapp,
      // wa.me resolves whether or not the app is installed, unlike the
      // whatsapp:// scheme the original used.
      open: () => launchUrl(
            Uri.https('wa.me', '/$normalized'),
            mode: LaunchMode.externalApplication,
          ),
    );
  }

  final uri = Uri.tryParse(chat);
  if (chat.isNotEmpty &&
      uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http')) {
    return (
      icon: FontAwesomeIcons.comment,
      open: () => launchUrl(uri, mode: LaunchMode.externalApplication),
    );
  }
  return null;
}

/// Header action that opens the account's contact channel.
///
/// The original app carried this on every app bar; it is restored here as one
/// self-contained widget so each screen only has to place it. It renders
/// nothing when the account has neither channel.
class BrandContactAction extends StatefulWidget {
  const BrandContactAction({super.key, this.color});

  /// Defaults to the header foreground.
  final Color? color;

  @override
  State<BrandContactAction> createState() => _BrandContactActionState();
}

class _BrandContactActionState extends State<BrandContactAction> {
  late final Future<UserProfile> _profile;

  @override
  void initState() {
    super.initState();
    _profile = GetIt.I<CourierService>().getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _profile,
      builder: (context, snapshot) {
        final channel = resolveContactChannel(snapshot.data);
        if (channel == null) {
          return const SizedBox.shrink();
        }
        return IconButton(
          onPressed: channel.open,
          tooltip: 'escribenos'.tr(),
          icon: FaIcon(
            channel.icon,
            size: 20,
            color: widget.color ?? context.brand.onPrimary,
          ),
        );
      },
    );
  }
}
