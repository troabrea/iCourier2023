import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../services/courier_service.dart';

import '../appinfo.dart';
import 'bloc/courier_bloc.dart';
import 'courier_dashboard.dart';
import 'courierappbar.dart';

class CourierPage extends StatefulWidget {
  const CourierPage({Key? key}) : super(key: key);

  @override
  State<CourierPage> createState() => _CourierPageState();
}

class _CourierPageState extends State<CourierPage> {
  final appInfo = GetIt.I<AppInfo>();
  final courierBloc = CourierBloc(CourierIsBusyState());
  late ScrollController controller;

  bool isBusy = false;

  String userName = "";
  String password = "";

  @override
  void initState() {
    controller = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

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
                return loginPage(context, state.showError, state.registerUrl);
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
      //initialValue: initialValue,
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
          prefixIconColor: Theme.of(context).primaryColorDark,
        suffixIcon:  GestureDetector(onTap: () { _formKey.currentState!.fields['password']!.reset(); }, child: const Icon(Icons.clear)),
      ),
    );
  }

  FormBuilderTextField buildUserAccountFormField(
      BuildContext context, String initialValue) {
    return FormBuilderTextField(
      name: 'user',
      keyboardType: TextInputType.text,
      textAlign: TextAlign.center,
      initialValue: initialValue,
      autofocus: true,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'Requerido'),
      ]),
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(2),
          hintText: 'Código de cliente',
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
          prefixIconColor: Theme.of(context).primaryColorDark,
        suffixIcon:  GestureDetector(onTap: () { _formKey.currentState!.fields['user']!.reset(); }, child: const Icon(Icons.clear)),
      ),
    );
  }

  Widget loginPage(BuildContext context, bool showError, String registerUrl) {
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
                          appInfo.brandLogoImage,
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
                        "Código de cliente ó contraseña inválido, favor verificar",
                        maxLines: 1,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: Theme.of(context).errorColor),
                      ),
                    const SizedBox(height: 5,),
                    Center(child: TextButton(onPressed: () async {
                          userForReset = _formKey
                            .currentState!.fields['user']!.value
                            .toString();
                          emailForReset = "";
                          //
                          await _showRememberPassword(context);
                          //
                          if(userForReset.isNotEmpty && emailForReset.isNotEmpty) {
                            try
                            {
                              setState(() {
                                isBusy = true;
                              });
                              try {
                                await courierBloc.courierService.resetPassword(userForReset, emailForReset);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text(
                                      "Correo recordatorio de contraseña solicitado exitosamente."),
                                ));
                              } catch (ex) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  backgroundColor: Theme.of(context).errorColor,
                                  content: const Text(
                                      "Ha ocurrido un error favor intentar nuevamente."),
                                ));
                              }
                            } finally {
                              setState(() {
                                isBusy = false;
                              });
                            }


                          }
                        },
                        child: Text.rich(TextSpan(text: "¿La olvidaste? - ", style: Theme.of(context).textTheme.bodySmall, children: [
                        TextSpan(text:'Recordar contraseña', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).primaryColorDark,))])))),
                    const SizedBox(height: 30),
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

                                // var loginResult =
                                //     await GetIt.I<CourierService>()
                                //         .getLoginResult(userName, password);

                                courierBloc
                                    .add(TryLoginEvent(userName, password));
                              }
                            },
                            label: isBusy
                                ? const Text("Trabajando...")
                                : const Text("Iniciar Sesión")),
                      ),
                    ),
                    if(registerUrl.isNotEmpty)
                      const SizedBox(height: 20,),
                    if(registerUrl.isNotEmpty)
                      Center(child: TextButton(onPressed: () async { await launchUrlString(registerUrl); }, child: Text.rich(TextSpan(text: "¿Aún no eres cliente? - ", style: Theme.of(context).textTheme.bodySmall, children: [
                        TextSpan(text:'Solicita tu cuenta', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).primaryColorDark, fontWeight: FontWeight.bold))])))),
                    // if(registerUrl.isNotEmpty)
                    //   Center(child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.center,
                    //     children: [
                    //       Text("Aún no eres cliente -", style: Theme.of(context).textTheme.bodySmall,),
                    //       TextButton( child: const Text('Solicita tu cuenta'), onPressed: () async {
                    //         await launchUrlString(registerUrl);
                    //       } , ),
                    //     ],
                    //   ),)

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  var emailForReset = "";
  var userForReset = "";

  Future<void> _showRememberPassword(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Recordar Contraseña', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),),
            content: SizedBox(height: 120,width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                children: [
                  if(userForReset.isEmpty)
                    TextField(
                      keyboardType: TextInputType.text,
                      autofocus: userForReset.isEmpty,
                      autocorrect: false,
                      onChanged: (value) {
                        setState( () {
                          userForReset = value;
                        });
                      },
                      //controller: _textFieldController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(2),
                        hintText: 'Código de cliente',
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
                        prefixIconColor: Theme.of(context).primaryColorDark,
                      ),
                    ),
                  if(userForReset.isNotEmpty)
                    Text(userForReset,textAlign: TextAlign.start,  style: Theme.of(context).textTheme.titleMedium,),
                  const SizedBox(height: 20,),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    autofocus: userForReset.isNotEmpty,
                    autocorrect: false,
                    onChanged: (value) {
                      setState( () {
                        emailForReset = value;
                      });
                    },
                    //controller: _textFieldController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(2),
                      hintText: 'Correo electrónico',
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
                      prefixIcon: const Icon(Icons.mail_outline),
                      prefixIconColor: Theme.of(context).primaryColorDark,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  userForReset = "";
                  emailForReset = "";
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: const Text('Aceptar'),
                onPressed: () {
                    if(userForReset.isEmpty || emailForReset.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Debe especificar su cuenta y correco electrónico registrado.', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),), backgroundColor: Theme.of(context).errorColor, ));
                      return;
                    }
                    Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  onSubmitLogin() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() {
        isBusy = true;
      });

      userName = _formKey.currentState!.fields['user']!.value.toString().toUpperCase();
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
        GetIt.I<CourierService>().clearCourierDataCache();
        courierBloc.add(UserDidLoginEvent(userName));
      } else {
        // We have a session and is a new additional user account

      _formKey.currentState!.reset();

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
