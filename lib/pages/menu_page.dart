import 'package:flutter/material.dart';
import '../widgets/app_layout.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int index = 0;

  void onSelect(int i) {
    if (i == 1) {
      Navigator.pushReplacementNamed(context, "/premios");
      return;
    }
    setState(() => index = i);
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 0,
      onItemSelected: onSelect,
      child: const Center(
        child: Text(
          "Menú Principal",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}