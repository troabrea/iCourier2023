import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get_it/get_it.dart';
import 'package:sampleapi/preguntas/bloc/preguntas_bloc.dart';
import 'package:sampleapi/services/app_events.dart';
import 'package:sampleapi/services/courierService.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/courier_bloc.dart';
import 'courier_dashboard.dart';
import 'courierappbar.dart';

class CourierPage extends StatefulWidget {
  const CourierPage({Key? key}) : super(key: key);

  @override
  State<CourierPage> createState() => _CourierPageState();
}

class _CourierPageState extends State<CourierPage> {
  final courierBloc = CourierBloc(CourierIsBusyState());
  final ScrollController controller = ScrollController();

  bool isBusy = false;

  String userName = "";
  String password = "";

  final _formKey = GlobalKey<FormBuilderState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CourierAppBar(),
        body: BlocProvider(
            create: (context) => courierBloc..add(CheckLoggedEvent()),
            child: BlocBuilder<CourierBloc, CourierState>(
                builder: (context, state) {
              if (state is CourierIsBusyState) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (state is CourierIsNotLoggedState) {
                return loginPage(context, state.showError);
              }
              if (state is CourierIsLoggedState) {
                return const CourierDashboard();
              }
              return Container();
            })));
  }

  FormBuilderTextField buildPasswordFormField(
      BuildContext context, String initialValue) {
    return FormBuilderTextField(
      name: 'password',
      keyboardType: TextInputType.text,
      initialValue: initialValue,
      textAlign: TextAlign.center,
      obscureText: true,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'Requerido'),
      ]),
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(2),
          hintText: 'Contraseña',
          hintStyle: TextStyle(color: Theme.of(context).primaryColorDark),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
              borderRadius: BorderRadius.circular(30)),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).errorColor),
              borderRadius: BorderRadius.circular(30)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).errorColor),
              borderRadius: BorderRadius.circular(30)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
              borderRadius: BorderRadius.circular(30)),
          prefixIcon: const Icon(Icons.key),
          prefixIconColor: Theme.of(context).primaryColorDark),
    );
  }

  FormBuilderTextField buildUserAccountFormField(
      BuildContext context, String initialValue) {
    return FormBuilderTextField(
      name: 'user',
      keyboardType: TextInputType.text,
      textAlign: TextAlign.center,
      initialValue: initialValue,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'Requerido'),
      ]),
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(2),
          hintText: 'Nombre de usuario',
          hintStyle: TextStyle(color: Theme.of(context).primaryColorDark),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
              borderRadius: BorderRadius.circular(30)),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).errorColor),
              borderRadius: BorderRadius.circular(30)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).errorColor),
              borderRadius: BorderRadius.circular(30)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColorDark),
              borderRadius: BorderRadius.circular(30)),
          prefixIcon: const Icon(Icons.person),
          prefixIconColor: Theme.of(context).primaryColorDark),
    );
  }

  Widget loginPage(BuildContext context, bool showError) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(bottom: 65),
        child: SingleChildScrollView(
          controller: controller,
          child: FormBuilder(
            autovalidateMode: AutovalidateMode.disabled,
            key: _formKey,
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * .8,
                child: Column(
                  children: [
                    SizedBox(
                        height: 150,
                        child: Image.asset(
                          "images/brand_logo.png",
                          fit: BoxFit.scaleDown,
                        )),
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      'Bienvenido',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(fontSize: 26),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Favor indicar las credenciales para acceder a su cuenta.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 30),
                    buildUserAccountFormField(context, userName),
                    const SizedBox(height: 30),
                    buildPasswordFormField(context, password),
                    if (showError)
                      const SizedBox(
                        height: 20,
                      ),
                    if (showError)
                      AutoSizeText(
                        "Usuario ó contraseña inválido, favor verificar",
                        maxLines: 1,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: Theme.of(context).errorColor),
                      ),
                    const SizedBox(height: 60),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * .6,
                        child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15)),
                            icon: isBusy
                                ? const CircularProgressIndicator()
                                : const Icon(Icons.login),
                            onPressed: isBusy ? null : onSubmitLogin,
                            onLongPress: () async {
                              if (_formKey.currentState!.saveAndValidate()) {
                                userName = _formKey
                                    .currentState!.fields['user']!.value
                                    .toString();
                                password = _formKey
                                    .currentState!.fields['password']!.value
                                    .toString();

                                var loginResult =
                                    await GetIt.I<CourierService>()
                                        .getLoginResult(userName, password);

                                courierBloc
                                    .add(TryLoginEvent(userName, password));
                              }
                            },
                            label: isBusy
                                ? const Text("Trabajando...")
                                : const Text("Iniciar Sesión")),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  onSubmitLogin() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() {
        isBusy = true;
      });

      userName = _formKey.currentState!.fields['user']!.value.toString();
      password = _formKey.currentState!.fields['password']!.value.toString();

      var loginResult =
          await GetIt.I<CourierService>().getLoginResult(userName, password);

      setState(() {
        isBusy = false;
      });

      if (loginResult.sessionId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Theme.of(context).errorColor,
          content: const Text(
              "Cuenta de usuario ó clave incorrecta. Favor revisar."),
        ));
      } else if (!loginResult.shouldAskToStore) {
        courierBloc.add(UserDidLoginEvent(userName));
      } else {
        // We have a session and is a new additional user account

        var dlgResult = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Confirme',
              style: Theme.of(context).textTheme.titleLarge),
            content: const Text(
                'Se ha detectado una nueva cuenta, desea agregar esta cuenta como favorita y así podra re-usarla en un futuro?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Guardar'),
              ),
            ],
          ),
        );

        if (dlgResult != null && dlgResult) {
          await GetIt.I<CourierService>().addCurrentAccountToStore();
          GetIt.I<CourierService>().clearCourierDataCache();
          courierBloc.add(UserDidLoginEvent(userName));
        }
      }
    }
  }
}
