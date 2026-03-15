import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// Definición central de todas las páginas
// ─────────────────────────────────────────────
class _NavItem {
  final String label;
  final String ruta;
  final IconData icon;
  final IconData iconSel;
  final List<String> roles; // roles que pueden ver esta página

  const _NavItem({
    required this.label,
    required this.ruta,
    required this.icon,
    required this.iconSel,
    required this.roles,
  });
}

const _kTodos  = ['admin', 'central', 'rifero', 'tecnico'];
const _kAdmin  = ['admin'];
const _kGestion = ['admin', 'central'];

final _navItems = [
  _NavItem(label: 'Dashboard',    ruta: '/dashboard',    icon: Icons.dashboard_outlined,         iconSel: Icons.dashboard,         roles: _kTodos),
  _NavItem(label: 'Bancas',       ruta: '/bancas',       icon: Icons.storefront_outlined,        iconSel: Icons.storefront,        roles: _kTodos),
  _NavItem(label: 'Venta',        ruta: '/venta',        icon: Icons.receipt_long_outlined,      iconSel: Icons.receipt_long,      roles: _kGestion),
  _NavItem(label: 'Premios',      ruta: '/premios',      icon: Icons.emoji_events_outlined,      iconSel: Icons.emoji_events,      roles: _kGestion + ['rifero']),
  _NavItem(label: 'Reportes',     ruta: '/reportes',     icon: Icons.bar_chart_outlined,         iconSel: Icons.bar_chart,         roles: _kGestion + ['rifero']),
  _NavItem(label: 'Riferos',      ruta: '/riferos',      icon: Icons.manage_accounts_outlined,   iconSel: Icons.manage_accounts,   roles: _kAdmin),
  _NavItem(label: 'Usuarios',     ruta: '/usuarios',     icon: Icons.people_outline,             iconSel: Icons.people,            roles: _kGestion),
  _NavItem(label: 'Mensajes',     ruta: '/mensajes',     icon: Icons.chat_bubble_outline,        iconSel: Icons.chat_bubble,       roles: _kTodos),
  _NavItem(label: 'Límites',      ruta: '/limites',      icon: Icons.tune_outlined,              iconSel: Icons.tune,              roles: _kGestion),
  _NavItem(label: 'Configuración',ruta: '/configuracion',icon: Icons.settings_outlined,          iconSel: Icons.settings,          roles: _kGestion),
  _NavItem(label: 'Contabilidad', ruta: '/contabilidad', icon: Icons.account_balance_outlined,   iconSel: Icons.account_balance,   roles: _kGestion),
  _NavItem(label: 'Descargas',    ruta: '/descargas',    icon: Icons.download_outlined,          iconSel: Icons.download,          roles: _kTodos),
];

// ─────────────────────────────────────────────
// AppLayout — StatefulWidget para leer el rol
// ─────────────────────────────────────────────
class AppLayout extends StatefulWidget {
  final int    selectedIndex; // índice GLOBAL (de _navItems completo)
  final Widget child;

  // onItemSelected ya es opcional — AppLayout navega solo
  final Function(int)? onItemSelected;

  const AppLayout({
    super.key,
    required this.selectedIndex,
    required this.child,
    this.onItemSelected, // mantenido por compatibilidad, ignorado internamente
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  String _rol      = 'admin';
  String _nombre   = '';
  List<_NavItem> _visibles = [];

  @override
  void initState() {
    super.initState();
    _cargarRol();
  }

  Future<void> _cargarRol() async {
    final prefs   = await SharedPreferences.getInstance();
    final rawUser = prefs.getString('usuario') ?? '{}';
    final usuario = jsonDecode(rawUser) as Map<String, dynamic>;
    final rol     = usuario['rol']?.toString()    ?? 'admin';
    final nombre  = usuario['nombre']?.toString() ?? usuario['username']?.toString() ?? '';

    setState(() {
      _rol      = rol;
      _nombre   = nombre;
      _visibles = _navItemsParaRol(rol);
    });
  }

  // Filtra los items según rol
  List<_NavItem> _navItemsParaRol(String rol) {
    return _navItems.where((item) => item.roles.contains(rol)).toList();
  }

  // Índice visible a partir del índice global
  int get _selectedVisible {
    if (widget.selectedIndex < 0 || widget.selectedIndex >= _navItems.length) return 0;
    final ruta = _navItems[widget.selectedIndex].ruta;
    final idx  = _visibles.indexWhere((i) => i.ruta == ruta);
    return idx < 0 ? 0 : idx;
  }

  void _navegar(BuildContext context, int visibleIdx) {
    if (visibleIdx < 0 || visibleIdx >= _visibles.length) return;
    final ruta = _visibles[visibleIdx].ruta;
    Navigator.pushReplacementNamed(context, ruta);
  }

  Future<void> _salir(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_visibles.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()));
    }
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return isDesktop ? _desktop(context) : _mobile(context);
  }

  // ── Desktop ───────────────────────────────────
  Widget _desktop(BuildContext context) => Scaffold(
    body: Row(children: [
      Container(
        width: 210,
        color: const Color(0xFF1A237E),
        child: Column(children: [
          // Logo + nombre usuario
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('SuperBett',
                style: TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              if (_nombre.isNotEmpty)
                Text(_nombre,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
                child: Text(_rol.toUpperCase(),
                  style: const TextStyle(color: Colors.white70,
                      fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 8),

          // Items del menú
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            itemCount: _visibles.length,
            itemBuilder: (_, i) {
              final sel  = _selectedVisible == i;
              final item = _visibles[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _navegar(context, i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: sel
                            ? Colors.white.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: sel
                            ? Border.all(color: Colors.white.withOpacity(0.2))
                            : null,
                      ),
                      child: Row(children: [
                        Icon(sel ? item.iconSel : item.icon,
                            color: sel ? Colors.white : Colors.white60,
                            size: 20),
                        const SizedBox(width: 12),
                        Text(item.label,
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.white70,
                            fontWeight: sel
                                ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 14)),
                      ]),
                    ),
                  ),
                ),
              );
            },
          )),

          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _salir(context),
                icon: const Icon(Icons.logout, color: Colors.white60, size: 18),
                label: const Text('Salir',
                    style: TextStyle(color: Colors.white60,
                        fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11)),
              )),
          ),
        ]),
      ),
      const VerticalDivider(width: 1),
      Expanded(child: widget.child),
    ]),
  );

  // ── Mobile ────────────────────────────────────
  Widget _mobile(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('SuperBett Admin'),
      backgroundColor: const Color(0xFF1A237E),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _salir(context),
          tooltip: 'Salir'),
      ],
    ),
    drawer: Drawer(
      child: Column(children: [
        Container(
          width: double.infinity,
          color: const Color(0xFF1A237E),
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SuperBett',
                style: TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w900)),
              if (_nombre.isNotEmpty)
                Text(_nombre,
                    style: const TextStyle(color: Colors.white70,
                        fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
                child: Text(_rol.toUpperCase(),
                  style: const TextStyle(color: Colors.white70,
                      fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _visibles.length,
          itemBuilder: (_, i) {
            final sel  = _selectedVisible == i;
            final item = _visibles[i];
            return ListTile(
              leading: Icon(
                sel ? item.iconSel : item.icon,
                color: sel ? const Color(0xFF1A237E) : Colors.grey),
              title: Text(item.label,
                style: TextStyle(
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  color: sel ? const Color(0xFF1A237E) : Colors.black87)),
              selected: sel,
              selectedTileColor: const Color(0xFF1A237E).withOpacity(0.08),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              onTap: () {
                Navigator.pop(context);
                _navegar(context, i);
              },
            );
          },
        )),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Salir',
              style: TextStyle(color: Colors.red)),
          onTap: () => _salir(context),
        ),
        const SizedBox(height: 16),
      ]),
    ),
    body: widget.child,
  );
}
