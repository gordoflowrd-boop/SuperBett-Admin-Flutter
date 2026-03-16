import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/app_layout.dart';

const _kAzul = Color(0xFF1A237E);
const _kApi  = 'https://superbett-api-production.up.railway.app/api';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic> _stats = {};
  bool   _loading = true;
  String _nombre  = '';
  String _rol     = '';

  @override
  void initState() { 
    super.initState(); 
    _cargar(); 
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _loading = true);
    
    try {
      final prefs   = await SharedPreferences.getInstance();
      final token   = prefs.getString('token');

      // --- PROTECCIÓN: Si no hay token, mandamos al login ---
      if (token == null || token.isEmpty) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final rawUser = prefs.getString('usuario') ?? '{}';
      final usuario = jsonDecode(rawUser) as Map<String, dynamic>;
      
      if (mounted) {
        setState(() {
          _nombre = usuario['nombre']?.toString() ?? usuario['username']?.toString() ?? '';
          _rol    = usuario['rol']?.toString() ?? '';
        });
      }

      final headers = {'Authorization': 'Bearer $token'};

      // Llamadas paralelas a la API
      final responses = await Future.wait([
        http.get(Uri.parse('$_kApi/admin/bancas'),   headers: headers),
        http.get(Uri.parse('$_kApi/admin/usuarios'), headers: headers),
      ]);

      // Verificar si la respuesta es 401 (Token expirado)
      if (responses[0].statusCode == 401 || responses[1].statusCode == 401) {
        await prefs.clear(); // Limpiar datos viejos
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final bancas   = jsonDecode(responses[0].body)['bancas']   as List? ?? [];
      final usuarios = jsonDecode(responses[1].body)['usuarios'] as List? ?? [];

      if (mounted) {
        setState(() {
          _stats = {
            'bancas_total':   bancas.length,
            'bancas_activas': bancas.where((b) => b['activa'] == true).length,
            'usuarios_total': usuarios.length,
            'vendedores':     usuarios.where((u) => u['rol'] == 'vendedor').length,
            'riferos':        usuarios.where((u) => u['rol'] == 'rifero').length,
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 0,
      child: Column(children: [
        // Header con nombre y rol
        Container(
          color: _kAzul,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido${_nombre.isNotEmpty ? ', $_nombre' : ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)
                ),
                if (_rol.isNotEmpty)
                  Text(
                    _rol.toUpperCase(),
                    style: const TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 0.5)
                  ),
              ],
            )),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _cargar
            ),
          ]),
        ),

        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(child: RefreshIndicator(
            onRefresh: _cargar,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _seccion('Resumen'),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _statCard('Bancas',   '${_stats['bancas_total'] ?? 0}', Icons.storefront_outlined, Colors.blue),
                      _statCard('Activas',  '${_stats['bancas_activas'] ?? 0}', Icons.check_circle_outline, Colors.green),
                      _statCard('Usuarios', '${_stats['usuarios_total'] ?? 0}', Icons.people_outline, Colors.purple),
                      _statCard('Vendedores','${_stats['vendedores'] ?? 0}', Icons.person_outline, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _seccion('Accesos rápidos'),
                  const SizedBox(height: 8),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    if (_rol == 'admin' || _rol == 'central')
                      _accesoRapido(context, 'Bancas', Icons.storefront, '/bancas', Colors.blue),
                    if (_rol == 'admin' || _rol == 'central')
                      _accesoRapido(context, 'Usuarios', Icons.people, '/usuarios', Colors.purple),
                    if (_rol == 'admin' || _rol == 'central' || _rol == 'rifero')
                      _accesoRapido(context, 'Reportes', Icons.bar_chart, '/reportes', Colors.teal),
                    if (_rol == 'admin')
                      _accesoRapido(context, 'Riferos', Icons.manage_accounts, '/riferos', Colors.indigo),
                    _accesoRapido(context, 'Descargas', Icons.download, '/descargas', Colors.green),
                  ]),
                ],
              ),
            ),
          )),
      ]),
    );
  }

  Widget _seccion(String label) => Text(
    label,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)
  );

  Widget _statCard(String label, String valor, IconData icon, Color color) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        )),
      ]),
    );

  Widget _accesoRapido(BuildContext context, String label, IconData icon, String ruta, Color color) =>
    InkWell(
      onTap: () => Navigator.pushReplacementNamed(context, ruta),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
}
