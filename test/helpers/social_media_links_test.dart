import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:icourier/helpers/social_media_links.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/login_model.dart';

import 'brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcherChannel, null);
  });

  testWidgets('shows X and LinkedIn only from EmpresaOptions', (tester) async {
    final company = Empresa.empty()
      ..paginaWeb = 'https://example.com'
      ..correoVentas = 'ventas@example.com'
      ..instagram = 'icourier'
      ..facebook = 'icourier'
      ..twitter = 'legacy-support-link';

    await tester.pumpWidget(_testApp(company));

    expect(_socialIcon(FontAwesomeIcons.xTwitter), findsNothing);
    expect(_socialIcon(FontAwesomeIcons.linkedinIn), findsNothing);

    company.options = jsonEncode({
      'RedSocialX': ' icourier ',
      'RedSocialLinkedIn': ' icourier-srl ',
    });
    await tester.pumpWidget(_testApp(company));

    expect(_socialIcon(FontAwesomeIcons.xTwitter), findsOneWidget);
    expect(_socialIcon(FontAwesomeIcons.linkedinIn), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides empty or invalid social options', (tester) async {
    final company = Empresa.empty()
      ..options = jsonEncode({
        'RedSocialX': '   ',
        'RedSocialLinkedIn': 'not a valid url',
      });

    await tester.pumpWidget(_testApp(company));

    expect(_socialIcon(FontAwesomeIcons.xTwitter), findsNothing);
    expect(_socialIcon(FontAwesomeIcons.linkedinIn), findsNothing);
  });

  testWidgets('tries the social app before falling back to the web', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcherChannel, (call) async {
      calls.add(call);
      final arguments = call.arguments as Map<Object?, Object?>;
      return arguments['universalLinksOnly'] != true;
    });
    final company = Empresa.empty()
      ..options = jsonEncode({
        'RedSocialLinkedIn': 'icourier-srl',
      });

    await tester.pumpWidget(_testApp(company));
    await tester.tap(_socialIcon(FontAwesomeIcons.linkedinIn));
    await tester.pump();

    expect(calls, hasLength(2));
    expect(calls.map((call) => call.method), everyElement('launch'));
    expect(
      calls.map((call) => call.arguments['url']),
      everyElement('https://www.linkedin.com/company/icourier-srl'),
    );
    expect(calls.first.arguments['universalLinksOnly'], isTrue);
    expect(calls.last.arguments['universalLinksOnly'], isFalse);
  });

  testWidgets('builds the X profile link from its configured account', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcherChannel, (call) async {
      calls.add(call);
      return true;
    });
    final company = Empresa.empty()
      ..options = jsonEncode({'RedSocialX': 'icourier'});

    await tester.pumpWidget(_testApp(company));
    await tester.tap(_socialIcon(FontAwesomeIcons.xTwitter));
    await tester.pump();

    expect(calls, hasLength(1));
    expect(calls.single.arguments['url'], 'https://x.com/icourier');
    expect(calls.single.arguments['universalLinksOnly'], isTrue);
  });
}

Widget _testApp(Empresa company) => brandTestApp(
      config: loadTestBrand('bmcargo'),
      child: SocialMediaLinks(
        empresa: company,
        userProfile: UserProfile(
          cuenta: '',
          nombre: '',
          email: '',
          sucursal: '',
          fotoPerfilUrl: '',
          direccionBuzon: '',
          buzones: const [],
        ),
      ),
    );

Finder _socialIcon(IconData icon) => find.byWidgetPredicate(
      (widget) => widget is FaIcon && widget.icon == icon,
    );
