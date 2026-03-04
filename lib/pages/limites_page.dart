import 'package:flutter/material.dart';
import '../layout/app_layout.dart';

class LimitesPage extends StatelessWidget {
  const LimitesPage({super.key});

  void _onSelect(BuildContext context, int i) {
    const rutas = [
      '/menu', '/bancas', '/premios', '/reportes',
      '/usuarios', '/limites', '/configuracion',
    ];
    if (rutas[i] != '/limites') Navigator.pushReplacementNamed(context, rutas[i]);
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 5,
      onItemSelected: (i) => _onSelect(context, i),
      child: Column(children: [

        // ── Navbar azul ──────────────────────────────
        Container(
          color: const Color(0xFF1A237E),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: const Row(children: [
            Expanded(child: Text("Límites",
              style: TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.bold))),
            Icon(Icons.tune, color: Colors.white, size: 20),
          ]),
        ),

        // ── Contenido ────────────────────────────────
        Expanded(child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.construction_outlined, size: 56,
                color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text("Próximamente",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
            const SizedBox(height: 6),
            Text("Esta sección está en desarrollo.",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ))),
      ]),
    );
  }
}
