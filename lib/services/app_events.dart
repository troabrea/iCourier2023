import 'package:event/event.dart';

class SessionExpired extends EventArgs {
  SessionExpired();
}

class UserPrealertaRequested extends EventArgs {
  UserPrealertaRequested();
}

class LoginChanged extends EventArgs {
  bool loggedIn;
  String account;
  String name;
  LoginChanged(this.loggedIn, this.account, this.name);
}

class LogoutRequested extends EventArgs {
  LogoutRequested();
}

class CourierRefreshRequested extends EventArgs {
  CourierRefreshRequested();
}

class AutoNotificarRetiroRequested extends EventArgs {
  AutoNotificarRetiroRequested();
}

class NotificarRetiroRequested extends EventArgs {
  NotificarRetiroRequested();
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

class UnreadMessagesChanged extends EventArgs {
  int unreadCount;
  UnreadMessagesChanged(this.unreadCount);
}