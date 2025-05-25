import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/main.dart';
import 'package:einkaufsliste/screens/auth/auth_screen.dart';
import 'package:einkaufsliste/services/auth_service.dart';


class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the App!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _handleAnonymousSignIn(context); // Handle anonymous sign-in
              },
              child: const Text('Enter Without Login'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()), // Go to login screen
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  // Handle anonymous sign-in
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
