import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:testt/pages/home.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  await _connectToFirebaseEmulator();
  

  // Temporary workaround for Impeller crash
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('ImpellerValidationBreak')) {
      return; // Ignore Impeller validation errors
    }
    FlutterError.presentError(details);
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Share',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          secondary: Colors.teal,
        ),
      ),
      home: Home(),
    );
  }
}

Future<void> _connectToFirebaseEmulator() async {

  FirebaseFirestore.instance.useFirestoreEmulator("10.0.2.2", 8080);
  FirebaseAuth.instance.useAuthEmulator("10.0.2.2", 9099);
  FirebaseStorage.instance.useStorageEmulator("10.0.2.2", 9199);
}
