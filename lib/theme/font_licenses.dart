import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// SIL OFL 1.1 requires the licence to travel with the bundled font files.
/// Registering it also lists the families in Flutter's licence page.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, path) in const [
      ('Source Sans 3', 'fonts/OFL-SourceSans3.txt'),
      ('Outfit', 'fonts/OFL-Outfit.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks(
        [family],
        await rootBundle.loadString(path),
      );
    }
  });
}
