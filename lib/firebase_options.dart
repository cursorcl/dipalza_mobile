// File generated manually a partir de google-services.json / GoogleService-Info.plist
// (equivalente al output de `flutterfire configure`, sin usar el CLI).
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions no están configuradas para web - '
        'esta app no se ejecuta en un navegador.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están soportadas para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD88oWP1H3942Sp8jRgnjaYfwJebdsly8M',
    appId: '1:212794342260:android:7250cf128dd46b4d338a21',
    messagingSenderId: '212794342260',
    projectId: 'dipalza-movil',
    storageBucket: 'dipalza-movil.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDZFC94UFODaX6wZcdGLkAKWYGcxlkVFW8',
    appId: '1:212794342260:ios:e83267d97cf8132e338a21',
    messagingSenderId: '212794342260',
    projectId: 'dipalza-movil',
    storageBucket: 'dipalza-movil.firebasestorage.app',
    iosBundleId: 'cl.eos.dipalzaMovil',
  );
}
