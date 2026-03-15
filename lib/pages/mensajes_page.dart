import 'package:flutter/material.dart';
import '../layout/app_layout.dart';

class MensajesPage extends StatelessWidget {
  const MensajesPage({super.key});
  @override
  Widget build(BuildContext context) => AppLayout(
    selectedIndex: 8,
    child: const Center(child: Text('Mensajes — Próximamente',
        style: TextStyle(color: Colors.grey))),
  );
}