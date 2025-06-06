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
    apiKey: 'AIzaSyAvRQK29eQ9p1K8XnJgLK5DIp8l3PYg_k8',
    appId: '1:125211484755:web:01673423cceaa493619ca6',
    messagingSenderId: '125211484755',
    projectId: 'fir-flutter-codelab-74cc5',
    authDomain: 'fir-flutter-codelab-74cc5.firebaseapp.com',
    storageBucket: 'fir-flutter-codelab-74cc5.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA96fKQp3kf69n0vKBycBlnoCQmew22sU8',
    appId: '1:125211484755:android:95dc6019a595a48a619ca6',
    messagingSenderId: '125211484755',
    projectId: 'fir-flutter-codelab-74cc5',
    storageBucket: 'fir-flutter-codelab-74cc5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC6NPUg3rhJ6ltXANOSV0gmOhoXQD4uv7U',
    appId: '1:125211484755:ios:53141a69b50d91e5619ca6',
    messagingSenderId: '125211484755',
    projectId: 'fir-flutter-codelab-74cc5',
    storageBucket: 'fir-flutter-codelab-74cc5.firebasestorage.app',
    iosBundleId: 'com.example.shop',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC6NPUg3rhJ6ltXANOSV0gmOhoXQD4uv7U',
    appId: '1:125211484755:ios:53141a69b50d91e5619ca6',
    messagingSenderId: '125211484755',
    projectId: 'fir-flutter-codelab-74cc5',
    storageBucket: 'fir-flutter-codelab-74cc5.firebasestorage.app',
    iosBundleId: 'com.example.shop',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAvRQK29eQ9p1K8XnJgLK5DIp8l3PYg_k8',
    appId: '1:125211484755:web:3868fc520648354f619ca6',
    messagingSenderId: '125211484755',
    projectId: 'fir-flutter-codelab-74cc5',
    authDomain: 'fir-flutter-codelab-74cc5.firebaseapp.com',
    storageBucket: 'fir-flutter-codelab-74cc5.firebasestorage.app',
  );

}