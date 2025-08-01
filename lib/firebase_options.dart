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
    apiKey: 'AIzaSyD7QRVM07vfJJb2GTikIRnzu3lvP_ukmh0',
    appId: '1:999907979024:web:8b076cc326ecffaaa7ff95',
    messagingSenderId: '999907979024',
    projectId: 'duoihinhbatchuapp',
    authDomain: 'duoihinhbatchuapp.firebaseapp.com',
    storageBucket: 'duoihinhbatchuapp.firebasestorage.app',
    measurementId: 'G-8HJPJY4P57',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAz4FCJvXLcAUS2uve0DVdXvEmaol41qFQ',
    appId: '1:999907979024:android:d25838179cb8bb2aa7ff95',
    messagingSenderId: '999907979024',
    projectId: 'duoihinhbatchuapp',
    storageBucket: 'duoihinhbatchuapp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA7eMqCyq_5XRHhudrIe1-vJRjPE8MWc5E',
    appId: '1:999907979024:ios:b99f988f72f003fda7ff95',
    messagingSenderId: '999907979024',
    projectId: 'duoihinhbatchuapp',
    storageBucket: 'duoihinhbatchuapp.firebasestorage.app',
    iosBundleId: 'com.duoihinhbat.chu',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA7eMqCyq_5XRHhudrIe1-vJRjPE8MWc5E',
    appId: '1:999907979024:ios:7cd5fd103759d66fa7ff95',
    messagingSenderId: '999907979024',
    projectId: 'duoihinhbatchuapp',
    storageBucket: 'duoihinhbatchuapp.firebasestorage.app',
    iosBundleId: 'com.example.duoihinhbatchu',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD7QRVM07vfJJb2GTikIRnzu3lvP_ukmh0',
    appId: '1:999907979024:web:9caa43a8e36919d8a7ff95',
    messagingSenderId: '999907979024',
    projectId: 'duoihinhbatchuapp',
    authDomain: 'duoihinhbatchuapp.firebaseapp.com',
    storageBucket: 'duoihinhbatchuapp.firebasestorage.app',
    measurementId: 'G-1DTGFG363Z',
  );
}
