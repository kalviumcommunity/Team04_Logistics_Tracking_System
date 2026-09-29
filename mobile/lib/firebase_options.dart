import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for DeliverSync.
/// Note: When connecting to a real production Firebase project,
/// replace these configuration constants or generate via `flutterfire configure`.
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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBE0ZsaWkU4ZpP6Y8P4LUD7UW1kDIqTMPo',
    appId: '1:1009988083161:web:9fce74afa8e9354c140dc8',
    messagingSenderId: '1009988083161',
    projectId: 'deliversync-46f67',
    authDomain: 'deliversync-46f67.firebaseapp.com',
    storageBucket: 'deliversync-46f67.firebasestorage.app',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBE0ZsaWkU4ZpP6Y8P4LUD7UW1kDIqTMPo',
    appId: '1:1009988083161:web:9fce74afa8e9354c140dc8',
    messagingSenderId: '1009988083161',
    projectId: 'deliversync-46f67',
    storageBucket: 'deliversync-46f67.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBE0ZsaWkU4ZpP6Y8P4LUD7UW1kDIqTMPo',
    appId: '1:1009988083161:web:9fce74afa8e9354c140dc8',
    messagingSenderId: '1009988083161',
    projectId: 'deliversync-46f67',
    storageBucket: 'deliversync-46f67.firebasestorage.app',
    iosBundleId: 'com.deliversync.mobile',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBE0ZsaWkU4ZpP6Y8P4LUD7UW1kDIqTMPo',
    appId: '1:1009988083161:web:9fce74afa8e9354c140dc8',
    messagingSenderId: '1009988083161',
    projectId: 'deliversync-46f67',
    storageBucket: 'deliversync-46f67.firebasestorage.app',
    iosBundleId: 'com.deliversync.mobile',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBE0ZsaWkU4ZpP6Y8P4LUD7UW1kDIqTMPo',
    appId: '1:1009988083161:web:9fce74afa8e9354c140dc8',
    messagingSenderId: '1009988083161',
    projectId: 'deliversync-46f67',
    authDomain: 'deliversync-46f67.firebaseapp.com',
    storageBucket: 'deliversync-46f67.firebasestorage.app',
  );
}
