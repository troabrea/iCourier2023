import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_foundations.dart';
import '../services/model/empresa.dart';
import '../services/model/login_model.dart';
import '../theme/brand_tokens.dart';

const _xOptionKey = 'RedSocialX';
const _linkedInOptionKey = 'RedSocialLinkedIn';

/// Row of brand contact channels.
///
/// These use icon-font marks rather than the repository SVGs: the social
/// artwork is drawn as a white knockout over a solid shape, so tinting it with
/// a token would flatten each one into a filled circle.
class SocialMediaLinks extends StatelessWidget {
  const SocialMediaLinks({
    super.key,
    required this.empresa,
    required this.userProfile,
    this.iconSize = 24,
  });

  final Empresa empresa;
  final UserProfile userProfile;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final socialOptions = _SocialOptions.parse(empresa.options);
    final links = <({IconData icon, String label, VoidCallback onTap})>[
      if (empresa.paginaWeb.isNotEmpty)
        (
          icon: FontAwesomeIcons.globe,
          label: empresa.paginaWeb,
          onTap: () => _open(Uri.tryParse(empresa.paginaWeb)),
        ),
      if (empresa.correoVentas.isNotEmpty || userProfile.email.isNotEmpty)
        (
          icon: FontAwesomeIcons.envelope,
          label: 'email',
          onTap: _sendEmail,
        ),
      if (empresa.instagram.isNotEmpty)
        (
          icon: FontAwesomeIcons.instagram,
          label: 'Instagram',
          onTap: () => _open(
                Uri.https('www.instagram.com', '/${empresa.instagram}'),
              ),
        ),
      if (empresa.facebook.isNotEmpty)
        (
          icon: FontAwesomeIcons.facebook,
          label: 'Facebook',
          onTap: () => _openFacebook(empresa.facebook),
        ),
      if (socialOptions.xUrl != null)
        (
          icon: FontAwesomeIcons.xTwitter,
          label: 'X',
          onTap: () => _openSocial(socialOptions.xUrl!),
        ),
      if (socialOptions.linkedInUrl != null)
        (
          icon: FontAwesomeIcons.linkedinIn,
          label: 'LinkedIn',
          onTap: () => _openSocial(socialOptions.linkedInUrl!),
        ),
    ];

    if (links.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final link in links)
          Semantics(
            button: true,
            label: link.label,
            child: InkResponse(
              onTap: link.onTap,
              radius: 28,
              child: Padding(
                padding: const EdgeInsets.all(BrandSpace.sm),
                child: FaIcon(
                  link.icon,
                  color: tokens.primary,
                  size: iconSize,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _sendEmail() async {
    final address = userProfile.emailSucursal.isEmpty
        ? empresa.correoVentas
        : userProfile.emailSucursal;
    if (address.isEmpty) {
      return;
    }
    await _open(Uri(scheme: 'mailto', path: address));
  }

  Future<void> _openFacebook(String page) async {
    final scheme = Platform.isIOS ? 'fb://profile/$page' : 'fb://page/$page';
    final app = Uri.tryParse(scheme);
    if (app != null && await canLaunchUrl(app)) {
      await launchUrl(app);
      return;
    }
    await _open(Uri.https('www.facebook.com', '/$page'));
  }

  Future<void> _openSocial(Uri uri) async {
    try {
      final openedInApp = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (openedInApp) {
        return;
      }
    } on PlatformException {
      // No installed app claimed the universal link; use the web fallback.
    }
    await _open(uri);
  }

  Future<void> _open(Uri? uri) async {
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final class _SocialOptions {
  const _SocialOptions({this.xUrl, this.linkedInUrl});

  factory _SocialOptions.parse(String rawOptions) {
    if (rawOptions.trim().isEmpty) {
      return const _SocialOptions();
    }

    Object? decoded;
    try {
      decoded = jsonDecode(rawOptions);
    } on FormatException {
      return const _SocialOptions();
    }
    if (decoded is! Map) {
      return const _SocialOptions();
    }

    final xAccount = _readSlug(decoded[_xOptionKey], _xAccountPattern);
    final linkedInPage = _readSlug(
      decoded[_linkedInOptionKey],
      _linkedInPagePattern,
    );
    return _SocialOptions(
      xUrl: xAccount.isEmpty ? null : Uri.https('x.com', '/$xAccount'),
      linkedInUrl: linkedInPage.isEmpty
          ? null
          : Uri.https('www.linkedin.com', '/company/$linkedInPage'),
    );
  }

  final Uri? xUrl;
  final Uri? linkedInUrl;

  static final _xAccountPattern = RegExp(r'^[A-Za-z0-9_]{1,15}$');
  static final _linkedInPagePattern = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9-]*$',
  );

  static String _readSlug(Object? value, RegExp pattern) {
    if (value is! String || value.trim().isEmpty) {
      return '';
    }
    final slug = value.trim();
    return pattern.hasMatch(slug) ? slug : '';
  }
}
