import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/design_system/brand_foundations.dart';
import 'package:icourier/design_system/motion_components.dart';
import 'package:icourier/theme/brand_tokens.dart';

import '../helpers/brand_test_app.dart';

void main() {
  setUpAll(loadBrandFonts);

  test('manifest delays stay bounded for backend-driven lists', () {
    expect(brandManifestDelay(0), Duration.zero);
    expect(
      brandManifestDelay(100, startMilliseconds: 90),
      const Duration(milliseconds: 420),
    );
  });

  testWidgets('manifest beam is transient and leaves content interactive', (
    tester,
  ) async {
    final config = loadTestBrand('bmcargo');
    var taps = 0;

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: BrandManifestReveal(
          child: BrandPrimaryButton(
            label: 'Continuar',
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    final reveal = find.byType(BrandManifestReveal);
    expect(find.descendant(of: reveal, matching: find.byType(ClipPath)),
        findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.descendant(of: reveal, matching: find.byType(ClipPath)),
        findsNothing);

    await tester.tap(find.text('Continuar'));
    expect(taps, 1);
  });

  testWidgets('manifest reveal resolves immediately for reduced motion', (
    tester,
  ) async {
    final config = loadTestBrand('bmcargo');

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const BrandManifestReveal(child: Text('Contenido listo')),
          ),
        ),
      ),
    );

    final reveal = find.byType(BrandManifestReveal);
    expect(find.text('Contenido listo'), findsOneWidget);
    expect(find.descendant(of: reveal, matching: find.byType(ClipPath)),
        findsNothing);
  });

  testWidgets('manifest scan has a deliberate branded mid-frame', (
    tester,
  ) async {
    final config = loadTestBrand('bmcargo');
    await tester.binding.setSurfaceSize(const Size(430, 260));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: BrandManifestReveal(
          duration: const Duration(milliseconds: 900),
          child: Builder(
            builder: (context) {
              final tokens = context.brand;
              return Padding(
                padding: const EdgeInsets.all(24),
                child: BrandCard(
                  child: Row(
                    children: [
                      const BrandGlyphTile(
                        asset: BrandIcons.track,
                        size: 48,
                        glyphSize: 25,
                      ),
                      const SizedBox(width: BrandSpace.sm),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Manifiesto recibido', style: tokens.head(17)),
                            const SizedBox(height: BrandSpace.xxs),
                            Text(
                              'Tu paquete acaba de entrar al sistema.',
                              style: tokens.body(12, color: tokens.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    await expectLater(
      find.byType(BrandManifestReveal),
      matchesGoldenFile('goldens/manifest_scan_bmcargo.png'),
    );
  });
}
