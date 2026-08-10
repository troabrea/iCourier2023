import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../services/courier_service.dart';
import '../services/model/prealerta_model.dart';
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
  String _carrier = 'Amazon';

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      appBar: ScreenHeader(title: 'crear_pre_alerta'.tr()),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<PrePostAlertaBloc, PrePostAlertaState>(
          builder: (context, state) {
            if (state is PrePostAlertaUpLoadingState) {
              return const BrandSkeleton(rows: 5);
            }
            if (state is PrePostAlertaDoneState) {
              return _ResultState(
                icon: Icons.check_circle_outline,
                message: 'crear_prealerta'.tr(),
              );
            }
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _carrier,
                    decoration: InputDecoration(
                      labelText: 'transportista'.tr(),
                    ),
                    items:
                        ['Amazon', 'DHL', 'Fedex', 'UPS', 'USPS', 'otro'.tr()]
                            .map(
                              (carrier) => DropdownMenuItem(
                                value: carrier,
                                child: Text(carrier),
                              ),
                            )
                            .toList(growable: false),
                    onChanged: (value) => _carrier = value ?? _carrier,
                  ),
                  const SizedBox(height: 16),
                  _RequiredField(
                    controller: _tracking,
                    label: 'numero_rastreo'.tr(),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      '${'fecha'.tr()} · ${DateFormat.yMd().format(_date)}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _value,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: 'valor_fob'.tr()),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      return amount == null || amount <= 0
                          ? 'mayor_de_cero'.tr()
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _RequiredField(
                    controller: _supplier,
                    label: 'proveedor'.tr(),
                  ),
                  const SizedBox(height: 16),
                  _RequiredField(
                    controller: _content,
                    label: 'contenido'.tr(),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  _DocumentPicker(
                    document: _document,
                    onGallery: () => _pickImage(ImageSource.gallery),
                    onCamera: () => _pickImage(ImageSource.camera),
                    onFile: _pickFile,
                  ),
                  if (state is PrePostAlertaErrorState) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _document == null ? null : _submit,
                    icon: const Icon(Icons.send_outlined),
                    label: Text('enviar_pre_alerta'.tr()),
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
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickImage(ImageSource source) async {
    final selected = await _picker.pickImage(source: source);
    if (selected != null) setState(() => _document = selected);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'pdf', 'png', 'doc', 'docx'],
    );
    final path = result?.files.single.path;
    if (path != null) setState(() => _document = XFile(path));
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

class _RequiredField extends StatelessWidget {
  const _RequiredField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value?.trim().isEmpty ?? true ? 'requerido'.tr() : null,
    );
  }
}

class _DocumentPicker extends StatelessWidget {
  const _DocumentPicker({
    required this.document,
    required this.onGallery,
    required this.onCamera,
    required this.onFile,
  });

  final XFile? document;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              document?.name ?? 'seleccione_foto_archivo'.tr(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                IconButton(
                  tooltip: 'cargar_imagen'.tr(),
                  onPressed: onGallery,
                  icon: const Icon(Icons.image_outlined),
                ),
                IconButton(
                  tooltip: 'tomar_foto'.tr(),
                  onPressed: onCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                ),
                IconButton(
                  tooltip: 'cargar_archivo'.tr(),
                  onPressed: onFile,
                  icon: const Icon(Icons.file_open_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultState extends StatelessWidget {
  const _ResultState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64),
          const SizedBox(height: 12),
          Text(message),
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            child: Text('aceptar'.tr()),
          ),
        ],
      ),
    );
  }
}
