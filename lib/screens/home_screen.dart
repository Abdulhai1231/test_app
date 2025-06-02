import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key}); // Konstruktor für das Widget

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'), // Titel der AppBar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Inhalte vertikal zentrieren
          children: [
            // Bild aus assets, stelle sicher, dass es in pubspec.yaml eingetragen ist
            Image.asset('images/shopping.png'),
            // Einfacher Text als Willkommensnachricht
            const Text('Welcome to the Home Screen!'),
          ],
        ),
      ),
    );
  }
}
