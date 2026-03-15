import 'package:flutter/material.dart';
import '../layout/app_layout.dart';

class ContabilidadPage extends StatelessWidget {
  const ContabilidadPage({super.key});
  @override
  Widget build(BuildContext context) => AppLayout(
    selectedIndex: 7,
    child: const Center(child: Text('Contabilidad — Próximamente',
        style: TextStyle(color: Colors.grey))),
  );
}