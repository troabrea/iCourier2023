import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:empty_widget/empty_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:easy_mask/easy_mask.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get_it/get_it.dart';
import 'package:icourier/apps/appinfo.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/courier_service.dart';
import 'package:intl/intl.dart';
import '../../services/model/prealerta_model.dart';

import 'bloc/prepostalerta_bloc.dart';

class CrearPreAlertaPage extends StatefulWidget {
  const CrearPreAlertaPage({Key? key}) : super(key: key);

  @override
  State<CrearPreAlertaPage> createState() => _CrearPreAlertaPageState();

}

class _CrearPreAlertaPageState extends State<CrearPreAlertaPage> {
  final ImagePicker _picker = ImagePicker();
  final courierService = GetIt.I<CourierService>();
  final appInfo = GetIt.I<AppInfo>();
  final formatDate = DateFormat("yyyyMMdd");
  final prePostAlertaBloc = PrePostAlertaBloc(GetIt.I<CourierService>());
  late ScrollController controller;

  File? selectedFile;
  XFile? selectedImage;

  final transportistas = <String>[
    'Amazon',
    'DHL',
    'Fedex',
    'UPS',
    'USPS',
    'otro'.tr()
  ];
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 720,
      child: BlocProvider(
            create: (context) => prePostAlertaBloc,
            child: BlocBuilder<PrePostAlertaBloc,PrePostAlertaState>(
              builder: (context,state) {
              return Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: Text('crear_pre_alerta'.tr()),
                  actions: [
                    IconButton(onPressed: () => {Navigator.of(context).pop()}, icon: const Icon(Icons.close))
                  ],
                ),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: SafeArea(
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 65),
                      child: Column(
                        children: [
                          FormBuilder(
                            autovalidateMode: AutovalidateMode.disabled,
                            key: _formKey,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
                              child: Column(
                                children: [
                                  if(state is PrePostAlertaUpLoadingState)
                                    Container(padding: const EdgeInsets.only(top:200), child: const Center(child: CircularProgressIndicator(),))
                                  else if (state is PrePostAlertaDoneState)
                                    InkWell(onTap:() { Navigator.of(context).pop(); }, child: Container(padding: const EdgeInsets.only(top: 200), child: const Center(child: Icon(Icons.done_outline_sharp, size: 100,),)))
                                  else if (state is PrePostAlertaErrorState)
                                    InkWell(onTap:() { Navigator.of(context).pop(); },child: Container(padding: const EdgeInsets.only(top: 200), child: Center(child: Column(
                                      children: [
                                        Icon(Icons.error, size: 100, color: Theme.of(context).colorScheme.error),
                                        Text(state.errorMessage)
                                      ],
                                    ),)))
                                  else
                                    buildEntryForm(context, () async {

                                      if(_formKey.currentState?.saveAndValidate() ?? false) {

                                        var transportista = _formKey.currentState!.fields['transportista']!.value.toString();
                                        var tracking = _formKey.currentState!.fields['tracking']!.value.toString();
                                        var contenido = _formKey.currentState!.fields['contenido']!.value.toString();
                                        var proveedor = _formKey.currentState!.fields['proveedor']!.value.toString();
                                        var strValor = _formKey.currentState!.fields['valor']!.value.toString();
                                        strValor = strValor.replaceAll(',', '');
                                        var valor = double.parse(strValor);
                                        var fecha = formatDate.format(_formKey.currentState!.fields['fecha']!.value as DateTime);
                                        var xfile = selectedImage != null ? selectedImage! : XFile(selectedFile!.path) ;
                                        var preAlerta = PreAlertaModel("", "", transportista, tracking, valor, contenido, proveedor, fecha, "");
                                        prePostAlertaBloc.add(SendPreAlertaEvent(xfile,preAlerta));
                                      }
                                    }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          )
    ),
    );
  }

  Widget buildEntryForm(BuildContext context, void Function() onSend) {
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildTransportistaField(context),
          const SizedBox(height: 20),
          buildTrackingField(context),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                  width: MediaQuery.of(context).size.width * 0.35,
                  child: buildFechaFormField(context)),
              SizedBox(
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: buildValorFormField(context)),
              ]
          ),
          const SizedBox(height: 20),
          buildProveedorField(context),
          const SizedBox(height: 20),
          buildContenidoField(context),
          const SizedBox(height: 20,),
          Row(children: [
            SizedBox(width: MediaQuery.of(context).size.width * .5, child:Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(width: MediaQuery.of(context).size.width * .5,
                  child: FilledButton.icon(onPressed: () async {
                    selectedImage = await _picker.pickImage(source: ImageSource.gallery);
                    if(selectedImage != null) selectedFile = null;
                    setState(() {});
                  }, style: FilledButton.styleFrom( elevation: 0, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))), alignment: Alignment.center) , label: Text('cargar_imagen'.tr()),  icon: const Icon(Icons.image,)),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * .5,
                  child: FilledButton.icon(onPressed: () async {
                    selectedImage = await _picker.pickImage(source: ImageSource.camera);
                    if(selectedImage != null) selectedFile = null;
                    setState(() {});
                  },style: FilledButton.styleFrom( elevation: 0, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))), alignment: Alignment.center) , label: Text('tomar_foto'.tr(), ),  icon: const Icon(Icons.camera)),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * .5,
                  child: FilledButton.icon(onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'pdf', 'png','doc'],
                    );
                    if (result != null) {
                      selectedFile = result.paths.map((path) => File(path!)).first;
                      selectedImage = null;
                      setState(() {});
                    }
                  },style: FilledButton.styleFrom( elevation: 0, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))), alignment: Alignment.center) , label: Text('cargar_archivo'.tr(), ),  icon: const Icon(Icons.file_open,)),
                ),
              ],
            )),
            const Spacer(),
            if( selectedImage != null)
              SizedBox( height: 130, width: MediaQuery.of(context).size.width * .4,
                child: ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(30)), child: Image.file(File(selectedImage!.path), fit: BoxFit.fill,)) ),
            if(selectedFile != null)
              SizedBox( height: 130, width: MediaQuery.of(context).size.width * .4,
                  child: Center(child: Text(selectedFile!.uri.pathSegments.last)),),
            if(selectedFile == null && selectedImage == null)
              SizedBox( height: 130,width: MediaQuery.of(context).size.width * .4,
                child: EmptyWidget(
                  hideBackgroundAnimation: true,
                  subtitleTextStyle: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey),
                  title: " - ",
                  subTitle: "seleccione_foto_archivo".tr(),
                  titleTextStyle: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          ],),
          const SizedBox(height: 15,),
          const Divider(),
          FilledButton.icon(onPressed: (selectedImage == null && selectedFile == null) ? null : onSend,  label: Container( padding: const EdgeInsets.symmetric(horizontal: 5), child: Text('enviar_pre_alerta'.tr())), icon: Container( padding: const EdgeInsets.only(left: 5), child: const Icon(Icons.send))),
        ],

      ),
    );
  }

  FormBuilderDateTimePicker buildFechaFormField(BuildContext context) {
    return FormBuilderDateTimePicker (
      name: 'fecha',
      initialEntryMode: DatePickerEntryMode.calendar,
      format: DateFormat("dd-MMM-yyyy"),
      inputType: InputType.date,
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
      initialValue: DateTime.now(),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'Requerido'),
      ]),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(2),
        floatingLabelAlignment: FloatingLabelAlignment.center,
        labelText: 'fecha'.tr(),
        floatingLabelStyle:
        TextStyle(color: Theme.of(context).dividerColor),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(10)),
        focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
            borderRadius: BorderRadius.circular(10)),
        errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
            borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  FormBuilderTextField buildValorFormField(BuildContext context) {
    return FormBuilderTextField(
      name: 'valor',
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      initialValue: '0.00',
      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
      inputFormatters: [
        TextInputMask(
            mask: '9+,999.99',
            placeholder: '0',
            maxPlaceHolders: 2,
            reverse: true)
      ],
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: "requerido".tr()),
        FormBuilderValidators.min(0.01, errorText: "mayor_de_cero".tr()),
      ]),
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(2),
          labelText: 'valor_fob'.tr(),
          floatingLabelAlignment: FloatingLabelAlignment.center,
          floatingLabelStyle:
          TextStyle(color: Theme.of(context).dividerColor),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10)),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(10)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10)),
          prefixIcon: const Icon(Icons.attach_money_outlined),
          prefixIconColor: Theme.of(context).colorScheme.secondary),
    );
  }

  SizedBox buildContenidoField(BuildContext context) {
    return SizedBox(
        height: 60,
        child: FormBuilderTextField(
          name: 'contenido',
          initialValue: '',
          contextMenuBuilder: (context, editableTextState) {
            return AdaptiveTextSelectionToolbar.editableText(
              editableTextState: editableTextState,
            );
          },
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
          validator: FormBuilderValidators.compose(
              [FormBuilderValidators.required(errorText: 'requerido'.tr())]),
          valueTransformer: (val) => val?.toString(),
          decoration: InputDecoration(
            labelText: 'contenido'.tr(),
            hintText: 'contenido'.tr(),
            floatingLabelAlignment: FloatingLabelAlignment.center,
            floatingLabelStyle:
            TextStyle(color: Theme.of(context).dividerColor),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(15)),
            focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(15)),
            errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(15)),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(15)),
          ),
        )
    );
  }

  SizedBox buildProveedorField(BuildContext context) {
    return SizedBox(
        height: 60,
        child: FormBuilderTextField(
          name: 'proveedor',
          contextMenuBuilder: (context, editableTextState) {
            return AdaptiveTextSelectionToolbar.editableText(
              editableTextState: editableTextState,
            );
          },
          initialValue: '',
          validator: FormBuilderValidators.compose(
              [FormBuilderValidators.required(errorText: 'requerido'.tr())]),
          valueTransformer: (val) => val?.toString(),
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
          decoration: InputDecoration(
            labelText: 'proveedor'.tr(),
            hintText: 'proveedor'.tr(),
            floatingLabelAlignment: FloatingLabelAlignment.center,
            floatingLabelStyle:
            TextStyle(color: Theme.of(context).dividerColor),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(15)),
            focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(15)),
            errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(15)),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(15)),
          ),
        )
    );
  }

  SizedBox buildTrackingField(BuildContext context) {
    return SizedBox(
            height: 60,
            child: FormBuilderTextField(
              name: 'tracking',
              contextMenuBuilder: (context, editableTextState) {
                return AdaptiveTextSelectionToolbar.editableText(
                  editableTextState: editableTextState,
                );
              },
              initialValue: '',
              validator: FormBuilderValidators.compose(
                  [FormBuilderValidators.required(errorText: 'requerido'.tr())]),
              valueTransformer: (val) => val?.toString(),
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
              decoration: InputDecoration(
                labelText: 'Tracking',
                hintText: 'Tracking',
                floatingLabelAlignment: FloatingLabelAlignment.center,
                floatingLabelStyle:
                TextStyle(color: Theme.of(context).dividerColor),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(15)),
                focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                    borderRadius: BorderRadius.circular(15)),
                errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                    borderRadius: BorderRadius.circular(15)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(15)),
              ),
            )
        );
  }

  SizedBox buildTransportistaField(BuildContext context) {
    return SizedBox(
            height: 60,
            child: FormBuilderDropdown(
              name: 'transportista',
              initialValue: transportistas.first,
              validator: FormBuilderValidators.compose(
                  [FormBuilderValidators.required(errorText: 'requerido'.tr())]),
              valueTransformer: (val) => val?.toString(),
              decoration: InputDecoration(
                labelText: 'transportista'.tr(),
                hintText: 'seleccione_transportista'.tr(),
                floatingLabelAlignment: FloatingLabelAlignment.center,
                floatingLabelStyle:
                TextStyle(color: Theme.of(context).dividerColor),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(15)),
                focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                    borderRadius: BorderRadius.circular(15)),
                errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                    borderRadius: BorderRadius.circular(15)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(15)),
              ),
              items: transportistas
                  .map((gender) => DropdownMenuItem(
                        alignment: AlignmentDirectional.center,
                        value: gender,
                        child: Text(gender),
                      ))
                  .toList(),
            )
        );
  }
}
