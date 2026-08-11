import 'package:flutter/material.dart';

import '../domain/package_stage.dart';
import '../services/model/banner.dart';
import '../services/model/login_model.dart';
import '../services/model/mensaje.dart';
import '../services/model/noticia.dart';
import '../services/model/recepcion.dart';
import '../services/model/sucursal.dart';
import '../theme/brand_config.dart';
import '../theme/brand_tokens.dart';
import 'brand_foundations.dart';
import 'brand_states.dart';
import 'calculator_components.dart';
import 'content_components.dart';
import 'core_components.dart';
import 'home_components.dart';
import 'overlay_components.dart';

/// Internal catalogue of every component, used to review the design system
/// without walking the whole app. Registered in debug builds only.
class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key, required this.config});

  final BrandConfig config;

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  final _weight = TextEditingController(text: '2.50');
  final _fob = TextEditingController(text: '248.00');
  var _product = 'Estándar';
  var _selected = false;
  var _tab = 2;

  late final _history = [
    Historia(
      paqueteID: 'PK-1',
      nombreEstatus: 'En Tránsito a Sucursal',
      fecha: '10-08-2026 | 10:00 AM',
      ciudad: 'Miami',
      fechaHora: '2026-08-10T10:00:00',
    ),
    Historia(
      paqueteID: 'PK-1',
      nombreEstatus: 'Embarcado',
      fecha: '08-08-2026 | 07:45 AM',
      ciudad: 'Miami',
      fechaHora: '2026-08-08T07:45:00',
    ),
  ];

  late final _package = _sample(retenido: false);
  late final _retained = _sample(retenido: true, disponible: true);

  @override
  void dispose() {
    _weight.dispose();
    _fob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    final branch = _sampleBranch();
    final account = UserAccount(
      sessionId: 'session',
      nombre: 'Baroli Technologies, SRL',
      userAccount: 'KR-002332',
      password: 'password',
    );

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: const ScreenHeader(title: 'Component Gallery'),
      bottomNavigationBar: BrandTabBar(
        modules: widget.config.navigation.tabs,
        index: _tab,
        onTap: (index) => setState(() => _tab = index),
        logoMark: widget.config.assets.logoMark,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, BrandTabBar.height),
        children: [
          BrandHeader(
            greeting: 'Baroli',
            accountName: account.nombre,
            account: account.userAccount,
            points: 1240,
            unread: 3,
            capabilities: widget.config.capabilities,
            onAccounts: () {},
            onCarnet: () {},
            onMessages: () {},
            onRefresh: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BrandSpace.lg),
            child: HomeStatusCard(
              status: HomeStatus.ready,
              count: 2,
              total: '337.99',
              currency: r'$',
              branch: 'Sucursal Miami Principal',
              onTap: () {},
              onPickup: () {},
              onDelivery: () {},
            ),
          ),
          _section('Estados de la tarjeta de inicio'),
          _pad(
            HomeStatusCard(
              status: HomeStatus.onTheWay,
              count: 3,
              nextContent: 'Cargador inalámbrico',
              nextStage: PackageStage.destino,
              onTap: () {},
            ),
          ),
          _pad(
            HomeStatusCard(
              status: HomeStatus.empty,
              onShowAddress: () {},
            ),
          ),
          _section('Tip · grupo · accesos'),
          _pad(
            TipBubble(
              title: 'Nuevo: sigue tus paquetes',
              message: 'Agrega el widget y activa las actividades en vivo.',
              onDismiss: () {},
            ),
          ),
          const SizedBox(height: 10),
          _pad(
            ReceptionsGroupCard(
              total: 6,
              initiallyExpanded: true,
              children: [
                GroupRow(label: 'Recibido', count: 1, onTap: () {}),
                GroupRow(label: 'En ruta', count: 2, onTap: () {}),
                GroupRow(label: 'Disponibles', count: 3, onTap: () {}),
              ],
            ),
          ),
          _pad(
            QuickActionGrid(
              actions: [
                QuickAction(
                  label: 'Crear Pre-Alerta',
                  icon: BrandIcons.prealert,
                  onTap: () {},
                ),
                QuickAction(
                  label: 'Ver Pre-Alertas',
                  icon: BrandIcons.receptions,
                  onTap: () {},
                ),
                QuickAction(
                  label: 'Rastrear Paquete',
                  icon: BrandIcons.track,
                  onTap: () {},
                ),
                QuickAction(
                  label: 'Consulta Histórica',
                  icon: BrandIcons.history,
                  onTap: () {},
                ),
              ],
            ),
          ),
          _section('Puntos · filtro'),
          _pad(
            PointsCard(
              label: widget.config.loyaltyLabel,
              balance: '1,240',
              onRedeem: () {},
            ),
          ),
          const SizedBox(height: 10),
          _pad(BrandFilterChip(label: 'Disponibles', onClear: () {})),
          _section('Estados'),
          _pad(
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final stage in PackageStage.values)
                  StatusBadge(stage: stage),
                const StatusBadge(
                  stage: PackageStage.disponible,
                  retained: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _pad(
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final stage in PackageStage.values)
                  StatusBadge.soft(stage: stage),
                const StatusBadge.soft(
                  stage: PackageStage.disponible,
                  retained: true,
                ),
              ],
            ),
          ),
          _section('Paquete'),
          _pad(PackageCard(package: _package, onTap: () {})),
          const SizedBox(height: 10),
          _pad(const MacroStepper(stage: PackageStage.destino)),
          const SizedBox(height: 10),
          _pad(
            BrandNotice(
              title: 'Retenido — Falta factura',
              message: 'Adjunta el valor y la factura para liberar el paquete.',
              glyph: BrandIcons.missingInvoice,
              actionLabel: 'Adjuntar factura',
              onAction: () {},
            ),
          ),
          const SizedBox(height: 10),
          _pad(
            EventTimeline(events: _history, stage: PackageStage.destino),
          ),
          _section('Selección'),
          _pad(
            SelectableRow(
              package: _package,
              checked: _selected,
              onToggle: (value) => setState(() => _selected = value),
            ),
          ),
          const SizedBox(height: 10),
          _pad(
            SelectableRow(
              package: _retained,
              checked: false,
              onToggle: (_) {},
            ),
          ),
          const SizedBox(height: 10),
          SelectionSummaryBar(
            count: _selected ? 1 : 0,
            total: 18.75,
            currency: widget.config.currency,
            capabilities: widget.config.capabilities,
            onPickup: () {},
            onPay: () {},
            onDelivery: () {},
          ),
          _section('Calculadora'),
          _pad(
            Row(
              children: [
                Expanded(
                  child: BigNumberField(
                    label: 'Peso',
                    unit: widget.config.weightUnit,
                    controller: _weight,
                    hint: '0.0',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BigNumberField(
                    label: 'Valor FOB',
                    unit: r'US$',
                    unitLeading: true,
                    controller: _fob,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _pad(
            ProductSelector<String>(
              options: const ['Estándar', 'Carga General', 'Documentos'],
              value: _product,
              labelFor: (product) => product,
              onChange: (product) => setState(() => _product = product),
            ),
          ),
          const SizedBox(height: 10),
          _pad(
            TotalsPanel(
              subtotal: 15,
              tax: 3.75,
              total: 18.75,
              currency: widget.config.currency,
            ),
          ),
          const SizedBox(height: 10),
          _pad(
            ConceptTable(
              currency: widget.config.currency,
              concepts: const [
                CalcConceptView(
                  label: 'Flete Estándar',
                  amount: 15,
                  quantity: '2.50',
                  unitPrice: '3.50',
                ),
                CalcConceptView(
                  label: 'Servicios DGA',
                  amount: 3.75,
                  quantity: '2.50',
                  unitPrice: '0.50',
                ),
              ],
            ),
          ),
          _section('Contenido'),
          BannerCarousel(
            config: widget.config,
            banners: [
              BannerImage(
                registroId: '1',
                empresa: 'demo',
                imagenId: '',
                descripcion: 'Envíos internacionales',
                url: 'invalid://banner',
                deleted: false,
              ),
              BannerImage(
                registroId: '2',
                empresa: 'demo',
                imagenId: '',
                descripcion: 'Domicilio gratis',
                url: 'invalid://banner',
                deleted: false,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _pad(BranchCard(branch: branch, onTap: () {}, distance: '2.4 km')),
          _pad(
            const ServiceCard(
              title: 'Casillero en Miami',
              description: 'Contenido entregado por el backend.',
              glyph: BrandIcons.receptions,
            ),
          ),
          _pad(
            const FaqAccordion(
              question: '¿Cómo creo una pre-alerta?',
              answer: 'Respuesta entregada por el backend.',
              initiallyExpanded: true,
            ),
          ),
          _pad(
            NewsCard(
              news: Noticia(
                registroId: '1',
                empresa: 'demo',
                fecha: DateTime(2026, 8, 10),
                titulo: 'Nueva ruta directa a Santiago',
                resumen: 'Resumen entregado por el backend.',
                contenido: '',
                url: '',
                deleted: false,
              ),
              onTap: () {},
            ),
          ),
          _pad(
            MessageRow(
              message: Mensaje(
                registroId: '1',
                empresa: 'demo',
                fecha: DateTime(2026, 8, 10),
                titulo: '¡Bienvenido a la nueva app!',
                contenido: 'Contenido entregado por el backend.',
                deleted: false,
                read: false,
              ),
              onTap: () {},
            ),
          ),
          _section('Formularios'),
          _pad(const BrandField(label: 'Transportista', hint: 'Amazon')),
          const SizedBox(height: 10),
          _pad(
            const BrandDropZone(
              label: 'Toca para tomar foto o cargar factura (JPG, PNG, PDF)',
            ),
          ),
          const SizedBox(height: 10),
          _pad(BrandPrimaryButton(label: 'Enviar', onPressed: () {})),
          const SizedBox(height: 10),
          _pad(BrandOutlineButton(label: 'Cancelar', onPressed: () {})),
          _section('Carnet · estados'),
          _pad(Center(child: CarnetQR(accountCode: account.userAccount))),
          const SizedBox(height: 10),
          const BrandEmptyState(messageKey: 'no_resultados'),
          BrandErrorState(onRetry: () {}),
          const SizedBox(height: 10),
          const BrandSkeleton(rows: 2),
          _section('Sheets y diálogos'),
          _pad(
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                BrandOutlineButton(
                  label: 'Cuentas',
                  expand: false,
                  onPressed: () => showBrandSheet(
                    context,
                    scrollable: true,
                    child: AccountSwitcher(
                      accounts: [account],
                      activeAccount: account.userAccount,
                      onSelect: (_) {},
                      onDelete: (_) {},
                      onAdd: () {},
                    ),
                  ),
                ),
                BrandOutlineButton(
                  label: 'Retiro',
                  expand: false,
                  onPressed: () => showBrandSheet(
                    context,
                    child: PickupSheet(
                      modes: widget.config.capabilities.pickupModes,
                      count: 2,
                      onConfirm: (_) {},
                    ),
                  ),
                ),
                BrandOutlineButton(
                  label: 'Pago',
                  expand: false,
                  onPressed: () => showBrandSheet(
                    context,
                    child: PaymentSheet(
                      amount: r'$337.99',
                      brandName: widget.config.name,
                      onConfirm: () {},
                    ),
                  ),
                ),
                BrandOutlineButton(
                  label: 'Domicilio',
                  expand: false,
                  onPressed: () => showBrandSheet(
                    context,
                    child: DeliverySheet(count: 2, onConfirm: () {}),
                  ),
                ),
                BrandOutlineButton(
                  label: 'Sucursal',
                  expand: false,
                  onPressed: () => showBrandSheet(
                    context,
                    scrollable: true,
                    child: BranchSheet(
                      branch: branch,
                      whatsapp: '8494519103',
                      onCall: () {},
                      onWhatsApp: () {},
                      onEmail: () {},
                      onDirections: () {},
                    ),
                  ),
                ),
                BrandOutlineButton(
                  label: 'Confirmar',
                  expand: false,
                  onPressed: () => ConfirmDialog.show(
                    context,
                    title: 'Sus Cuentas',
                    message: 'Estas seguro que deseas BORRAR esta cuenta?',
                    destructive: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BrandSpace.xxl),
        ],
      ),
    );
  }

  Widget _pad(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: BrandSpace.lg),
        child: child,
      );

  Widget _section(String label) => _pad(BrandSectionLabel(label));

  Recepcion _sample({required bool retenido, bool disponible = false}) =>
      Recepcion(
        recepcionID: 'KR0100458321',
        fecha: '08-Aug-2026',
        producto: 'Estándar',
        suplidor: 'Amazon',
        cantidadPaquetes: 1,
        contenido: 'Cargador inalámbrico',
        enviadoPor: 'Amazon',
        totalPeso: '1.40',
        totalVolumen: '0',
        totalNeto: '64.50',
        estatus: disponible ? 'Disponible para Entrega' : 'Embarcado',
        retenido: retenido,
        disponible: disponible,
        paquetes: const [],
        fotoPaqueteSmallUrl: '',
        fotoPaqueteUrl: '',
        fotoFacturaUrl: '',
        fechaHora: '2026-08-08T10:00:00',
        progreso: disponible ? 4 : 2,
        numeroRastreo: 'KR0100458321',
      );

  Sucursal _sampleBranch() => Sucursal(
        registroId: '1',
        empresa: 'demo',
        nombre: 'Sucursal Miami Principal',
        codigo: 'MIA',
        direccion: '8220 NW 68th Street, Miami, FL 33195',
        ciudad: 'Miami',
        pais: 'Estados Unidos',
        horario: 'Lunes a viernes de 8:00am a 5:00pm.',
        telefonoOficina: '1-305-518-1831',
        telefonoVentas: '',
        email: 'miami@courier.com',
        imagenId: '',
        latitud: 25.8103,
        longitud: -80.3222,
        orden: 1,
        deleted: false,
      );
}
