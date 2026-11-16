import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (useEmulators) {
    // Connect each service once, before any Auth or Firestore request.
    // The two Cloud Functions are called through services/callable.dart,
    // which targets the Functions emulator itself.
    final host = emulatorHost;
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    debugPrint('Cloud Quest: using Firebase emulators at $host');
  }
  runApp(const CloudQuestApp());
}
