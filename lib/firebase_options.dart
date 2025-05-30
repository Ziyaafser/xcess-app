// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyAZCO7k7D7DEx2GnF31OdSFjpKTBFq0Lg4',
    appId: '1:286533301554:web:f74f054194bab96321932b',
    messagingSenderId: '286533301554',
    projectId: 'xcessapp',
    authDomain: 'xcessapp.firebaseapp.com',
    storageBucket: 'xcessapp.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDjhwyqOjyX8NTdgwZFm1MzBCpJCjOoYAA',
    appId: '1:286533301554:android:742b75cfb74e19e321932b',
    messagingSenderId: '286533301554',
    projectId: 'xcessapp',
    storageBucket: 'xcessapp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBAvLji7QWlDdQPFbi5_8YN9qTFFKaWWmE',
    appId: '1:286533301554:ios:94c896793dfba0c621932b',
    messagingSenderId: '286533301554',
    projectId: 'xcessapp',
    storageBucket: 'xcessapp.firebasestorage.app',
    iosBundleId: 'com.xcessApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBAvLji7QWlDdQPFbi5_8YN9qTFFKaWWmE',
    appId: '1:286533301554:ios:94c896793dfba0c621932b',
    messagingSenderId: '286533301554',
    projectId: 'xcessapp',
    storageBucket: 'xcessapp.firebasestorage.app',
    iosBundleId: 'com.xcessApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAZCO7k7D7DEx2GnF31OdSFjpKTBFq0Lg4',
    appId: '1:286533301554:web:df1f1eb56f21bff221932b',
    messagingSenderId: '286533301554',
    projectId: 'xcessapp',
    authDomain: 'xcessapp.firebaseapp.com',
    storageBucket: 'xcessapp.firebasestorage.app',
  );
}
