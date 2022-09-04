import 'dart:io';

import 'package:empty_widget/empty_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_mask/easy_mask.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_image_picker/form_builder_image_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:navbar_router/navbar_router.dart';

import 'package:sampleapi/calculadora/bloc/calculadora_bloc.dart';
import 'package:sampleapi/services/courierService.dart';
import 'package:intl/intl.dart';
import 'package:sampleapi/services/model/calculadora_model.dart';
import 'package:sampleapi/services/model/prealerta_model.dart';

import 'bloc/prepostalerta_bloc.dart';

class CrearPreAlertaPage extends StatefulWidget {
  const CrearPreAlertaPage({Key? key}) : super(key: key);

  @override
  State<CrearPreAlertaPage> createState() => _CrearPreAlertaPageState();

}

class _CrearPreAlertaPageState extends State<CrearPreAlertaPage> {
  final ImagePicker _picker = ImagePicker();
  final courierService = GetIt.I<CourierService>();
  final formatDate = DateFormat("yyyyMMdd");
  final prePostAlertaBloc = PrePostAlertaBloc(GetIt.I<CourierService>());
  final ScrollController controller = ScrollController();

  File? selectedFile;
  XFile? selectedImage;

  final transportistas = <String>[
    'Amazon',
    'DHL',
    'Fedex',
    'UPS',
    'USPS',
    'Otro'
  ];
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 720,
      child: Scaffold(
          appBar: AppBar(title: const Text("Creación de Pre-Alerta"),
          automaticallyImplyLeading: false,
          ),
          body: BlocProvider(
            create: (context) => prePostAlertaBloc,
            child: BlocBuilder<PrePostAlertaBloc,PrePostAlertaState>(
              builder: (context,state) {
              return GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                onVerticalDragEnd: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 65),
                      child: FormBuilder(
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
                                InkWell(onTap:() { Navigator.of(context).pop(); },child: Container(padding: const EdgeInsets.only(top: 200), child: Center(child: Icon(Icons.done_outline_sharp, size: 100, color: Theme.of(context).errorColor),)))
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
                    ),
                  ),
                ),
              );
            }
          )
    ),
    ));
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
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: buildFechaFormField(context)),
              SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
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
                  child: ElevatedButton.icon(onPressed: () async {
                    selectedImage = await _picker.pickImage(source: ImageSource.gallery);
                    if(selectedImage != null) selectedFile = null;
                    setState(() {});
                  }, style: ElevatedButton.styleFrom( elevation: 0, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12))), alignment: Alignment.centerLeft) , label: const Text('Cargar Imagen'),  icon: const Icon(Icons.image,)),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * .5,
                  child: ElevatedButton.icon(onPressed: () async {
                    selectedImage = await _picker.pickImage(source: ImageSource.camera);
                    if(selectedImage != null) selectedFile = null;
                    setState(() {});
                  },style: ElevatedButton.styleFrom( elevation: 0, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12))), alignment: Alignment.centerLeft) , label: const Text('Tomar Foto', ),  icon: const Icon(Icons.camera)),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * .5,
                  child: ElevatedButton.icon(onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'pdf', 'png','doc'],
                    );
                    if (result != null) {
                      selectedFile = result.paths.map((path) => File(path!)).first;
                      selectedImage = null;
                      setState(() {});
                    }
                  },style: ElevatedButton.styleFrom( elevation: 0, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12))), alignment: Alignment.centerLeft) , label: const Text('Cargar Archivo', ),  icon: const Icon(Icons.file_open,)),
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
                  subTitle: "Seleccione imágen o archivo",
                ),
              ),

          ],),
          const SizedBox(height: 15,),
          const Divider(),
          ElevatedButton.icon(onPressed: (selectedImage == null && selectedFile == null) ? null : onSend,  label: const Text('Enviar Pre-Alerta'), icon: const Icon(Icons.send)),
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
      initialValue: DateTime.now(),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'Requerido'),
      ]),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(2),
        floatingLabelAlignment: FloatingLabelAlignment.center,
        labelText: 'Fecha',
        floatingLabelStyle:
        TextStyle(color: Theme.of(context).primaryColorDark),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
            borderRadius: BorderRadius.circular(10)),
        focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).errorColor),
            borderRadius: BorderRadius.circular(10)),
        errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).errorColor),
            borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
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
      inputFormatters: [
        TextInputMask(
            mask: '9+,999.99',
            placeholder: '0',
            maxPlaceHolders: 2,
            reverse: true)
      ],
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: "Requerido"),
        FormBuilderValidators.min(0.01, errorText: "Mayor de cero."),
      ]),
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(2),
          labelText: 'Valor FOB',
          floatingLabelStyle:
          TextStyle(color: Theme.of(context).primaryColorDark),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
              borderRadius: BorderRadius.circular(10)),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).errorColor),
              borderRadius: BorderRadius.circular(10)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).errorColor),
              borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
              borderRadius: BorderRadius.circular(10)),
          prefixIcon: const Icon(Icons.attach_money_outlined),
          prefixIconColor: Theme.of(context).primaryColorDark),
    );
  }

  SizedBox buildContenidoField(BuildContext context) {
    return SizedBox(
        height: 60,
        child: FormBuilderTextField(
          name: 'contenido',
          initialValue: '',
          validator: FormBuilderValidators.compose(
              [FormBuilderValidators.required(errorText: 'Requerido')]),
          valueTransformer: (val) => val?.toString(),
          decoration: InputDecoration(
            labelText: 'Contenido',
            hintText: 'Contenido',
            floatingLabelAlignment: FloatingLabelAlignment.center,
            floatingLabelStyle:
            TextStyle(color: Theme.of(context).primaryColorDark),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
                borderRadius: BorderRadius.circular(15)),
            focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).errorColor),
                borderRadius: BorderRadius.circular(15)),
            errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).errorColor),
                borderRadius: BorderRadius.circular(15)),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
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
          initialValue: '',
          validator: FormBuilderValidators.compose(
              [FormBuilderValidators.required(errorText: 'Requerido')]),
          valueTransformer: (val) => val?.toString(),
          decoration: InputDecoration(
            labelText: 'Proveedor',
            hintText: 'Proveedor',
            floatingLabelAlignment: FloatingLabelAlignment.center,
            floatingLabelStyle:
            TextStyle(color: Theme.of(context).primaryColorDark),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
                borderRadius: BorderRadius.circular(15)),
            focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).errorColor),
                borderRadius: BorderRadius.circular(15)),
            errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).errorColor),
                borderRadius: BorderRadius.circular(15)),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
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
              initialValue: '',
              validator: FormBuilderValidators.compose(
                  [FormBuilderValidators.required(errorText: 'Requerido')]),
              valueTransformer: (val) => val?.toString(),
              decoration: InputDecoration(
                labelText: 'Tracking',
                hintText: 'Tracking',
                floatingLabelAlignment: FloatingLabelAlignment.center,
                floatingLabelStyle:
                TextStyle(color: Theme.of(context).primaryColorDark),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
                    borderRadius: BorderRadius.circular(15)),
                focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).errorColor),
                    borderRadius: BorderRadius.circular(15)),
                errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).errorColor),
                    borderRadius: BorderRadius.circular(15)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
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
                  [FormBuilderValidators.required(errorText: 'Requerido')]),
              valueTransformer: (val) => val?.toString(),
              decoration: InputDecoration(
                labelText: 'Transportista',
                hintText: 'Seleccione transportista',
                floatingLabelAlignment: FloatingLabelAlignment.center,
                floatingLabelStyle:
                TextStyle(color: Theme.of(context).primaryColorDark),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
                    borderRadius: BorderRadius.circular(15)),
                focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).errorColor),
                    borderRadius: BorderRadius.circular(15)),
                errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).errorColor),
                    borderRadius: BorderRadius.circular(15)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
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
