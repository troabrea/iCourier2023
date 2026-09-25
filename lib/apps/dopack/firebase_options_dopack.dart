// File generated from Firebase app configuration.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the DoPack apps.
class DoPackDefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DoPack Firebase options have not been configured for web.',
      );
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
          'DoPack Firebase options are not supported for this platform.',
        ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbHYrktsP-ndUKq3F9dc368XsbobqV_sQ',
    appId: '1:762385130317:android:559b33a1a3254ee8d98d04',
    messagingSenderId: '762385130317',
    projectId: 'icourierapps-group3',
    storageBucket: 'icourierapps-group3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCyAGYm5_sQFiyhgGivJunQgIqkl2INCsE',
    appId: '1:762385130317:ios:0eb311ff2cfaf9b8d98d04',
    messagingSenderId: '762385130317',
    projectId: 'icourierapps-group3',
    storageBucket: 'icourierapps-group3.firebasestorage.app',
    iosBundleId: 'com.barolit.dopack',
  );
}
