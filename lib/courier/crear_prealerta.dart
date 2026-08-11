import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../design_system/brand_foundations.dart';
import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../navigation/app_routes.dart';
import '../design_system/overlay_components.dart';
import '../services/courier_service.dart';
import '../services/model/prealerta_model.dart';
import '../theme/brand_tokens.dart';
import 'bloc/prepostalerta_bloc.dart';

class CrearPreAlertaPage extends StatefulWidget {
  const CrearPreAlertaPage({super.key});

  @override
  State<CrearPreAlertaPage> createState() => _CrearPreAlertaPageState();
}

class _CrearPreAlertaPageState extends State<CrearPreAlertaPage> {
  final _formKey = GlobalKey<FormState>();
  final _tracking = TextEditingController();
  final _value = TextEditingController(text: '0.00');
  final _supplier = TextEditingController();
  final _content = TextEditingController();
  final _picker = ImagePicker();
  late final PrePostAlertaBloc _bloc;
  XFile? _document;
  DateTime _date = DateTime.now();
  late String _carrier;

  late final List<String> _carriers = [
    'Amazon',
    'DHL',
    'Fedex',
    'UPS',
    'USPS',
    'otro'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    _carrier = 'Amazon';
    _bloc = PrePostAlertaBloc(GetIt.I<CourierService>());
  }

  @override
  void dispose() {
    _tracking.dispose();
    _value.dispose();
    _supplier.dispose();
    _content.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: 'crear_pre_alerta'.tr(),
        titleSize: 18,
        onBack: context.popOrHome,
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<PrePostAlertaBloc, PrePostAlertaState>(
          builder: (context, state) {
            if (state is PrePostAlertaUpLoadingState) {
              return const BrandSkeleton(rows: 5);
            }
            if (state is PrePostAlertaDoneState) {
              return _Success(onClose: () => Navigator.maybePop(context));
            }
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  BrandSpace.lg,
                  18,
                  BrandSpace.lg,
                  BrandTabBar.height,
                ),
                children: [
                  _Label('transportista'.tr()),
                  _CarrierField(
                    value: _carrier,
                    options: _carriers,
                    onChanged: (value) => setState(() => _carrier = value),
                  ),
                  const SizedBox(height: BrandSpace.sm),
                  _Label('numero_rastreo'.tr()),
                  BrandField(
                    controller: _tracking,
                    hint: '1Z999AA10123456784',
                  ),
                  const SizedBox(height: BrandSpace.sm),
                  _Label('fecha'.tr()),
                  _DateField(date: _date, onTap: _pickDate),
                  const SizedBox(height: BrandSpace.sm),
                  _Label('valor_fob'.tr()),
                  BrandField(
                    controller: _value,
                    hint: '0.00',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: BrandSpace.sm),
                  _Label('proveedor'.tr()),
                  BrandField(controller: _supplier),
                  const SizedBox(height: BrandSpace.sm),
                  _Label('contenido'.tr()),
                  BrandField(controller: _content, maxLines: 3),
                  const SizedBox(height: BrandSpace.md),
                  BrandDropZone(
                    label: _document?.name ?? 'toca_para_cargar_factura'.tr(),
                    onTap: _pickDocument,
                  ),
                  if (state is PrePostAlertaErrorState) ...[
                    const SizedBox(height: BrandSpace.sm),
                    Text(
                      state.errorMessage,
                      style: tokens.body(
                        12,
                        weight: FontWeight.w600,
                        color: tokens.danger,
                      ),
                    ),
                  ],
                  const SizedBox(height: BrandSpace.md),
                  BrandPrimaryButton(
                    label: 'enviar_pre_alerta'.tr(),
                    onPressed: _document == null ? null : _submit,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  Future<void> _pickDocument() async {
    final choice = await showBrandSheet<_Source>(
      context,
      child: const _SourceSheet(),
    );
    if (choice == null || !mounted) {
      return;
    }
    switch (choice) {
      case _Source.gallery:
        await _pickImage(ImageSource.gallery);
      case _Source.camera:
        await _pickImage(ImageSource.camera);
      case _Source.file:
        await _pickFile();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final selected = await _picker.pickImage(source: source);
    if (selected != null && mounted) {
      setState(() => _document = selected);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'pdf', 'png', 'doc', 'docx'],
    );
    final path = result?.files.single.path;
    if (path != null && mounted) {
      setState(() => _document = XFile(path));
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false) || _document == null) {
      return;
    }
    _bloc.add(
      SendPreAlertaEvent(
        _document!,
        PreAlertaModel(
          '',
          '',
          _carrier,
          _tracking.text.trim(),
          double.parse(_value.text),
          _content.text.trim(),
          _supplier.text.trim(),
          DateFormat('yyyyMMdd').format(_date),
          '',
        ),
      ),
    );
  }
}

enum _Source { gallery, camera, file }

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: tokens.body(
          12,
          weight: FontWeight.w600,
          color: tokens.textMuted,
        ),
      ),
    );
  }
}

class _CarrierField extends StatelessWidget {
  const _CarrierField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return DropdownButtonFormField<String>(
      initialValue: value,
      style: tokens.body(14, weight: FontWeight.w500),
      dropdownColor: tokens.surface,
      icon: Icon(Icons.expand_more, color: tokens.textMuted),
      items: options
          .map(
            (carrier) => DropdownMenuItem(
              value: carrier,
              child: Text(carrier),
            ),
          )
          .toList(growable: false),
      onChanged: (selected) => onChanged(selected ?? value),
      decoration: InputDecoration(
        filled: true,
        fillColor: tokens.surface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          borderSide: BorderSide(color: tokens.primary, width: 2),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return BrandCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('dd-MMM-yyyy').format(date),
              style: tokens.body(14, weight: FontWeight.w500),
            ),
          ),
          Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: tokens.textMuted,
          ),
        ],
      ),
    );
  }
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) => BrandSheet(
        title: 'seleccione_foto_archivo'.tr(),
        children: [
          BrandOutlineButton(
            label: 'cargar_imagen'.tr(),
            onPressed: () => Navigator.of(context).pop(_Source.gallery),
          ),
          const SizedBox(height: BrandSpace.xs),
          BrandOutlineButton(
            label: 'tomar_foto'.tr(),
            onPressed: () => Navigator.of(context).pop(_Source.camera),
          ),
          const SizedBox(height: BrandSpace.xs),
          BrandOutlineButton(
            label: 'cargar_archivo'.tr(),
            onPressed: () => Navigator.of(context).pop(_Source.file),
          ),
        ],
      );
}

class _Success extends StatelessWidget {
  const _Success({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BrandSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.accentWash(tokens.success),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, size: 32, color: tokens.success),
            ),
            const SizedBox(height: BrandSpace.md),
            Text(
              'enviar_pre_alerta'.tr(),
              textAlign: TextAlign.center,
              style: tokens.head(18),
            ),
            const SizedBox(height: BrandSpace.md),
            BrandOutlineButton(
              label: 'aceptar'.tr(),
              expand: false,
              pill: true,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
