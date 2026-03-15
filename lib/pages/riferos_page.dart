import 'package:flutter/material.dart';
import '../layout/app_layout.dart';
import '../services/riferos_service.dart';

const _kAzul = Color(0xFF1A237E);
const _kRojo = Color(0xFFD32F2F);

class RiferosPage extends StatefulWidget {
  const RiferosPage({super.key});
  @override State<RiferosPage> createState() => _RiferosPageState();
}

class _RiferosPageState extends State<RiferosPage> {
  List<Map<String, dynamic>> _riferos   = [];
  bool   _loading = true;
  String _error   = '';


  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final riferos = await RiferosService.obtenerRiferos();
      // Para cada rifero cargar sus bancas y vendedores
      final enriquecidos = await Future.wait(riferos.map((r) async {
        final bancas    = await RiferosService.bancasDeRifero(r['id'].toString());
        final vendedores = await RiferosService.vendedoresDeRifero(r['id'].toString());
        return {...r, 'bancas': bancas, 'vendedores': vendedores};
      }));
      setState(() { _riferos = enriquecidos; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) => AppLayout(
    selectedIndex: 5,
    child: Column(children: [
      // Header
      Container(
        color: _kAzul,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: [
          const Expanded(child: Text('Riferos',
              style: TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.bold))),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargar),
        ]),
      ),

      if (_loading)
        const Expanded(child: Center(child: CircularProgressIndicator()))
      else if (_error.isNotEmpty)
        Expanded(child: Center(child: Text(_error,
            style: const TextStyle(color: Colors.red))))
      else if (_riferos.isEmpty)
        const Expanded(child: Center(child: Text('No hay riferos',
            style: TextStyle(color: Colors.grey))))
      else
        Expanded(child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _riferos.length,
            itemBuilder: (_, i) => _RiferoCard(
              rifero: _riferos[i],
              onUpdated: _cargar,
            ),
          ),
        )),
    ]),
  );
}

// ─────────────────────────────────────────────
// Card de un rifero
// ─────────────────────────────────────────────
class _RiferoCard extends StatelessWidget {
  final Map<String, dynamic> rifero;
  final VoidCallback onUpdated;
  const _RiferoCard({required this.rifero, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final bancas    = List<Map<String, dynamic>>.from(rifero['bancas']    ?? []);
    final vendedores = List<Map<String, dynamic>>.from(rifero['vendedores'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header rifero
          Row(children: [
            const Icon(Icons.manage_accounts, color: _kAzul, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rifero['nombre']?.toString() ?? rifero['username']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('@${rifero['username']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ])),
            // Botón gestionar vendedores
            TextButton.icon(
              onPressed: () => _abrirVendedores(context),
              icon: const Icon(Icons.group_add_outlined, size: 16),
              label: const Text('Vendedores'),
              style: TextButton.styleFrom(foregroundColor: _kAzul),
            ),
          ]),
          const SizedBox(height: 10),

          // Bancas
          if (bancas.isNotEmpty) ...[
            Text('Bancas (${bancas.length})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Colors.grey, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4,
              children: bancas.map((b) => Chip(
                label: Text(b['nombre']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12)),
                backgroundColor: _kAzul.withOpacity(0.08),
                side: BorderSide(color: _kAzul.withOpacity(0.3)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList()),
            const SizedBox(height: 10),
          ],

          // Vendedores
          if (vendedores.isNotEmpty) ...[
            Text('Vendedores (${vendedores.length})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Colors.grey, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4,
              children: vendedores.map((v) => Chip(
                avatar: const Icon(Icons.person_outline, size: 14),
                label: Text(v['username']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.green.withOpacity(0.08),
                side: BorderSide(color: Colors.green.withOpacity(0.3)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onDeleted: () => _quitarVendedor(
                    context, v['id'].toString(), rifero['id'].toString()),
                deleteIcon: const Icon(Icons.close, size: 14),
                deleteIconColor: _kRojo,
              )).toList()),
          ] else
            Text('Sin vendedores asignados',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12,
                    fontStyle: FontStyle.italic)),
        ]),
      ),
    );
  }

  Future<void> _quitarVendedor(
      BuildContext context, String vendedorId, String riferoId) async {
    try {
      await RiferosService.quitarVendedor(vendedorId, riferoId);
      onUpdated();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _abrirVendedores(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _VendedoresModal(
        rifero: rifero,
        onUpdated: onUpdated,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Modal para asignar/quitar vendedores
// ─────────────────────────────────────────────
class _VendedoresModal extends StatefulWidget {
  final Map<String, dynamic> rifero;
  final VoidCallback onUpdated;
  const _VendedoresModal({required this.rifero, required this.onUpdated});
  @override State<_VendedoresModal> createState() => _VendedoresModalState();
}

class _VendedoresModalState extends State<_VendedoresModal> {
  List<Map<String, dynamic>> _todosVendedores = [];
  Set<String> _asignados = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final todos     = await RiferosService.obtenerVendedores();
      final asignados = await RiferosService.vendedoresDeRifero(
          widget.rifero['id'].toString());
      final idsAsignados = asignados.map((v) => v['id'].toString()).toSet();
      setState(() {
        _todosVendedores = todos;
        _asignados       = idsAsignados;
        _loading         = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(String vendedorId, bool estaAsignado) async {
    try {
      if (estaAsignado) {
        await RiferosService.quitarVendedor(
            vendedorId, widget.rifero['id'].toString());
        setState(() => _asignados.remove(vendedorId));
      } else {
        await RiferosService.asignarVendedor(
            vendedorId, widget.rifero['id'].toString());
        setState(() => _asignados.add(vendedorId));
      }
      widget.onUpdated();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.6,
    maxChildSize: 0.9,
    minChildSize: 0.4,
    expand: false,
    builder: (_, ctrl) => Column(children: [
      // Handle
      Container(margin: const EdgeInsets.only(top: 10),
        width: 40, height: 4,
        decoration: BoxDecoration(color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2))),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          const Icon(Icons.group, color: _kAzul),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'Vendedores — ${widget.rifero['nombre'] ?? widget.rifero['username']}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
        ]),
      ),
      const Divider(height: 1),
      if (_loading)
        const Expanded(child: Center(child: CircularProgressIndicator()))
      else if (_todosVendedores.isEmpty)
        const Expanded(child: Center(
            child: Text('No hay vendedores', style: TextStyle(color: Colors.grey))))
      else
        Expanded(child: ListView.builder(
          controller: ctrl,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _todosVendedores.length,
          itemBuilder: (_, i) {
            final v          = _todosVendedores[i];
            final id         = v['id'].toString();
            final asignado   = _asignados.contains(id);
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: asignado
                    ? Colors.green.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.1),
                child: Icon(Icons.person_outline,
                    color: asignado ? Colors.green : Colors.grey, size: 20),
              ),
              title: Text(v['nombre']?.toString() ?? v['username']?.toString() ?? ''),
              subtitle: Text('@${v['username']}',
                  style: const TextStyle(fontSize: 12)),
              trailing: Switch(
                value: asignado,
                activeColor: _kAzul,
                onChanged: (_) => _toggle(id, asignado),
              ),
            );
          },
        )),
    ]),
  );
}

