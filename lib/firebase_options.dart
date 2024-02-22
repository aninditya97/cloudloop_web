// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBmg_A0BWBOosk5CSqY7k3_OLHdKpM0x94',
    appId: '1:853683776763:web:a3562c44bc54e9d32d545e',
    messagingSenderId: '853683776763',
    projectId: 'cloudloop-5d8d2',
    authDomain: 'cloudloop-5d8d2.firebaseapp.com',
    storageBucket: 'cloudloop-5d8d2.appspot.com',
    measurementId: 'G-P63DCQEBHJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB4KIKidEaMa0NuleTk8AD20Pul48whRQY',
    appId: '1:853683776763:android:73df2ea1d1fd5f942d545e',
    messagingSenderId: '853683776763',
    projectId: 'cloudloop-5d8d2',
    storageBucket: 'cloudloop-5d8d2.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBJlnz1Ng_JEMzotGn2sN_xPv-K6R_0gLg',
    appId: '1:853683776763:ios:c0e0bb374ae5c3ab2d545e',
    messagingSenderId: '853683776763',
    projectId: 'cloudloop-5d8d2',
    storageBucket: 'cloudloop-5d8d2.appspot.com',
    androidClientId:
        '853683776763-05hkbefka73s4rf9q0plqvhlop1itgoa.apps.googleusercontent.com',
    iosClientId:
        '853683776763-vn7q3cemu7sgo24p25rqfcm9l8bsmfsr.apps.googleusercontent.com',
    iosBundleId: 'com.cloudloop.mobile',
  );
}
