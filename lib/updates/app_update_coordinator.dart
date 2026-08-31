import 'package:upgrader/upgrader.dart';

/// Describes an update published for the installed WhiteLabel application.
final class AvailableAppUpdate {
  const AvailableAppUpdate({
    required this.installedVersion,
    required this.storeVersion,
    required this.isRequired,
  });

  final String installedVersion;
  final String storeVersion;
  final bool isRequired;
}

/// Checks for updates and opens the current platform's store listing.
abstract interface class AppUpdateCoordinator {
  Future<AvailableAppUpdate?> findUpdate({bool refresh = false});

  Future<void> markPrompted();

  Future<void> openStore();

  void dispose();
}

/// Uses the public Google Play and App Store listings as the version source.
final class StoreAppUpdateCoordinator implements AppUpdateCoordinator {
  StoreAppUpdateCoordinator({
    required String appStoreCountryCode,
    Duration reminderInterval = const Duration(days: 1),
  }) : _upgrader = Upgrader(
          checkOnResume: false,
          countryCode: appStoreCountryCode,
          durationUntilAlertAgain: reminderInterval,
        );

  final Upgrader _upgrader;
  bool _initialized = false;

  @override
  Future<AvailableAppUpdate?> findUpdate({bool refresh = false}) async {
    if (!_initialized) {
      await _upgrader.initialize();
      _initialized = true;
    } else if (refresh) {
      await _upgrader.updateVersionInfo();
    }

    if (!_upgrader.shouldDisplayUpgrade()) {
      return null;
    }

    final versionInfo = _upgrader.versionInfo;
    final installedVersion = versionInfo?.installedVersion?.toString() ??
        _upgrader.currentInstalledVersion;
    final storeVersion = versionInfo?.appStoreVersion?.toString() ??
        _upgrader.currentAppStoreVersion;
    if (installedVersion == null || storeVersion == null) {
      return null;
    }

    return AvailableAppUpdate(
      installedVersion: installedVersion,
      storeVersion: storeVersion,
      isRequired: _upgrader.blocked(),
    );
  }

  @override
  Future<void> markPrompted() async {
    await _upgrader.saveLastAlerted();
  }

  @override
  Future<void> openStore() => _upgrader.sendUserToAppStore();

  @override
  void dispose() => _upgrader.dispose();
}
