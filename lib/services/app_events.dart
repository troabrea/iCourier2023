import 'package:event/event.dart';

import 'model/login_model.dart';

class LoginChanged extends EventArgs {
  bool loggedIn;
  String account;
  LoginChanged(this.loggedIn, this.account);
}

class LogoutRequested extends EventArgs {
  LogoutRequested();
}

class CourierRefreshRequested extends EventArgs {
  CourierRefreshRequested();
}

class EmpresaRefreshFinished extends EventArgs {
  EmpresaRefreshFinished();
}

class NoticiasDataRefreshRequested extends EventArgs {
  NoticiasDataRefreshRequested();
}

class SucursalesDataRefreshRequested extends EventArgs {
  SucursalesDataRefreshRequested();
}


class ToogleBarEvent extends EventArgs {
  bool show;
  ToogleBarEvent(this.show);
}