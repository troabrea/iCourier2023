import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/model/empresa.dart';

class SocialMediaLinks extends StatelessWidget {
  final Empresa empresa;
  final UserProfile userProfile;
  final double iconSize;
  const SocialMediaLinks({Key? key, required this.empresa, required this.userProfile, this.iconSize = 30}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      IconButton(icon: FaIcon(Platform.isIOS ? FontAwesomeIcons.safari : FontAwesomeIcons.chrome, size: iconSize,),
        color: Theme.of(context).colorScheme.secondary,
        onPressed: () => { openInBrowser(empresa) },),
      if(empresa.correoVentas.isNotEmpty || userProfile.email.isNotEmpty)
      IconButton(icon: FaIcon(FontAwesomeIcons.envelope, size: iconSize),
        color: Theme.of(context).colorScheme.secondary,
        onPressed: () => { sendEmail(empresa, userProfile) },),
      if(empresa.facebook.isNotEmpty)
      IconButton(icon: FaIcon(FontAwesomeIcons.instagram, size: iconSize),
        color: Theme.of(context).colorScheme.secondary,
        onPressed: () => { viewInInstagram(empresa) },),
      if(empresa.facebook.isNotEmpty)
      IconButton(icon: FaIcon(FontAwesomeIcons.facebook, size: iconSize),
        color: Theme.of(context).colorScheme.secondary,
        onPressed: () => { viewInFacebook(empresa) },),
    ],);
  }

  Future<void> openInBrowser(Empresa empresa) async {
    var _url = Uri.parse(empresa.paginaWeb);
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $_url';
    }
  }
  Future<void> sendEmail(Empresa empresa, UserProfile userProfile) async {
    var email = userProfile.emailSucursal.isEmpty ? empresa.correoVentas : userProfile.emailSucursal;
    var _url = Uri.parse("mailto:$email");
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $_url';
    }
  }

  Future<void> viewInFacebook(Empresa empresa) async {
    var facebook = empresa.facebook;
    String fbProtocolUrl;
    if (Platform.isIOS) {
      fbProtocolUrl = 'fb://profile/$facebook';
    } else {
      fbProtocolUrl = 'fb://page/$facebook';
    }

    String fallbackUrl = 'https://www.facebook.com/$facebook';
    if(empresa.dominio.toUpperCase() == "CPS") {
      fbProtocolUrl = "https://www.facebook.com/comunidadcps/?mibextid=LQQJ4d";
      fallbackUrl = "https://www.facebook.com/comunidadcps/?mibextid=LQQJ4d";
    }
    if(empresa.dominio.toUpperCase() == "JETPACK") {
      fbProtocolUrl = "https://www.facebook.com/jetpackcourier";
      fallbackUrl = "https://www.facebook.com/jetpackcourier";
    }


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
    if(empresa.dominio.toUpperCase() == "CPS") {
      facebook="cps.rd";
    }
    if(empresa.dominio.toUpperCase() == "FIXOCARGO") {
      facebook = 'fixocargo';
    }

    if(empresa.instagram.isNotEmpty) {
      var num = double.tryParse(empresa.instagram);
      if(num == null) {
        facebook = empresa.instagram;
      }
    }


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
