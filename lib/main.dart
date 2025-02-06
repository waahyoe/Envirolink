import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:envirolink/splash_screen.dart';
import 'package:envirolink/dashboard_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

//handler untuk pesan background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

//widget utama aplikasi. mengatur tema & layar awal aplikasi
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EnviroLink',
      theme: ThemeData(
        primaryColor: const Color(0xFF1DB954),
        scaffoldBackgroundColor: const Color(0xFF1C1C1C),
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreenWrapper(),
    );
  }
}

//StatefulWidget yang menampilkan splash screen selama 3 detik, kemudian menavigasi ke DashboardScreen
class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({Key? key}) : super(key: key);

  @override
  _SplashScreenWrapperState createState() => _SplashScreenWrapperState();
}

//Menginisialisasi state dan menavigasi ke Dashboard setelah penundaan 3 detik menggunakan metode _navigateToDashboard
class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToDashboard();
  }

  void _navigateToDashboard() async {
    await Future.delayed(
        const Duration(seconds: 3), () {}); // Durasi splash screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
