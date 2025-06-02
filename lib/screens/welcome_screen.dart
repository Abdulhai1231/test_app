import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/main.dart'; // Hauptdatei deiner App (für Routen etc.)
import 'package:einkaufsliste/screens/auth/auth_screen.dart'; // Screen für Login/Registrierung
import 'package:einkaufsliste/services/auth_service.dart'; // Authentifizierungs-Service

/// Der erste Bildschirm, den der Benutzer sieht.
/// Bietet zwei Optionen: Anonym fortfahren oder einloggen.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Obere App-Leiste
      appBar: AppBar(title: const Text('Welcome')),

      // Hauptinhalt des Screens
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Zentriert vertikal
          children: [
            // Begrüßungstext
            const Text('Welcome to the App!'),

            const SizedBox(height: 20), // Abstand

            // Button zum anonymen Einloggen
            ElevatedButton(
              onPressed: () {
                _handleAnonymousSignIn(context); // Funktion unten aufrufen
              },
              child: const Text('Enter Without Login'), // Button-Text
            ),

            const SizedBox(height: 20), // Abstand

            // Button zum Weiterleiten zur Login-Seite
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()), // Navigiere zu AuthScreen
                );
              },
              child: const Text('Login'), // Button-Text
            ),
          ],
        ),
      ),
    );
  }

  /// Funktion zum anonymen Einloggen über Firebase
  Future<void> _handleAnonymousSignIn(BuildContext context) async {
    try {
      // Zugriff auf den AuthService über Provider
      final authService = Provider.of<AuthService>(context, listen: false);

      // Versuche, anonymen Benutzer anzumelden
      await authService.signInAnonymously();

      // Nach erfolgreichem Login, Navigation zur Startseite
      Navigator.of(context).pushReplacementNamed('/home');

    } catch (e) {
      // Falls ein Fehler passiert, zeige eine Fehlermeldung
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
