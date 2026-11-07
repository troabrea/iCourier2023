import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:icourier/design_system/content_components.dart';
import 'package:icourier/helpers/social_media_links.dart';
import 'package:icourier/services/model/empresa.dart';
import 'package:icourier/services/model/login_model.dart';
import 'package:icourier/services/model/noticia.dart';
import 'package:icourier/theme/brand_tokens.dart';

import '../helpers/brand_test_app.dart';

void main() {
  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  for (final slug in ['domex', 'bmcargo', 'fixocargo']) {
    for (final brightness in Brightness.values) {
      testWidgets('news contrast $slug ${brightness.name}', (tester) async {
        final news = Noticia(
          registroId: 'contrast-news',
          empresa: slug,
          fecha: DateTime(2026, 10, 19),
          titulo: '¡BLACK FRIDAY EN OCTUBRE! DOMEX, EXPLÍCATE',
          resumen: 'No pudimos esperar hasta noviembre.',
          contenido: '',
          url: '',
          deleted: false,
        );
        final goldenKey = GlobalKey();
        await tester.pumpWidget(brandTestApp(
          config: loadTestBrand(slug),
          brightness: brightness,
          child: RepaintBoundary(
            key: goldenKey,
            child: Builder(builder: (context) {
              return ColoredBox(
                color: context.brand.bg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SocialMediaLinks(
                      empresa: Empresa.empty()
                        ..paginaWeb = 'https://example.com',
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
                    NewsCard(news: news, onTap: () {}),
                  ],
                ),
              );
            }),
          ),
        ));
        await tester.pumpAndSettle();

        final tokens = tester.element(find.byType(NewsCard)).brand;
        final title = tester.widget<Text>(find.text(news.titulo));
        expect(_contrast(title.style!.color!, tokens.surface),
            greaterThanOrEqualTo(4.5));
        for (final text in ['19', 'OCT']) {
          final finder = find.text(text);
          final stamp = tester.widget<Container>(find
              .ancestor(
                of: finder,
                matching: find.byType(Container),
              )
              .first);
          final background = (stamp.decoration! as BoxDecoration).color!;
          expect(
              _contrast(tester.widget<Text>(finder).style!.color!, background),
              greaterThanOrEqualTo(4.5));
        }
        for (final icon in tester.widgetList<FaIcon>(find.byType(FaIcon))) {
          expect(_contrast(icon.color!, tokens.bg), greaterThanOrEqualTo(3));
        }
        expect(tester.takeException(), isNull);
        if (slug == 'domex' && brightness == Brightness.light) {
          await expectLater(find.byKey(goldenKey),
              matchesGoldenFile('goldens/news_card_domex_light.png'));
        }
      });
    }
  }
}

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance() + 0.05;
  final b = background.computeLuminance() + 0.05;
  return a > b ? a / b : b / a;
}
