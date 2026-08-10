import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../design_system/brand_states.dart';
import '../design_system/core_components.dart';
import '../services/courier_service.dart';
import '../services/model/postalerta_model.dart';
import '../services/model/recepcion.dart';
import 'bloc/prepostalerta_bloc.dart';

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
    return Scaffold(
      appBar: ScreenHeader(title: 'crear_post_alerta'.tr()),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<PrePostAlertaBloc, PrePostAlertaState>(
          builder: (context, state) {
            if (state is PrePostAlertaUpLoadingState) {
              return const BrandSkeleton(rows: 4);
            }
            if (state is PrePostAlertaDoneState) {
              return Center(
                child: IconButton(
                  tooltip: 'aceptar'.tr(),
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.check_circle_outline, size: 64),
                ),
              );
            }
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: ListTile(
                      title: Text(widget.recepcion.numeroRastreo),
                      subtitle: Text(widget.recepcion.contenido),
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
                  Card(
                    child: ListTile(
                      title: Text(
                        _document?.name ?? 'seleccione_foto_archivo'.tr(),
                      ),
                      subtitle: Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.image_outlined),
                            label: Text('cargar_imagen'.tr()),
                          ),
                          TextButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text('tomar_foto'.tr()),
                          ),
                          TextButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.file_open_outlined),
                            label: Text('cargar_archivo'.tr()),
                          ),
                        ],
                      ),
                    ),
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
                    label: Text('enviar_post_alerta'.tr()),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
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
