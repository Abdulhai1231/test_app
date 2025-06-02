import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/screens/auth/login_screen.dart';
import 'package:einkaufsliste/screens/auth/register_screen.dart';
import '../../services/auth_service.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Haupt-Widget mit zentriertem Inhalt
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to Family Shopping List'), // Begrüßungstext
            const SizedBox(height: 20),

            // Button für Google-Sign-In
            ElevatedButton(
              child: const Text('Sign In with Google'),
              onPressed: () async {
                try {
                  // Zugriff auf AuthService über Provider (ohne Zuhören)
                  final authService = Provider.of<AuthService>(context, listen: false);
                  // Google-Sign-In durchführen (context wird benötigt für Navigation/Dialogs)
                  await authService.signInWithGoogle(context);
                } catch (e) {
                  // Fehler anzeigen, wenn Google-Sign-In fehlschlägt
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),

            const SizedBox(height: 10),

            // Button für anonymen Gastzugang
            ElevatedButton(
              child: const Text('Continue as Guest'),
              onPressed: () => _handleAnonymousSignIn(context),
            ),

            const SizedBox(height: 20),

            // Link zum Login mit Email/Passwort
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              ),
              child: const Text('Email Login'),
            ),

            // Link zur Registrierung (Neues Konto erstellen)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegisterScreen(),
                ),
              ),
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  // Hilfsmethode: Google-Sign-In mit Fehlerbehandlung
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithGoogle(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Hilfsmethode: Anonymes Anmelden mit Fehlerbehandlung
  Future<void> _handleAnonymousSignIn(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInAnonymously();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
