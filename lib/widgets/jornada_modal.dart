import 'package:flutter/material.dart';
import '../models/jornada.dart';

class JornadaModal extends StatelessWidget {
  final Jornada jornada;

  const JornadaModal({
    super.key,
    required this.jornada,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(jornada.loteria ?? "Jornada"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Estado: ${jornada.estado ?? '-'}"),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar"),
        ),
      ],
    );
  }
}