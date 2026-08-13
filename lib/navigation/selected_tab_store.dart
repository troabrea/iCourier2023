import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../theme/brand_config.dart';

/// Persists the last main-navigation module selected by the customer.
final class SelectedTabStore {
  SelectedTabStore(this.preferences);

  final SharedPreferences preferences;

  /// Stores a module name so a future WhiteLabel tab reorder remains safe.
  static const storageKey = 'lastSelectedTabModule';

  // The previous shell stored an index through flutter_cache. Reading that
  // shape lets existing installations keep their last selection after the
  // navigation redesign ships.
  static const _legacyStorageKey = 'lastSelectedTab';

  /// Returns a valid index for [tabs], falling back to [fallbackIndex].
  int restoreIndex(List<TabModule> tabs, {required int fallbackIndex}) {
    final storedModule = preferences.getString(storageKey);
    if (storedModule != null) {
      final storedIndex = tabs.indexWhere(
        (module) => module.name == storedModule,
      );
      if (storedIndex >= 0) {
        return storedIndex;
      }
    }

    final legacyIndex = _legacyIndex;
    if (legacyIndex != null && _isValid(legacyIndex, tabs)) {
      return legacyIndex;
    }
    if (_isValid(fallbackIndex, tabs)) {
      return fallbackIndex;
    }

    final homeIndex = tabs.indexOf(TabModule.home);
    return homeIndex >= 0 ? homeIndex : 0;
  }

  /// Saves [module] as the stable identity of the selected tab.
  Future<void> save(TabModule module) async {
    await preferences.setString(storageKey, module.name);
  }

  int? get _legacyIndex {
    final descriptor = preferences.getString(_legacyStorageKey);
    if (descriptor == null || descriptor.isEmpty) {
      return null;
    }

    // Also accepts a direct value in case an intermediate build wrote the
    // index without flutter_cache's descriptor wrapper.
    final directIndex = int.tryParse(descriptor);
    if (directIndex != null) {
      return directIndex;
    }

    try {
      final decoded = jsonDecode(descriptor);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final contentKey = decoded['content'];
      if (contentKey is! String) {
        return null;
      }
      return int.tryParse(preferences.getString(contentKey) ?? '');
    } on FormatException {
      return null;
    }
  }

  bool _isValid(int index, List<TabModule> tabs) =>
      index >= 0 && index < tabs.length;
}
