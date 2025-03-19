import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../services/courier_service.dart';

import '../apps/appinfo.dart';
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
  bool hasWhatsApp = false;
  bool isBusy = false;

  String userName = "";
  String password = "";

  @override
  void initState() {
    controller = ScrollController();
    super.initState();
    _configureWithProfile();
  }
  Future<void> _configureWithProfile() async {
    var userProfile = await GetIt.I<CourierService>().getUserProfile();
    setState(() {
      hasWhatsApp = userProfile.whatsappSucursal.isNotEmpty;
    });
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
        appBar: CourierAppBar(hasWhatsApp: hasWhatsApp),
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
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.editableText(
          editableTextState: editableTextState,
        );
      },
      keyboardType: TextInputType.text,
      //initialValue: initialValue,
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
      obscureText: true,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'requerido'.tr()),
      ]),
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(2),
          hintText: 'contraseña'.tr(),
          hintStyle: TextStyle(color: Theme.of(context).dividerColor),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(30)),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(30)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(30)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(30)),
          prefixIcon: const Icon(Icons.key),
          prefixIconColor: Theme.of(context).dividerColor,
        suffixIcon:  GestureDetector(onTap: () { _formKey.currentState!.fields['password']!.reset(); }, child: const Icon(Icons.clear)),
      ),
    );
  }

  FormBuilderTextField buildUserAccountFormField(
      BuildContext context, String initialValue) {
    return FormBuilderTextField(
      name: 'user',
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.editableText(
          editableTextState: editableTextState,
        );
      },
      keyboardType: TextInputType.text,
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
      initialValue: initialValue,
      autofocus: false,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'requerido'.tr()),
      ]),
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(2),
          hintText: appInfo.metricsPrefixKey == "CPS" ? "ABC-123456" : 'codigo_de_cliente'.tr(),
          hintStyle: TextStyle(color: Theme.of(context).dividerColor),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(30)),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(30)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(30)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(30)),
          prefixIcon: const Icon(Icons.person),
          prefixIconColor: Theme.of(context).dividerColor ,
        suffixIcon:  GestureDetector(onTap: () { _formKey.currentState!.fields['user']!.reset(); }, child: const Icon(Icons.clear)),
      ),
    );
  }

  Widget loginPage(BuildContext context, bool showError, String registerUrl) {
    if(appInfo.metricsPrefixKey == "TLS") {
      registerUrl = "";
    }
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
                    const SizedBox(height: 10,),
                    SizedBox(
                        height: 150,
                        child: Image.asset(
                          MediaQuery.of(context).platformBrightness == Brightness.dark ? appInfo.brandLogoImageDark : appInfo.brandLogoImage,
                          fit: BoxFit.scaleDown,
                        )),
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      'bienvenido'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(fontSize: 26),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      'indique_credenciales'.tr(),
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
                        "credenciales_invalidas".tr(),
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
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      "correo_recordatorio_enviado".tr()),
                                ));
                              } catch (ex) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  content: Text(
                                      "error_favor_reintentar".tr()),
                                ));
                              }
                            } finally {
                              setState(() {
                                isBusy = false;
                              });
                            }


                          }
                        },
                        child: Text.rich(TextSpan(text: "lo_olvidaste".tr(), style: Theme.of(context).textTheme.bodySmall, children: [
                        TextSpan(text:'recordar_contraseña'.tr(), style: Theme.of(context).textTheme.bodySmall!.copyWith(color: appInfo.metricsPrefixKey == "FIXOCARGO" ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))])))),
                    const SizedBox(height: 30),
                    if(isBusy)
                      Center(
                        child: CircularProgressIndicator(color: GetIt.I<AppInfo>().metricsPrefixKey == "FIXOCARGO" ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,),
                      )
                    else
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * .6,
                        child: FilledButton.icon(
                            style: FilledButton.styleFrom(
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
                                ? Text("trabajando".tr())
                                : Text("iniciar_sesión".tr())),
                      ),
                    ),
                    if(registerUrl.isNotEmpty)
                      const SizedBox(height: 20,),
                    if(appInfo.metricsPrefixKey != "INBOX" && appInfo.metricsPrefixKey != "TUPAQ" && appInfo.metricsPrefixKey != "FLYPACK" && appInfo.metricsPrefixKey != "BOXPAQ" && appInfo.metricsPrefixKey != "SWOOP" && appInfo.metricsPrefixKey != "FIXOCARGO" && registerUrl.isNotEmpty)
                      Center(child: TextButton(onPressed: () async { await launchUrlString(registerUrl, mode: LaunchMode.inAppWebView); }, child: Text.rich(TextSpan(text: "no_eres_cliente".tr(), style: Theme.of(context).textTheme.bodySmall, children: [
                        TextSpan(text:'conoce_mas_aqui'.tr(), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))])))),
                    if(appInfo.additionalLocale.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(onPressed: () { context.setLocale(const Locale('es')); }, child: context.locale.languageCode == 'es' ? Text('Español', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),) : const Text('Español'),),
                          Icon(Icons.circle, color: Theme.of(context).dividerColor, size: 6,),
                          TextButton(onPressed: () { context.setLocale(const Locale('en')); }, child: context.locale.languageCode == 'en' ? Text('English', style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),) : const Text('English'),),
                      ],),
                    if(appInfo.metricsPrefixKey == "FIXOCARGO")
                      Center(child: OutlinedButton(onPressed: () async {
                        await launchUrlString("https://fixocargo.com/", mode: LaunchMode.externalApplication); },
                          child: Text.rich(TextSpan(text: "aun_no_eres_cliente".tr(), style: Theme.of(context).textTheme.bodySmall,
                          )))),

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
            title: Text('recordar_la_contraseña'.tr(), style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),),
            content: SizedBox(height: 160,width: MediaQuery.of(context).size.width * 0.95,
              child: Column(
                children: [
                  if(userForReset.isEmpty)
                    TextField(
                      keyboardType: TextInputType.text,
                      autofocus: userForReset.isEmpty,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                      autocorrect: false,
                      onChanged: (value) {
                        setState( () {
                          userForReset = value;
                        });
                      },
                      //controller: _textFieldController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(2),
                        hintText: appInfo.metricsPrefixKey == "CPS" ? 'ABC-123456' : 'codigo_de_cliente'.tr(),
                        hintStyle: TextStyle(color: Theme.of(context).primaryColorDark.withOpacity(0.3)),
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
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                    onChanged: (value) {
                      setState( () {
                        emailForReset = value;
                      });
                    },
                    //controller: _textFieldController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(2),
                      hintText: 'correo_electronico'.tr(),
                      helperText: 'correo_registrado'.tr(),
                      hintStyle: TextStyle(color: Theme.of(context).primaryColorDark.withOpacity(0.3)),
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
                child: Text('cancelar'.tr()),
                onPressed: () {
                  userForReset = "";
                  emailForReset = "";
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text('aceptar'.tr()),
                onPressed: () {
                    if(userForReset.isEmpty || emailForReset.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Debe especificar su cuenta y correo electrónico registrado.', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),), backgroundColor: Theme.of(context).errorColor, ));
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
          content: Text(
              "credenciales_invalidas".tr()),
        ));
      } else if (!loginResult.shouldAskToStore) {
        GetIt.I<CourierService>().clearCourierDataCache();
        courierBloc.add(UserDidLoginEvent(userName, loginResult.sessionId, loginResult.sucursal));
      } else {
        // We have a session and is a new additional user account

      _formKey.currentState!.reset();

      var dlgResult = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('confirme'.tr(),
              style: Theme.of(context).textTheme.titleLarge),
            content: Text(
                'nueva_cuenta_detectada'.tr()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancelar'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('guardar'.tr()),
              ),
            ],
          ),
        );

        if (dlgResult != null && dlgResult) {
          await GetIt.I<CourierService>().addCurrentAccountToStore();
          GetIt.I<CourierService>().clearCourierDataCache();
          courierBloc.add(UserDidLoginEvent(userName, loginResult.sessionId,loginResult.sucursal));
        }
      }
    }
  }
}
