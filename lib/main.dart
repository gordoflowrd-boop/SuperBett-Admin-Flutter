import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/menu_page.dart';
import 'pages/bancas_page.dart';
import 'pages/premios_page.dart';

void main() {
  runApp(const SuperBettApp());
}

class SuperBettApp extends StatelessWidget {
  const SuperBettApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperBett Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      initialRoute: '/',
      routes: {
        '/':        (context) => const LoginPage(),
        '/login':   (context) => const LoginPage(),
        '/menu':    (context) => const MenuPage(),
        '/bancas':  (context) => const BancasPage(),
        '/premios': (context) => const PremiosPage(),
      },
    );
  }
}