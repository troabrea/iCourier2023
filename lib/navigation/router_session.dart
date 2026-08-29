import 'package:event/event.dart';
import 'package:flutter/foundation.dart';

import '../services/app_events.dart';

/// Bridges the existing login event into GoRouter's refresh contract.
final class RouterSession extends ChangeNotifier {
  RouterSession({
    required bool initiallyLoggedIn,
    required Event<LoginChanged> loginChanges,
  })  : _isLoggedIn = initiallyLoggedIn,
        _loginChanges = loginChanges {
    _loginChanges.subscribe(_onLoginChanged);
  }

  final Event<LoginChanged> _loginChanges;
  bool _isLoggedIn;
  String _account = '';
  String _name = '';
  int _accountRevision = 0;

  bool get isLoggedIn => _isLoggedIn;

  /// Changes whenever the authenticated identity changes, including a switch
  /// between two accounts that are both logged in.
  int get accountRevision => _accountRevision;

  void _onLoginChanged(LoginChanged? change) {
    if (change == null ||
        (change.loggedIn == _isLoggedIn &&
            change.account == _account &&
            change.name == _name)) {
      return;
    }
    _isLoggedIn = change.loggedIn;
    _account = change.account;
    _name = change.name;
    _accountRevision++;
    notifyListeners();
  }

  @override
  void dispose() {
    _loginChanges.unsubscribe(_onLoginChanged);
    super.dispose();
  }
}
