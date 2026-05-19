import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:fyp1/screens/login_screen.dart';
import 'package:fyp1/screens/pairing/bluetooth_screen.dart';
import 'package:fyp1/screens/pairing/pair_trolley_screen.dart';
import 'package:fyp1/screens/pairing/qr_screen.dart';
import 'package:fyp1/screens/register_screen.dart';
import 'package:fyp1/screens/splash_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CuRoCART',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
          primary: const Color(0xFFFF6B35),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          labelStyle: TextStyle(color: Colors.black),
          floatingLabelStyle: TextStyle(color: Colors.black),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Colors.black26,
          selectionHandleColor: Colors.black,
        ),
      ),

      home: const SplashScreen(),

      routes: {
        '/login':       (context) => const LoginScreen(),
        '/register':    (context) => const RegisterScreen(),
        '/pairTrolley': (context) => const PairTrolleyScreen(),
        '/bluetooth':   (context) => const BluetoothScreen(),
        '/qrScanner':   (context) => const QRScannerScreen(),
      },
    );
  }
}