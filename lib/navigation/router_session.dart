import 'package:event/event.dart';
import 'package:flutter/foundation.dart';

import '../services/app_events.dart';

/// Bridges the existing login event into GoRouter's refresh contract.
final class RouterSession extends ChangeNotifier {
  RouterSession({
    required bool initiallyLoggedIn,
    required Event<LoginChanged> loginChanges,
  }) : _isLoggedIn = initiallyLoggedIn {
    loginChanges.subscribe((change) {
      if (change == null || change.loggedIn == _isLoggedIn) {
        return;
      }
      _isLoggedIn = change.loggedIn;
      notifyListeners();
    });
  }

  bool _isLoggedIn;

  bool get isLoggedIn => _isLoggedIn;
}
