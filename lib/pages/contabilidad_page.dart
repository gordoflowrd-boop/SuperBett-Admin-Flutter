import 'package:flutter/material.dart';
import '../layout/app_layout.dart';

class ContabilidadPage extends StatelessWidget {
  const ContabilidadPage({super.key});

  @override
  Widget build(BuildContext context) => AppLayout(
    selectedIndex: 10,
    child: Column(children: [
      Container(
        color: const Color(0xFF1A237E),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: const Row(children: [
          Expanded(child: Text('Contabilidad',
              style: TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.bold))),
          Icon(Icons.account_balance_outlined, color: Colors.white, size: 20),
        ]),
      ),
      const Expanded(child: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Contabilidad', style: TextStyle(fontSize: 20,
              fontWeight: FontWeight.bold, color: Colors.grey)),
          SizedBox(height: 8),
          Text('Próximamente', style: TextStyle(color: Colors.grey)),
        ],
      ))),
    ]),
  );