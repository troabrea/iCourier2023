import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PendingDestinationStore {
  Future<void> save(String destination);

  Future<String?> take();

  Future<void> clear();
}

/// Persists one protected destination while the user completes login.
final class SharedPreferencesPendingDestinationStore
    implements PendingDestinationStore {
  SharedPreferencesPendingDestinationStore(this.preferences);

  static const storageKey = 'pending_authenticated_destination_v1';

  final SharedPreferences preferences;

  @override
  Future<void> save(String destination) async {
    await preferences.setString(storageKey, destination);
  }

  @override
  Future<String?> take() async {
    final destination = preferences.getString(storageKey);
    await clear();
    return destination;
  }

  @override
  Future<void> clear() async {
    await preferences.remove(storageKey);
  }
}
