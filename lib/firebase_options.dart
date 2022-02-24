// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars
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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    // ignore: missing_enum_constant_in_switch
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
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCr4h_cWMW6dxjviJ_7vwAlp81KdYgJoWk',
    appId: '1:2796489029:android:d6409a3a65cfd84c71562c',
    messagingSenderId: '2796489029',
    projectId: 'vicara-fall-detection',
    storageBucket: 'vicara-fall-detection.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCNuTUH1HFv5pXD9FiviYdNdO4NWDRN9uI',
    appId: '1:2796489029:ios:0b5cfdbb72ee23d971562c',
    messagingSenderId: '2796489029',
    projectId: 'vicara-fall-detection',
    storageBucket: 'vicara-fall-detection.appspot.com',
    androidClientId: '2796489029-327pqib6fe71hd0qhk7r1scsdni0j6vp.apps.googleusercontent.com',
    iosClientId: '2796489029-9j6p7m14cicclefet1o5f4nbu3hukafe.apps.googleusercontent.com',
    iosBundleId: 'com.example.vicara',
  );
}