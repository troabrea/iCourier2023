import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/asistente/assistant_avatar.dart';
import 'package:icourier/design_system/brand_foundations.dart';
import 'package:icourier/services/model/assistant_settings.dart';

import '../helpers/brand_test_app.dart';

const _avatarSvg =
    "<svg viewBox='0 0 24 24'><circle cx='12' cy='12' r='8'/></svg>";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAvatar(WidgetTester tester, String avatarSvg) async {
    final config = loadTestBrand('bmcargo');
    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: AssistantAvatar(
          avatarSvg: avatarSvg,
          semanticLabel: 'Mía',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders configured SVG artwork', (tester) async {
    await pumpAvatar(tester, _avatarSvg);

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(BrandGlyph), findsNothing);
  });

  testWidgets('uses the bundled assistant for a blank avatar', (tester) async {
    await pumpAvatar(tester, '');

    final fallback = tester.widget<BrandGlyph>(find.byType(BrandGlyph));
    expect(fallback.asset, BrandIcons.assistant);
  });

  testWidgets('uses the bundled assistant when SVG parsing fails',
      (tester) async {
    await pumpAvatar(tester, '<svg');

    final fallback = tester.widget<BrandGlyph>(find.byType(BrandGlyph));
    expect(fallback.asset, BrandIcons.assistant);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the bundled assistant for an oversized record',
      (tester) async {
    final oversized = '<svg viewBox="0 0 1 1">'
        '${List.filled(AssistantSettings.maxAvatarBytes, 'x').join()}'
        '</svg>';
    final settings = AssistantSettings.parse(
      jsonEncode({'AvatarSvg': oversized}),
    );
    await pumpAvatar(tester, settings.avatarSvg);

    expect(find.byType(BrandGlyph), findsOneWidget);
  });

  testWidgets('entrance grows, turns, and returns to rest', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: AssistantAvatarEntrance(
            rotate: true,
            duration: Duration(milliseconds: 600),
            peakScale: 1.2,
            child: SizedBox.square(dimension: 40),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 180));
    var transforms = tester.widgetList<Transform>(
      find.descendant(
        of: find.byType(AssistantAvatarEntrance),
        matching: find.byType(Transform),
      ),
    );
    expect(
      transforms.any((transform) => transform.transform.storage[0] > 1.05),
      isTrue,
    );
    expect(
      transforms.any(
        (transform) => transform.transform.storage[1].abs() > 0.1,
      ),
      isTrue,
    );

    await tester.pumpAndSettle();
    transforms = tester.widgetList<Transform>(
      find.descendant(
        of: find.byType(AssistantAvatarEntrance),
        matching: find.byType(Transform),
      ),
    );
    for (final transform in transforms) {
      expect(transform.transform.storage[0], closeTo(1, 0.001));
      expect(transform.transform.storage[1], closeTo(0, 0.001));
    }
  });

  testWidgets('reduced motion renders the resting state immediately',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(
            child: AssistantAvatarEntrance(
              rotate: true,
              child: SizedBox.square(dimension: 40),
            ),
          ),
        ),
      ),
    );

    final transforms = tester.widgetList<Transform>(
      find.descendant(
        of: find.byType(AssistantAvatarEntrance),
        matching: find.byType(Transform),
      ),
    );
    for (final transform in transforms) {
      expect(transform.transform.storage[0], closeTo(1, 0.001));
      expect(transform.transform.storage[1], closeTo(0, 0.001));
    }
  });
}
