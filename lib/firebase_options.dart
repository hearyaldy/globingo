import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  // This web config uses the same Firebase project values and prevents
  // web startup crashes. Replace appId with your Web appId from Firebase
  // Console for full production correctness.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA4n-k01hbMBCvnxFDUOg53TrpoUJOevHA',
    appId: '1:489642650167:web:replace-with-web-app-id',
    messagingSenderId: '489642650167',
    projectId: 'globingo-4362f',
    authDomain: 'globingo-4362f.firebaseapp.com',
    storageBucket: 'globingo-4362f.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA4n-k01hbMBCvnxFDUOg53TrpoUJOevHA',
    appId: '1:489642650167:android:f949c0413530e3af0cedb2',
    messagingSenderId: '489642650167',
    projectId: 'globingo-4362f',
    storageBucket: 'globingo-4362f.firebasestorage.app',
  );

  // Configure these when you add iOS/macOS Firebase apps.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'replace-with-ios-api-key',
    appId: 'replace-with-ios-app-id',
    messagingSenderId: '489642650167',
    projectId: 'globingo-4362f',
    storageBucket: 'globingo-4362f.firebasestorage.app',
    iosBundleId: 'com.haweeinc.globingo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'replace-with-macos-api-key',
    appId: 'replace-with-macos-app-id',
    messagingSenderId: '489642650167',
    projectId: 'globingo-4362f',
    storageBucket: 'globingo-4362f.firebasestorage.app',
    iosBundleId: 'com.haweeinc.globingo',
  );
}
