import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/brand_foundations.dart';
import '../services/model/empresa.dart';
import '../services/model/login_model.dart';
import '../theme/brand_tokens.dart';

/// Row of brand contact channels, rendered with the repository glyphs tinted
/// by a token rather than a fixed-colour icon font.
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
    final links = <({String glyph, String label, VoidCallback onTap})>[
      if (empresa.paginaWeb.isNotEmpty)
        (
          glyph: BrandIcons.website,
          label: empresa.paginaWeb,
          onTap: () => _open(Uri.tryParse(empresa.paginaWeb)),
        ),
      if (empresa.correoVentas.isNotEmpty || userProfile.email.isNotEmpty)
        (
          glyph: BrandIcons.email,
          label: 'email',
          onTap: _sendEmail,
        ),
      if (empresa.instagram.isNotEmpty)
        (
          glyph: BrandIcons.instagram,
          label: 'Instagram',
          onTap: () => _open(
            Uri.https('www.instagram.com', '/${empresa.instagram}'),
          ),
        ),
      if (empresa.facebook.isNotEmpty)
        (
          glyph: BrandIcons.facebook,
          label: 'Facebook',
          onTap: () => _openFacebook(empresa.facebook),
        ),
      if (empresa.twitter.isNotEmpty)
        (
          glyph: BrandIcons.twitter,
          label: 'X',
          onTap: () => _open(Uri.https('x.com', '/${empresa.twitter}')),
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
                child: BrandGlyph(
                  link.glyph,
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

  Future<void> _open(Uri? uri) async {
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
