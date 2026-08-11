import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icourier/design_system/brand_foundations.dart';
import 'package:icourier/design_system/brand_states.dart';
import 'package:icourier/design_system/calculator_components.dart';
import 'package:icourier/design_system/content_components.dart';
import 'package:icourier/design_system/core_components.dart';
import 'package:icourier/design_system/home_components.dart';
import 'package:icourier/design_system/overlay_components.dart';
import 'package:icourier/domain/package_stage.dart';
import 'package:icourier/services/model/mensaje.dart';
import 'package:icourier/services/model/noticia.dart';
import 'package:icourier/services/model/recepcion.dart';
import 'package:icourier/services/model/sucursal.dart';
import 'package:icourier/theme/brand_config.dart';

import '../helpers/brand_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializeTestTranslations();
    await loadBrandFonts();
  });

  for (final brand in ['bmcargo', 'fixocargo']) {
    for (final brightness in Brightness.values) {
      final mode = brightness.name;
      for (final fixture in _fixtures()) {
        testWidgets('${fixture.key} · $brand · $mode', (tester) async {
          final goldenKey = GlobalKey();
          await tester.pumpWidget(
            brandTestApp(
              config: loadTestBrand(brand),
              brightness: brightness,
              child: RepaintBoundary(
                key: goldenKey,
                child: Material(
                  child: SizedBox(
                    width: 390,
                    height: 320,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(child: fixture.value()),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await expectLater(
            find.byKey(goldenKey),
            matchesGoldenFile('goldens/${fixture.key}_${brand}_$mode.png'),
          );
        });
      }
    }
  }
}

List<MapEntry<String, Widget Function()>> _fixtures() {
  final package = _package();
  final event = Historia(
    paqueteID: 'PK-1',
    nombreEstatus: 'Embarcado',
    fecha: '10-08-2026 | 10:00 AM',
    ciudad: 'Miami',
    fechaHora: '2026-08-10T10:00:00',
  );
  final branch = Sucursal(
    registroId: '1',
    empresa: 'demo',
    nombre: 'Sucursal Principal',
    codigo: 'SDQ',
    direccion: 'Av. Principal, Santo Domingo',
    ciudad: 'Santo Domingo',
    pais: 'República Dominicana',
    horario: 'Lunes a viernes · 8:00–17:00',
    telefonoOficina: '809-000-0000',
    telefonoVentas: '',
    email: '',
    imagenId: '',
    latitud: 18.4861,
    longitud: -69.9312,
    orden: 1,
    deleted: false,
  );
  final news = Noticia(
    registroId: '1',
    empresa: 'demo',
    fecha: DateTime(2026, 8, 10),
    titulo: 'Nueva facilidad para tus paquetes',
    resumen: 'Información entregada por el backend.',
    contenido: '',
    url: '',
    deleted: false,
  );
  final message = Mensaje(
    registroId: '1',
    empresa: 'demo',
    fecha: DateTime(2026, 8, 10),
    titulo: 'Tu paquete cambió de estado',
    contenido: 'Ya se encuentra en nuestro centro de distribución.',
    deleted: false,
    read: false,
  );

  return [
    MapEntry(
      'brand_header',
      () => const BrandHeader(
        greeting: 'Bienvenido, María',
        account: 'BM-002332',
        points: 1280,
        unread: 3,
        capabilities: BrandCapabilities(points: true),
      ),
    ),
    const MapEntry(
      'screen_header',
      _screenHeader,
    ),
    MapEntry(
      'brand_tab_bar',
      () => BrandTabBar(
        modules: BrandNavigationConfig.standard().tabs,
        index: 2,
        onTap: (_) {},
      ),
    ),
    MapEntry(
      'quick_action_grid',
      () => const QuickActionGrid(
        actions: [
          QuickAction(
            label: 'Crear Pre-Alerta',
            icon: BrandIcons.prealert,
            onTap: _noop,
          ),
          QuickAction(
            label: 'Rastrear Paquete',
            icon: BrandIcons.track,
            onTap: _noop,
          ),
          QuickAction(
            label: 'Ver Pre-Alertas',
            icon: BrandIcons.receptions,
            onTap: _noop,
          ),
          QuickAction(
            label: 'Consulta Histórica',
            icon: BrandIcons.history,
            onTap: _noop,
          ),
        ],
      ),
    ),
    MapEntry('package_card', () => PackageCard(package: package)),
    const MapEntry('status_badge', _statusBadge),
    const MapEntry('macro_stepper', _macroStepper),
    MapEntry(
      'event_timeline',
      () => EventTimeline(events: [event], stage: PackageStage.ruta),
    ),
    MapEntry(
      'selectable_row',
      () => SelectableRow(
        package: package,
        checked: true,
        onToggle: (_) {},
      ),
    ),
    const MapEntry('selection_summary_bar', _selectionSummaryBar),
    MapEntry(
      'group_row',
      () => const GroupRow(label: 'Recepciones', count: 4, onTap: _noop),
    ),
    MapEntry(
      'product_selector',
      () => ProductSelector<String>(
        options: const ['Aéreo', 'Marítimo', 'Express'],
        value: 'Aéreo',
        labelFor: (value) => value,
        onChange: (_) {},
      ),
    ),
    MapEntry(
      'big_number_field',
      () => BigNumberField(
        label: 'Peso',
        unit: 'lb',
        controller: TextEditingController(text: '2.50'),
      ),
    ),
    const MapEntry('totals_panel', _totalsPanel),
    const MapEntry('concept_table', _conceptTable),
    MapEntry('branch_card', () => BranchCard(branch: branch)),
    const MapEntry('service_card', _serviceCard),
    const MapEntry('faq_accordion', _faqAccordion),
    MapEntry('news_card', () => NewsCard(news: news)),
    MapEntry('message_row', () => MessageRow(message: message)),
    const MapEntry('confirm_dialog', _confirmDialog),
    const MapEntry('tip_bubble', _tipBubble),
    const MapEntry('carnet_qr', _carnetQr),
    const MapEntry('stage_rail', _stageRail),
    const MapEntry('status_badge_soft', _statusBadgeSoft),
    const MapEntry('brand_notice', _brandNotice),
    const MapEntry('empty_state', _emptyState),
    const MapEntry('error_state', _errorState),
    const MapEntry('skeleton', _skeleton),
    const MapEntry('home_card_ready', _homeCardReady),
    const MapEntry('home_card_on_the_way', _homeCardOnTheWay),
    const MapEntry('home_card_empty', _homeCardEmpty),
    const MapEntry('points_card', _pointsCard),
    const MapEntry('filter_chip', _filterChip),
  ];
}

Widget _screenHeader() => const ScreenHeader(title: 'Detalle de paquete');

Widget _statusBadge() => const StatusBadge(
      stage: PackageStage.disponible,
      retained: true,
    );

Widget _macroStepper() => const MacroStepper(stage: PackageStage.destino);

Widget _selectionSummaryBar() => const SelectionSummaryBar(
      count: 2,
      total: 318.75,
      currency: 'RD\$',
      capabilities: BrandCapabilities(payments: true, delivery: true),
      onPickup: _noop,
      onPay: _noop,
      onDelivery: _noop,
    );

Widget _totalsPanel() => const TotalsPanel(
      subtotal: 250,
      tax: 68.75,
      total: 318.75,
      currency: 'RD\$',
    );

Widget _conceptTable() => const ConceptTable(
      currency: 'RD\$',
      concepts: [
        CalcConceptView(
          label: 'Flete Estándar',
          amount: 250,
          quantity: '2.50',
          unitPrice: '3.50',
        ),
        CalcConceptView(
          label: 'Servicios DGA',
          amount: 68.75,
          quantity: '2.50',
          unitPrice: '0.50',
        ),
      ],
    );

Widget _serviceCard() => const ServiceCard(
      title: 'Consolidación',
      description: 'Agrupa tus compras en un solo envío.',
    );

Widget _faqAccordion() => const FaqAccordion(
      question: '¿Cómo funciona?',
      answer: 'La respuesta proviene del backend.',
    );

Widget _confirmDialog() => const ConfirmDialog(
      title: 'Eliminar cuenta',
      message: '¿Seguro que deseas continuar?',
      onConfirm: _noop,
    );

Widget _tipBubble() => const TipBubble(
      title: 'Nuevo: sigue tus paquetes desde tu pantalla de inicio',
      message: 'Agrega el widget y activa las actividades en vivo.',
      onDismiss: _noop,
    );

Widget _carnetQr() => const CarnetQR(accountCode: 'BM-002332');

Widget _stageRail() => const StageRail(stage: PackageStage.destino);

Widget _statusBadgeSoft() => const StatusBadge.soft(
      stage: PackageStage.disponible,
      retained: true,
    );

Widget _brandNotice() => const BrandNotice(
      title: 'Retenido — Falta factura',
      message: 'Adjunta el valor y la factura para liberar este paquete.',
      glyph: BrandIcons.missingInvoice,
      actionLabel: 'Adjuntar factura',
      onAction: _noop,
    );

Widget _emptyState() => const BrandEmptyState(messageKey: 'no_paquetes');

Widget _errorState() => const BrandErrorState(onRetry: _noop);

Widget _skeleton() => const SizedBox(height: 220, child: BrandSkeleton(rows: 2));

Widget _homeCardReady() => const HomeStatusCard(
      status: HomeStatus.ready,
      count: 2,
      total: '337.99',
      currency: r'$',
      branch: 'Sucursal Miami Principal',
      onPickup: _noop,
      onDelivery: _noop,
    );

Widget _homeCardOnTheWay() => const HomeStatusCard(
      status: HomeStatus.onTheWay,
      count: 3,
      nextContent: 'Cargador inalámbrico',
      nextStage: PackageStage.destino,
    );

Widget _homeCardEmpty() => const HomeStatusCard(
      status: HomeStatus.empty,
      onShowAddress: _noop,
    );

Widget _pointsCard() => const PointsCard(
      label: 'Puntos Disponibles',
      balance: '1,240',
      onRedeem: _noop,
    );

Widget _filterChip() => const BrandFilterChip(
      label: 'Disponibles',
      onClear: _noop,
    );

void _noop() {}

Recepcion _package() => Recepcion(
      recepcionID: 'RD-10458321',
      fecha: '2026-08-10',
      producto: 'Aéreo',
      suplidor: 'Amazon',
      cantidadPaquetes: 1,
      contenido: 'Artículos personales',
      enviadoPor: 'Amazon',
      totalPeso: '2.50',
      totalVolumen: '0',
      totalNeto: '318.75',
      estatus: 'Embarcado',
      retenido: false,
      disponible: false,
      paquetes: const [],
      fotoPaqueteSmallUrl: '',
      fotoPaqueteUrl: '',
      fotoFacturaUrl: '',
      fechaHora: '2026-08-10T10:00:00',
      progreso: 2,
      numeroRastreo: '1Z999AA10123456784',
    );
