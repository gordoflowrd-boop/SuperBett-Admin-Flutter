import 'package:flutter/material.dart';
import '../layout/app_layout.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  void _onSelect(BuildContext context, int i) {
    const rutas = [
      null,
      '/bancas',
      '/premios',
      '/reportes',
      '/usuarios',
      '/limites',
      '/configuracion',
    ];
    final ruta = rutas[i];
    if (ruta != null && ruta != '/menu') {
      Navigator.pushReplacementNamed(context, ruta);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 0,
      onItemSelected: (i) => _onSelect(context, i),
      child: Column(
        children: [
          // ── Navbar idéntico al de Bancas ──
          Container(
            color: const Color(0xFF1A237E),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Panel Principal",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Icono decorativo o de usuario para mantener la simetría
                const Icon(Icons.dashboard_outlined, color: Colors.white, size: 20),
              ],
            ),
          ),

          // ── Contenido Central ──
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x331A237E),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "SB",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "SuperBett Admin",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Selecciona una sección del menú lateral",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
