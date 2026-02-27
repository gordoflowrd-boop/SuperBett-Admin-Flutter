import 'package:flutter/material.dart';

class AppLayout extends StatefulWidget {
  final int selectedIndex;
  final Widget child;
  final Function(int) onItemSelected;

  const AppLayout({
    super.key,
    required this.selectedIndex,
    required this.child,
    required this.onItemSelected,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (!isDesktop) {
      return Scaffold(
        appBar: AppBar(title: const Text("SuperBett Admin")),
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.selectedIndex,
          onDestinationSelected: widget.onItemSelected,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: "Menú"),
            NavigationDestination(icon: Icon(Icons.emoji_events), label: "Premios"),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onItemSelected,
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "SuperBett",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text("Menú"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.emoji_events),
                label: Text("Premios"),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}