import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/model/empresa.dart';

class SocialMediaLinks extends StatelessWidget {
  final Empresa empresa;
  final double iconSize;
  const SocialMediaLinks({Key? key, required this.empresa, this.iconSize = 30}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      IconButton(icon: FaIcon(Platform.isIOS ? FontAwesomeIcons.safari : FontAwesomeIcons.chrome, size: iconSize,), onPressed: () => { openInBrowser(empresa) },),
      IconButton(icon: FaIcon(FontAwesomeIcons.envelope, size: iconSize), onPressed: () => { sendEmail(empresa) },),
      IconButton(icon: FaIcon(FontAwesomeIcons.facebook, size: iconSize), onPressed: () => { viewInFacebook(empresa) },),
      IconButton(icon: FaIcon(FontAwesomeIcons.instagram, size: iconSize), onPressed: () => { viewInInstagram(empresa) },),
    ],);
  }

  Future<void> openInBrowser(Empresa empresa) async {
    var _url = Uri.parse(empresa.paginaWeb);
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $_url';
    }
  }
  Future<void> sendEmail(Empresa empresa) async {
    var email = empresa.correoVentas;
    var _url = Uri.parse("mailto:$email");
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $_url';
    }
  }

  Future<void> viewInFacebook(Empresa empresa) async {
    var facebook = empresa.facebook;
    String fbProtocolUrl;
    if (Platform.isIOS) {
      fbProtocolUrl = 'fb://profile/$facebook.';
    } else {
      fbProtocolUrl = 'fb://page/$facebook';
    }

    String fallbackUrl = 'https://www.facebook.com/$facebook';

    try {
      Uri fbBundleUri = Uri.parse(fbProtocolUrl);
      var canLaunchNatively = await canLaunchUrl(fbBundleUri);

      if (canLaunchNatively) {
        launchUrl(fbBundleUri);
      } else {
        await launchUrl(Uri.parse(fallbackUrl),
            mode: LaunchMode.externalApplication);
      }
    } catch (e, st) {
      // Handle this as you prefer
    }
  }

  // Future<void> viewInFacebookOld(Empresa empresa) async {
  //   var facebook = empresa.facebook;
  //
  //   String fbProtocolUrl;
  //   if (Platform.isIOS) {
  //     fbProtocolUrl = 'https://www.facebook.com/$facebook';// 'fb://profile?app_scoped_user_id=$facebook';
  //   } else {
  //     fbProtocolUrl = 'https://www.facebook.com/$facebook'; // 'fb://page/$facebook';
  //   }
  //
  //   String fallbackUrl = 'https://www.facebook.com/$facebook';
  //
  //
  //   var _url = Uri.parse(fbProtocolUrl);
  //
  //   if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
  //     _url = Uri.parse(fallbackUrl);
  //     if(!await launchUrl(_url, mode: LaunchMode.externalApplication))
  //     {
  //       throw 'Could not launch $_url';
  //     }
  //   }
  // }

  Future<void> viewInInstagram(Empresa empresa) async {
    var facebook = empresa.facebook;

    String fbProtocolUrl;
    if (Platform.isIOS) {
      fbProtocolUrl = 'instagram://user?username=$facebook';
    } else {
      fbProtocolUrl =  'instagram://user?username=$facebook'; //'https://www.instagram.com/$facebook';//
    }

    String fallbackUrl = 'https://www.instagram.com/$facebook';

    try {
      Uri fbBundleUri = Uri.parse(fbProtocolUrl);
      var canLaunchNatively = await canLaunchUrl(fbBundleUri);

      if (canLaunchNatively) {
        launchUrl(fbBundleUri);
      } else {
        await launchUrl(Uri.parse(fallbackUrl),
            mode: LaunchMode.externalApplication);
      }
    } catch (e, st) {
      // Handle this as you prefer
    }

  }

}
