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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to Family Shopping List'),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Sign In with Google'),
              onPressed: () => _handleGoogleSignIn(context),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              child: const Text('Continue as Guest'),
              onPressed: () => _handleAnonymousSignIn(context),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Provider<AuthService>.value(
                    value: Provider.of<AuthService>(context, listen: false),
                    child: const LoginScreen(),
                  ),
                ),
              ),
              child: const Text('Email Login'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Provider<AuthService>.value(
                    value: Provider.of<AuthService>(context, listen: false),
                    child: const RegisterScreen(),
                  ),
                ),
              ),
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithGoogle();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

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