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
import '../services/model/postalerta_model.dart';
import '../services/model/recepcion.dart';
import '../theme/brand_tokens.dart';
import 'bloc/prepostalerta_bloc.dart';

/// Attaches the invoice a retained package is missing.
///
/// Back returns to the package detail, not to the home screen.
class CrearPostAlertaPage extends StatefulWidget {
  const CrearPostAlertaPage({super.key, required this.recepcion});

  final Recepcion recepcion;

  @override
  State<CrearPostAlertaPage> createState() => _CrearPostAlertaPageState();
}

class _CrearPostAlertaPageState extends State<CrearPostAlertaPage> {
  final _formKey = GlobalKey<FormState>();
  final _value = TextEditingController(text: '0.00');
  final _picker = ImagePicker();
  late final PrePostAlertaBloc _bloc;
  XFile? _document;

  @override
  void initState() {
    super.initState();
    _bloc = PrePostAlertaBloc(GetIt.I<CourierService>());
  }

  @override
  void dispose() {
    _value.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: 'crear_post_alerta'.tr(),
        titleSize: 18,
        onBack: context.popOrHome,
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<PrePostAlertaBloc, PrePostAlertaState>(
          builder: (context, state) {
            if (state is PrePostAlertaUpLoadingState) {
              return const BrandSkeleton(rows: 4);
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
                  BrandCard(
                    color: tokens.surfaceAlt,
                    borderColor: tokens.surfaceAlt,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 13,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recepcion.numeroRastreo.isEmpty
                              ? widget.recepcion.recepcionID
                              : widget.recepcion.numeroRastreo,
                          style: tokens.body(11, color: tokens.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.recepcion.contenido,
                          style: tokens.body(15, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BrandSpace.md),
                  _FobField(controller: _value),
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
                    label: 'enviar_post_alerta'.tr(),
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

  Future<void> _pickDocument() async {
    final choice = await showModalBottomSheet<_DocumentSource>(
      context: context,
      backgroundColor: context.brand.surface,
      barrierColor: context.brand.modalScrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BrandShape.sheet),
        ),
      ),
      builder: (context) => const _DocumentSourceSheet(),
    );
    if (choice == null || !mounted) {
      return;
    }
    switch (choice) {
      case _DocumentSource.gallery:
        await _pickImage(ImageSource.gallery);
      case _DocumentSource.camera:
        await _pickImage(ImageSource.camera);
      case _DocumentSource.file:
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
      SendPostAlertaEvent(
        _document!,
        PostAlertaModel(
          '',
          '',
          widget.recepcion.recepcionID,
          double.parse(_value.text),
          '',
        ),
      ),
    );
  }
}

enum _DocumentSource { gallery, camera, file }

class _DocumentSourceSheet extends StatelessWidget {
  const _DocumentSourceSheet();

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BrandSpace.lg,
          BrandSpace.lg,
          BrandSpace.lg,
          BrandSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrandSheetGrabber(),
            Text('seleccione_foto_archivo'.tr(), style: tokens.head(17)),
            const SizedBox(height: BrandSpace.md),
            BrandOutlineButton(
              label: 'cargar_imagen'.tr(),
              onPressed: () =>
                  Navigator.of(context).pop(_DocumentSource.gallery),
            ),
            const SizedBox(height: BrandSpace.xs),
            BrandOutlineButton(
              label: 'tomar_foto'.tr(),
              onPressed: () => Navigator.of(context).pop(_DocumentSource.camera),
            ),
            const SizedBox(height: BrandSpace.xs),
            BrandOutlineButton(
              label: 'cargar_archivo'.tr(),
              onPressed: () => Navigator.of(context).pop(_DocumentSource.file),
            ),
          ],
        ),
      ),
    );
  }
}

/// FOB amount, required and greater than zero.
class _FobField extends StatelessWidget {
  const _FobField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'valor_fob'.tr(),
          style: tokens.body(
            12,
            weight: FontWeight.w600,
            color: tokens.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: tokens.body(14, weight: FontWeight.w500),
          validator: (value) {
            final amount = double.tryParse(value ?? '');
            return amount == null || amount <= 0 ? 'mayor_de_cero'.tr() : null;
          },
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
        ),
      ],
    );
  }
}

/// Confirmation after the invoice is accepted.
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
            Text('enviar_post_alerta'.tr(), style: tokens.head(18)),
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
