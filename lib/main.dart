import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Stripe in Test Mode
  Stripe.publishableKey = 'pk_test_51RVFGCPkYLCIHR8eeJyHMkxwLK3xVOTlNaZl6dFSAdYd1V1YD2wjFhz5X6gSLT6pqQzoutFM6y6K94QVIXkMzBAX00r8r2DjvY';
  await Stripe.instance.applySettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xcess App',
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}
