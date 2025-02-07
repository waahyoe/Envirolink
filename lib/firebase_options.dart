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
    apiKey: 'AIzaSyCz_bkyAhlQF83995JHEBrKxXFq6274mQA',
    appId: '1:587659421384:web:443a30513b3a2d640ce7fd',
    messagingSenderId: '587659421384',
    projectId: 'envirolink-5b459',
    authDomain: 'envirolink-5b459.firebaseapp.com',
    databaseURL: 'https://envirolink-5b459-default-rtdb.firebaseio.com',
    storageBucket: 'envirolink-5b459.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBwssyhK-L9Yfyl7M7qhWmaD5jUQ7NGQjQ',
    appId: '1:587659421384:android:b288f2d418319a650ce7fd',
    messagingSenderId: '587659421384',
    projectId: 'envirolink-5b459',
    databaseURL: 'https://envirolink-5b459-default-rtdb.firebaseio.com',
    storageBucket: 'envirolink-5b459.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCfTF4JEiRdk6Z3jSLQl7phRm65CIF05T4',
    appId: '1:587659421384:ios:b8fe36b0628627ca0ce7fd',
    messagingSenderId: '587659421384',
    projectId: 'envirolink-5b459',
    databaseURL: 'https://envirolink-5b459-default-rtdb.firebaseio.com',
    storageBucket: 'envirolink-5b459.firebasestorage.app',
    iosBundleId: 'com.example.flutterFirsproject',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCfTF4JEiRdk6Z3jSLQl7phRm65CIF05T4',
    appId: '1:587659421384:ios:b8fe36b0628627ca0ce7fd',
    messagingSenderId: '587659421384',
    projectId: 'envirolink-5b459',
    databaseURL: 'https://envirolink-5b459-default-rtdb.firebaseio.com',
    storageBucket: 'envirolink-5b459.firebasestorage.app',
    iosBundleId: 'com.example.flutterFirsproject',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCz_bkyAhlQF83995JHEBrKxXFq6274mQA',
    appId: '1:587659421384:web:262bebe809e2b7f20ce7fd',
    messagingSenderId: '587659421384',
    projectId: 'envirolink-5b459',
    authDomain: 'envirolink-5b459.firebaseapp.com',
    databaseURL: 'https://envirolink-5b459-default-rtdb.firebaseio.com',
    storageBucket: 'envirolink-5b459.firebasestorage.app',
  );

}