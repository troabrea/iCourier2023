import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/design_system/brand_foundations.dart';
import 'package:icourier/design_system/brand_states.dart';
import 'package:icourier/design_system/calculator_components.dart';
import 'package:icourier/design_system/content_components.dart';
import 'package:icourier/design_system/core_components.dart';
import 'package:icourier/design_system/home_components.dart';
import 'package:icourier/domain/package_stage.dart';
import 'package:icourier/services/model/banner.dart';
import 'package:icourier/services/model/recepcion.dart';
import 'package:icourier/theme/brand_config.dart';
import 'package:icourier/theme/brand_tokens.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  testWidgets('muestra carga, vacío y error recuperable', (tester) async {
    final config = loadTestBrand('bmcargo');

    await tester.pumpWidget(
      brandTestApp(config: config, child: const BrandSkeleton(rows: 3)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Semantics), findsWidgets);

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: const BrandEmptyState(messageKey: 'no_resultados'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No hay resultados'), findsOneWidget);

    var retried = false;
    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: BrandErrorState(onRetry: () => retried = true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar'));
    expect(retried, isTrue);
  });

  testWidgets('retenido deshabilita selección y usa estado de advertencia',
      (tester) async {
    final config = loadTestBrand('bmcargo');
    final package = _package(retained: true);
    var toggled = false;

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StatusBadge(
              stage: PackageStage.disponible,
              retained: true,
            ),
            SelectableRow(
              package: package,
              checked: false,
              onToggle: (_) => toggled = true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // La fila retenida se atenúa y no acepta selección.
    expect(find.byType(Opacity), findsWidgets);
    await tester.tap(find.byType(SelectableRow), warnIfMissed: false);
    expect(toggled, isFalse);
  });

  testWidgets('capacidades ocultan puntos y pago', (tester) async {
    final config = loadTestBrand('fixocargo');

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandHeader(
              greeting: 'Bienvenido',
              account: 'FX-100',
              points: 900,
              capabilities: BrandCapabilities(points: false),
            ),
            SelectionSummaryBar(
              count: 1,
              total: 100,
              currency: 'RD\$',
              capabilities: BrandCapabilities(payments: false),
              onPay: _noop,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('900'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('componentes soportan escalado de texto al 200%', (tester) async {
    final config = loadTestBrand('fixocargo');
    await tester.pumpWidget(
      brandTestApp(
        config: config,
        textScaler: const TextScaler.linear(2),
        child: const BrandEmptyState(messageKey: 'no_resultados'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('campo numérico acepta separador decimal local', (tester) async {
    final config = loadTestBrand('bmcargo');
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: BigNumberField(
          label: 'Peso',
          unit: 'lb',
          controller: controller,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '1,25');

    expect(controller.text, '1,25');
    expect(tester.takeException(), isNull);
  });

  testWidgets('service details reveal before their external action', (
    tester,
  ) async {
    final config = loadTestBrand('bmcargo');
    var opened = false;

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: ServiceCard(
          title: 'Casillero internacional',
          description: 'Recibe tus compras y consulta cada etapa.',
          onOpenDetails: () => opened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.text('Recibe tus compras y consulta cada etapa.'), findsNothing);
    expect(find.text('Ver detalle'), findsNothing);

    await tester.tap(find.text('Casillero internacional'));
    await tester.pumpAndSettle();
    expect(
        find.text('Recibe tus compras y consulta cada etapa.'), findsOneWidget);
    expect(find.text('Ver detalle'), findsOneWidget);

    await tester.tap(find.text('Ver detalle'));
    expect(opened, isTrue);
  });

  testWidgets('banner carousel autoscrolls without an indicator overlay', (
    tester,
  ) async {
    final config = loadTestBrand('bmcargo');

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: BannerCarousel(
          config: config,
          interval: const Duration(seconds: 1),
          banners: [
            BannerImage(
              registroId: 'banner-1',
              empresa: 'demo',
              imagenId: '',
              descripcion: 'Primero',
              url: '',
              deleted: false,
            ),
            BannerImage(
              registroId: 'banner-2',
              empresa: 'demo',
              imagenId: '',
              descripcion: 'Segundo',
              url: '',
              deleted: false,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    final carousel = find.byType(BannerCarousel);
    final pageView = tester.widget<PageView>(
      find.descendant(of: carousel, matching: find.byType(PageView)),
    );
    expect(pageView.controller!.page, 10000);
    expect(
      find.descendant(of: carousel, matching: find.byType(Positioned)),
      findsNothing,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 450));

    expect(pageView.controller!.page, 10001);
  });

  testWidgets('acciones y canje conservan contraste con acentos claros', (
    tester,
  ) async {
    final config = loadTestBrand('domex');
    final goldenKey = GlobalKey();
    var redeemed = false;

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: RepaintBoundary(
          key: goldenKey,
          child: Material(
            child: SizedBox(
              width: 390,
              height: 220,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandGlyphTile(asset: BrandIcons.prealert),
                    const SizedBox(height: 16),
                    PointsCard(
                      label: 'Puntos disponibles',
                      balance: '0.0',
                      onRedeem: () => redeemed = true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tileFinder = find.byType(BrandGlyphTile);
    final tile = tester.widget<Container>(
      find.descendant(of: tileFinder, matching: find.byType(Container)).first,
    );
    final tileDecoration = tile.decoration! as BoxDecoration;
    final glyph = tester.widget<BrandGlyph>(
      find.descendant(of: tileFinder, matching: find.byType(BrandGlyph)),
    );
    expect(
      _contrast(glyph.color, tileDecoration.color!),
      greaterThanOrEqualTo(3),
    );

    final pointsFinder = find.byType(PointsCard);
    final tokens =
        Theme.of(tester.element(pointsFinder)).extension<BrandTokens>()!;
    final redeemButton = tester.widget<TextButton>(find.byType(TextButton));
    final redeemForeground = redeemButton.style!.foregroundColor!.resolve({})!;
    final redeemBackground = Color.lerp(
      tokens.surface,
      tokens.secondary,
      0.22,
    )!;
    expect(
      _contrast(redeemForeground, redeemBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      redeemButton.style!.minimumSize!.resolve({}),
      const Size(44, 44),
    );

    await tester.tap(find.text('Canjear'));
    expect(redeemed, isTrue);
    await tester.pump();

    await expectLater(
      find.byKey(goldenKey),
      matchesGoldenFile('goldens/contrast_actions_domex_light.png'),
    );
  });

  testWidgets('home y recepciones reutilizan superficies de icono legibles', (
    tester,
  ) async {
    final config = loadTestBrand('domex');
    final goldenKey = GlobalKey();

    await tester.pumpWidget(
      brandTestApp(
        config: config,
        child: RepaintBoundary(
          key: goldenKey,
          child: const Material(
            color: Color(0xfff6f5ef),
            child: SizedBox(
              width: 390,
              height: 650,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 46, 16, 16),
                child: Column(
                  children: [
                    HomeStatusCard(),
                    ReceptionsGroupCard(
                      total: 2,
                      children: [SizedBox.shrink()],
                    ),
                    SizedBox(
                      height: 230,
                      child: BrandEmptyState(messageKey: 'no_paquetes'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge.soft(
                          stage: PackageStage.disponible,
                          available: true,
                        ),
                        SizedBox(
                          width: 120,
                          child: StageRail(stage: PackageStage.disponible),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(HomeStatusCard),
        matching: find.byType(BrandGlyphTile),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ReceptionsGroupCard),
        matching: find.byType(BrandGlyphTile),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(BrandEmptyState),
        matching: find.byType(BrandGlyphTile),
      ),
      findsOneWidget,
    );

    final badge = tester.widget<BrandPill>(
      find.descendant(
        of: find.byType(StatusBadge),
        matching: find.byType(BrandPill),
      ),
    );
    expect(
      _contrast(badge.foreground, badge.background),
      greaterThanOrEqualTo(4.5),
    );

    final tokens = Theme.of(tester.element(find.byType(StageRail)))
        .extension<BrandTokens>()!;
    final visiblePrimary = tokens.accessibleForeground(
      tokens.surface,
      preferred: tokens.primary,
      minimumContrast: 3,
    );
    expect(
      _contrast(visiblePrimary, tokens.surface),
      greaterThanOrEqualTo(3),
    );

    await expectLater(
      find.byKey(goldenKey),
      matchesGoldenFile('goldens/contrast_home_receptions_domex_light.png'),
    );
  });
}

void _noop() {}

double _contrast(Color first, Color second) {
  final a = first.computeLuminance() + 0.05;
  final b = second.computeLuminance() + 0.05;
  return a > b ? a / b : b / a;
}

Recepcion _package({required bool retained}) => Recepcion(
      recepcionID: 'RD-1',
      fecha: '2026-08-10',
      producto: 'Aéreo',
      suplidor: 'Amazon',
      cantidadPaquetes: 1,
      contenido: 'Artículos personales',
      enviadoPor: 'Amazon',
      totalPeso: '2.5',
      totalVolumen: '0',
      totalNeto: '100',
      estatus: 'Disponible',
      retenido: retained,
      disponible: true,
      paquetes: const [],
      fotoPaqueteSmallUrl: '',
      fotoPaqueteUrl: '',
      fotoFacturaUrl: '',
      fechaHora: '2026-08-10T10:00:00',
      progreso: 3,
      numeroRastreo: '1Z999',
    );
