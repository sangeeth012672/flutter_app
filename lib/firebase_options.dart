// ============================================================
// firebase_options.dart
// IMPORTANT: Replace this file by running:
//   flutterfire configure
// Or manually fill in your Firebase project credentials.
// ============================================================
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Replace all values below with your actual Firebase project config.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCx9hacmB7Li09Yh6L83xvlabLKXveYOlw',
    appId: '1:1044509012650:android:07d7d05a2f360772ad16d3',
    messagingSenderId: '1044509012650',
    projectId: 'smart-tasks-manager-ed973',
    databaseURL: 'https://smart-tasks-manager-ed973-default-rtdb.firebaseio.com',
    storageBucket: 'smart-tasks-manager-ed973.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA4r6QH8TQdze85_02XNGYYQfAvzCnuZjQ',
    appId: '1:1044509012650:ios:986a53d56a10a0c9ad16d3',
    messagingSenderId: '1044509012650',
    projectId: 'smart-tasks-manager-ed973',
    databaseURL: 'https://smart-tasks-manager-ed973-default-rtdb.firebaseio.com',
    storageBucket: 'smart-tasks-manager-ed973.firebasestorage.app',
    iosBundleId: 'com.example.flutterApp',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDy1OoTQSXS0oCDZD8LkzIC1k7eIGYQqxo',
    appId: '1:1044509012650:web:f1fcf51464e2f7c9ad16d3',
    messagingSenderId: '1044509012650',
    projectId: 'smart-tasks-manager-ed973',
    authDomain: 'smart-tasks-manager-ed973.firebaseapp.com',
    databaseURL: 'https://smart-tasks-manager-ed973-default-rtdb.firebaseio.com',
    storageBucket: 'smart-tasks-manager-ed973.firebasestorage.app',
    measurementId: 'G-H75FPGVLRE',
  );
}
