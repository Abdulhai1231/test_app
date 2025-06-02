import 'package:flutter/material.dart';
import 'home_screen.dart';        // Startbildschirm/Home
import 'lists_screen.dart';      // Bildschirm mit Einkaufslisten
import 'settings_screen.dart';   // Einstellungen

/// Die Haupt-App-Oberfläche mit einer unteren Navigationsleiste.
/// Sie wechselt zwischen Home, Listen und Einstellungen.
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  // Der aktuell ausgewählte Index der Navigationsleiste
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Liste der Seiten, die zur Navigation verfügbar sind
    final List<Widget> screens = [
      const HomeScreen(),      // Index 0: Home
      const ListsScreen(),     // Index 1: Listen
      const SettingsScreen(),  // Index 2: Einstellungen
    ];

    return Scaffold(
      // Zeigt den aktuell ausgewählten Bildschirm basierend auf _currentIndex
      body: screens[_currentIndex],

      // Untere Navigationsleiste
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Welcher Tab ist aktiv
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Aktualisiert den aktiven Index beim Tippen
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home', // Beschriftung des Tabs
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Lists', // Beschriftung des Tabs
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings', // Beschriftung des Tabs
          ),
        ],
      ),
    );
  }
}
