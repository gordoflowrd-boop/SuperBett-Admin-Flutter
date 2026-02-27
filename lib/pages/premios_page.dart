import 'package:flutter/material.dart';
import '../models/jornada.dart';
import '../services/premios_service.dart';
import '../layout/app_layout.dart';
import '../widgets/jornada_modal.dart';

class PremiosPage extends StatefulWidget {
  const PremiosPage({super.key});

  @override
  State<PremiosPage> createState() => _PremiosPageState();
}

class _PremiosPageState extends State<PremiosPage> {
  List<Jornada> jornadas = [];
  bool loading = true;
  String fecha = DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    setState(() => loading = true);
    try {
      jornadas = await PremiosService.obtenerJornadas(fecha);
    } catch (e) {
      debugPrint("Error cargando jornadas: $e");
    }
    setState(() => loading = false);
  }

  void onSelect(int i) {
    if (i == 0) {
      Navigator.pushReplacementNamed(context, "/menu");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 1,
      onItemSelected: onSelect,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () async {
                      await PremiosService.generar(fecha);
                      await cargar();
                    },
                    child: const Text("Generar Jornadas"),
                  ),
                ),
                Expanded(
                  child: jornadas.isEmpty
                      ? const Center(
                          child: Text("No hay jornadas disponibles"),
                        )
                      : ListView.builder(
                          itemCount: jornadas.length,
                          itemBuilder: (context, index) {
                            final j = jornadas[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: ListTile(
                                title: Text(j.loteria ?? "-"),
                                subtitle: Text("Estado: ${j.estado}"),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (_) =>
                                          JornadaModal(jornada: j),
                                    );
                                    await cargar();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}