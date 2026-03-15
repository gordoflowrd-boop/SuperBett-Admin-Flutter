import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/bancas_page.dart';
import 'pages/venta_page.dart';
import 'pages/premios_page.dart';
import 'pages/reporte_page.dart';
import 'pages/usuarios_page.dart';
import 'pages/riferos_page.dart';
import 'pages/limites_page.dart';
import 'pages/configuracion_page.dart';
import 'pages/descargas_page.dart';
import 'pages/contabilidad_page.dart';
import 'pages/mensajes_page.dart';

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
        '/':              (context) => const DashboardPage(),
        '/login':         (context) => const LoginPage(),
        '/dashboard':     (context) => const DashboardPage(),
        '/bancas':        (context) => const BancasPage(),
        '/venta':         (context) => const VentaPage(),
        '/premios':       (context) => const PremiosPage(),
        '/reportes':      (context) => const ReportesPage(),
        '/usuarios':      (context) => const UsuariosPage(),
        '/riferos':       (context) => const RiferosPage(),
        '/limites':       (context) => const LimitesPage(),
        '/configuracion': (context) => const ConfiguracionPage(),
        '/descargas':     (context) => const DescargasPage(),
        '/contabilidad':  (context) => const ContabilidadPage(),
        '/mensajes':      (context) => const MensajesPage(),
      },
    );
  }
}