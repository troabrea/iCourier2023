import 'package:flutter/material.dart';

import '../domain/package_stage.dart';
import '../services/model/banner.dart';
import '../services/model/login_model.dart';
import '../services/model/mensaje.dart';
import '../services/model/noticia.dart';
import '../services/model/recepcion.dart';
import '../services/model/sucursal.dart';
import '../theme/brand_config.dart';
import 'brand_states.dart';
import 'calculator_components.dart';
import 'content_components.dart';
import 'core_components.dart';
import 'overlay_components.dart';

class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key, required this.config});

  final BrandConfig config;

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  final _numberController = TextEditingController(text: '2.50');
  var _product = 'Aéreo';
  var _selected = false;

  late final _history = Historia(
    paqueteID: 'PK-1',
    nombreEstatus: 'Embarcado',
    fecha: '10-08-2026 | 10:00 AM',
    ciudad: 'Miami',
    fechaHora: '2026-08-10T10:00:00',
  );
  late final _package = Recepcion(
    recepcionID: 'RD-10458321',
    fecha: '2026-08-10',
    producto: 'Aéreo',
    suplidor: 'Amazon',
    cantidadPaquetes: 1,
    contenido: 'Artículos personales',
    enviadoPor: 'Amazon',
    totalPeso: '2.50',
    totalVolumen: '0',
    totalNeto: '18.75',
    estatus: 'Embarcado',
    retenido: false,
    disponible: false,
    paquetes: [
      Paquetes(
        paqueteID: 'PK-1',
        recepcionID: 'RD-10458321',
        suplidor: 'Amazon',
        libras: '2.50',
        mercancia: 'Artículos personales',
        rastreo: '1Z999',
        status: 'Embarcado',
        urlTracking: '',
        historia: [],
      ),
    ],
    fotoPaqueteSmallUrl: '',
    fotoPaqueteUrl: '',
    fotoFacturaUrl: '',
    fechaHora: '2026-08-10T10:00:00',
    progreso: 2,
    numeroRastreo: '1Z999AA10123456784',
  );

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branch = _sampleBranch();
    final account = UserAccount(
      sessionId: 'session',
      nombre: 'María Rodríguez',
      userAccount: 'KR-002332',
      password: 'password',
    );
    return Scaffold(
      appBar: const ScreenHeader(title: 'Component Gallery'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BrandHeader(
            greeting: 'Bienvenido',
            account: account.userAccount,
            points: 1280,
            unread: 3,
            capabilities: widget.config.capabilities,
          ),
          _gap,
          QuickActionGrid(
            actions: [
              QuickAction(
                label: 'Pre-alerta',
                icon: Icons.add_alert_outlined,
                onTap: () {},
              ),
              QuickAction(
                label: 'Rastreo',
                icon: Icons.search,
                onTap: () {},
              ),
              QuickAction(
                label: 'Pago',
                icon: Icons.payment,
                onTap: () {},
              ),
              QuickAction(
                label: 'Carnet',
                icon: Icons.badge_outlined,
                onTap: () {},
              ),
            ],
          ),
          _gap,
          BannerCarousel(
            config: widget.config,
            banners: [
              BannerImage(
                registroId: '1',
                empresa: 'demo',
                imagenId: '',
                descripcion: 'Banner remoto con fallback de marca',
                url: 'invalid://banner',
                deleted: false,
              ),
            ],
          ),
          _gap,
          PackageCard(package: _package),
          _gap,
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(stage: PackageStage.origen),
              StatusBadge(stage: PackageStage.disponible),
              StatusBadge(stage: PackageStage.disponible, retained: true),
              StatusBadge(stage: PackageStage.entregado),
            ],
          ),
          _gap,
          const MacroStepper(stage: PackageStage.destino),
          _gap,
          EventTimeline(events: [_history], stage: PackageStage.ruta),
          _gap,
          SelectableRow(
            package: _package,
            checked: _selected,
            onToggle: (value) => setState(() => _selected = value),
          ),
          SelectionSummaryBar(
            count: _selected ? 1 : 0,
            total: 18.75,
            currency: widget.config.currency,
            paymentsEnabled: true,
            onPay: () {},
          ),
          GroupRow(label: 'Recepciones', count: 4, onTap: () {}),
          ProductSelector<String>(
            options: const ['Aéreo', 'Marítimo', 'Express'],
            value: _product,
            labelFor: (product) => product,
            onChange: (product) => setState(() => _product = product),
          ),
          _gap,
          BigNumberField(
            label: 'Peso',
            unit: widget.config.weightUnit,
            controller: _numberController,
          ),
          _gap,
          TotalsPanel(
            subtotal: 15,
            tax: 3.75,
            total: 18.75,
            currency: widget.config.currency,
          ),
          _gap,
          ConceptTable(
            currency: widget.config.currency,
            concepts: const [
              CalcConceptView(label: 'Flete', amount: 15),
              CalcConceptView(label: 'Impuestos', amount: 3.75),
            ],
          ),
          _gap,
          BranchCard(branch: branch),
          _gap,
          const ServiceCard(
            title: 'Consolidación',
            description: 'Contenido entregado por el backend.',
          ),
          _gap,
          const FaqAccordion(
            question: '¿Cómo funciona?',
            answer: 'Respuesta entregada por el backend.',
          ),
          _gap,
          NewsCard(
            news: Noticia(
              registroId: '1',
              empresa: 'demo',
              fecha: DateTime(2026, 8, 10),
              titulo: 'Noticia',
              resumen: 'Resumen entregado por el backend.',
              contenido: '',
              url: '',
              deleted: false,
            ),
          ),
          _gap,
          MessageRow(
            message: Mensaje(
              registroId: '1',
              empresa: 'demo',
              fecha: DateTime(2026, 8, 10),
              titulo: 'Mensaje',
              contenido: 'Contenido entregado por el backend.',
              deleted: false,
              read: false,
            ),
          ),
          _gap,
          const TipBubble(message: 'Ayuda contextual del primer arranque.'),
          _gap,
          const BrandEmptyState(messageKey: 'no_resultados'),
          _gap,
          CarnetQR(accountCode: account.userAccount),
          _gap,
          AccountSwitcher(
            accounts: [account],
            activeAccount: account.userAccount,
            onSelect: (account) {},
            onDelete: (account) {},
            onAdd: () {},
          ),
        ],
      ),
    );
  }

  Sucursal _sampleBranch() => Sucursal(
        registroId: '1',
        empresa: 'demo',
        nombre: 'Sucursal Principal',
        codigo: 'SDQ',
        direccion: 'Dirección entregada por el backend',
        ciudad: 'Santo Domingo',
        pais: 'República Dominicana',
        horario: 'Lunes a viernes',
        telefonoOficina: '809-000-0000',
        telefonoVentas: '',
        email: '',
        imagenId: '',
        latitud: 18.4861,
        longitud: -69.9312,
        orden: 1,
        deleted: false,
      );

  static const _gap = SizedBox(height: 16);
}
