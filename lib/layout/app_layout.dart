import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLayout extends StatelessWidget {
  final int selectedIndex;
  final Widget child;
  final Function(int) onItemSelected;

  const AppLayout({
    super.key,
    required this.selectedIndex,
    required this.child,
    required this.onItemSelected,
  });

  static const _items = [
    {'label': 'Menú',          'icon': Icons.home_outlined,            'iconSel': Icons.home},
    {'label': 'Bancas',        'icon': Icons.storefront_outlined,      'iconSel': Icons.storefront},
    {'label': 'Venta',         'icon': Icons.receipt_long_outlined,    'iconSel': Icons.receipt_long},
    {'label': 'Premios',       'icon': Icons.emoji_events_outlined,    'iconSel': Icons.emoji_events},
    {'label': 'Reportes',      'icon': Icons.bar_chart_outlined,       'iconSel': Icons.bar_chart},
    {'label': 'Usuarios',      'icon': Icons.people_outline,           'iconSel': Icons.people},
    {'label': 'Límites',       'icon': Icons.tune_outlined,            'iconSel': Icons.tune},
    {'label': 'Configuración', 'icon': Icons.settings_outlined,        'iconSel': Icons.settings},
    {'label': 'Riferos',       'icon': Icons.manage_accounts_outlined, 'iconSel': Icons.manage_accounts},
    {'label': 'Descargas',     'icon': Icons.download_outlined,        'iconSel': Icons.download},
  ];

  Future<void> _salir(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return isDesktop ? _desktop(context) : _mobile(context);
  }

  Widget _desktop(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        Container(
          width: 200,
          color: const Color(0xFF1A237E),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              alignment: Alignment.centerLeft,
              child: const Text("SuperBett",
                style: TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 8),
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final sel = selectedIndex == i;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onItemSelected(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: sel ? Colors.white.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: sel ? Border.all(color: Colors.white.withOpacity(0.2)) : null,
                        ),
                        child: Row(children: [
                          Icon(
                            sel ? _items[i]['iconSel'] as IconData : _items[i]['icon'] as IconData,
                            color: sel ? Colors.white : Colors.white60, size: 20),
                          const SizedBox(width: 12),
                          Text(_items[i]['label'] as String,
                            style: TextStyle(
                              color: sel ? Colors.white : Colors.white70,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
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
                  label: const Text("Salir",
                      style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11)),
                )),
            ),
          ]),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: child),
      ]),
    );
  }

  Widget _mobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SuperBett Admin"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _salir(context),
            tooltip: "Salir"),
        ],
      ),
      drawer: Drawer(
        child: Column(children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF1A237E),
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            child: const Text("SuperBett",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final sel = selectedIndex == i;
              return ListTile(
                leading: Icon(
                  sel ? _items[i]['iconSel'] as IconData : _items[i]['icon'] as IconData,
                  color: sel ? const Color(0xFF1A237E) : Colors.grey),
                title: Text(_items[i]['label'] as String,
                  style: TextStyle(
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? const Color(0xFF1A237E) : Colors.black87)),
                selected: sel,
                selectedTileColor: const Color(0xFF1A237E).withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () { Navigator.pop(context); onItemSelected(i); },
              );
            },
          )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Salir", style: TextStyle(color: Colors.red)),
            onTap: () => _salir(context),
          ),
          const SizedBox(height: 16),
        ]),
      ),
      body: child,
    );
  }
}

