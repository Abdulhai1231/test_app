import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeProvider with ChangeNotifier {
  // Aktueller ThemeMode (Light oder Dark), Standard ist Light
  ThemeMode _themeMode = ThemeMode.light;

  // Getter für den aktuellen ThemeMode
  ThemeMode get themeMode => _themeMode;

  // Prüft, ob Dark Mode aktiv ist
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Gibt das aktuell aktive ThemeData zurück, je nach ThemeMode
  ThemeData get currentTheme => isDarkMode ? _darkTheme : _lightTheme;

  // Definiert das helle Theme
  static final ThemeData _lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 32, 70, 119),
      foregroundColor: Colors.white,
    ),
  );

  // Definiert das dunkle Theme
  static final ThemeData _darkTheme = ThemeData(
    primarySwatch: Colors.blueGrey,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
    ),
  );

  // Methode zum Umschalten zwischen Light und Dark Mode
  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();  // Benachrichtigt alle Listener, dass sich das Theme geändert hat
  }
}
