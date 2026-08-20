import 'package:event/event.dart';

import '../services/app_events.dart';
import '../services/model/asistente_model.dart';

/// Holds one customer's conversation for as long as the app is running.
///
/// The screen used to own the turns, so leaving it — and a shortcut into a tab
/// leaves it by design — threw the conversation away. Keeping them here means
/// the customer can follow an answer into the branch list and come back to
/// where they were.
///
/// Nothing here is written to disk. The conversation lives in memory, ends when
/// the process ends, and is dropped the moment the session it belongs to does:
/// package contents are personal and a phone is often shared.
class AssistantConversation {
  AssistantConversation({
    Event<LogoutRequested>? logouts,
    Event<SessionExpired>? expiries,
  }) {
    logouts?.subscribe((_) => clear());
    expiries?.subscribe((_) => clear());
  }

  String _account = '';
  List<AssistantTurn> _turns = const [];
  int _selectedIndex = -1;

  List<AssistantTurn> get turns => _turns;

  /// Index into [turns] of the answer last on screen; -1 when there is none.
  int get selectedIndex => _selectedIndex;

  /// Binds the conversation to [account], dropping another customer's.
  ///
  /// Switching accounts inside the app never signs out, so the logout events
  /// alone would let one customer reopen the assistant onto the previous
  /// customer's packages.
  void adoptAccount(String account) {
    if (account != _account) {
      clear();
      _account = account;
    }
  }

  void remember({
    required List<AssistantTurn> turns,
    required int selectedIndex,
  }) {
    _turns = List<AssistantTurn>.unmodifiable(turns);
    _selectedIndex = selectedIndex;
  }

  void clear() {
    _account = '';
    _turns = const [];
    _selectedIndex = -1;
  }
}
