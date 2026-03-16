import 'package:flutter/material.dart';
import '../layout/app_layout.dart';

class MensajesPage extends StatelessWidget {
  const MensajesPage({super.key});

  @override
  Widget build(BuildContext context) => AppLayout(
    selectedIndex: 7,
    child: Column(children: [
      Container(
        color: const Color(0xFF1A237E),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: const Row(children: [
          Expanded(child: Text('Mensajes',
              style: TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.bold))),
          Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
        ]),
      ),
      const Expanded(child: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Mensajes', style: TextStyle(fontSize: 20,
              fontWeight: FontWeight.bold, color: Colors.grey)),
          SizedBox(height: 8),
          Text('Próximamente', style: TextStyle(color: Colors.grey)),
        ],
      ))),
    ]),
  );
}