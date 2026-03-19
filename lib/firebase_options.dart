import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD5GkqG9MyUgOPiUd4qKNWmCB66SMOnTPI',
    appId: '1:1009753899313:web:82f5ac3e6abd03d0e1b010',
    messagingSenderId: '1009753899313',
    projectId: 'endsem-a417a',
    authDomain: 'endsem-a417a.firebaseapp.com',
    storageBucket: 'endsem-a417a.firebasestorage.app',
    measurementId: 'G-DG81GC4BXG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD5GkqG9MyUgOPiUd4qKNWmCB66SMOnTPI',
    appId: '1:1009753899313:web:82f5ac3e6abd03d0e1b010',
    messagingSenderId: '1009753899313',
    projectId: 'endsem-a417a',
    storageBucket: 'endsem-a417a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD5GkqG9MyUgOPiUd4qKNWmCB66SMOnTPI',
    appId: '1:1009753899313:web:82f5ac3e6abd03d0e1b010',
    messagingSenderId: '1009753899313',
    projectId: 'endsem-a417a',
    storageBucket: 'endsem-a417a.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD5GkqG9MyUgOPiUd4qKNWmCB66SMOnTPI',
    appId: '1:1009753899313:web:82f5ac3e6abd03d0e1b010',
    messagingSenderId: '1009753899313',
    projectId: 'endsem-a417a',
    storageBucket: 'endsem-a417a.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD5GkqG9MyUgOPiUd4qKNWmCB66SMOnTPI',
    appId: '1:1009753899313:web:82f5ac3e6abd03d0e1b010',
    messagingSenderId: '1009753899313',
    projectId: 'endsem-a417a',
    storageBucket: 'endsem-a417a.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyD5GkqG9MyUgOPiUd4qKNWmCB66SMOnTPI',
    appId: '1:1009753899313:web:82f5ac3e6abd03d0e1b010',
    messagingSenderId: '1009753899313',
    projectId: 'endsem-a417a',
    storageBucket: 'endsem-a417a.firebasestorage.app',
  );
}
