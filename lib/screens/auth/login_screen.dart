import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/screens/auth/register_screen.dart';
import 'package:einkaufsliste/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Key für die Formularvalidierung
  final _formKey = GlobalKey<FormState>();

  // Controller für die Eingabefelder Email und Passwort
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Status ob gerade ein Ladevorgang (Login) läuft
  bool _isLoading = false;

  // Fehlernachricht, die bei falschen Eingaben angezeigt wird
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey, // Formular mit Validierung
          child: Column(
            children: [
              // Email-Eingabefeld mit Validierung
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              // Passwort-Eingabefeld mit Validierung
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true, // Passwort verdeckt eingeben
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              // Anzeige der Fehlernachricht (z.B. falsches Passwort)
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              // Ladeindikator oder Login-Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      child: const Text('Login'),
                    ),
              // Button zur Registrierung - navigiert zum RegisterScreen
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Methode, die Login-Prozess durchführt
  Future<void> _handleLogin() async {
    // Prüfe, ob die Eingaben gültig sind
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;   // Ladezustand aktivieren
      _errorMessage = null; // Fehlernachricht zurücksetzen
    });

    try {
      final email = _emailController.text.trim();
      debugPrint('Attempting login with email: $email');

      // 1. Prüfe, ob die Email in Firebase existiert
      // (fetchSignInMethodsForEmail ist veraltet, aber hier verwendet)
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      debugPrint('Available sign-in methods: $methods');

      // Wenn keine Methode zurückkommt, existiert kein Account mit der Email
      if (methods.isEmpty) {
        setState(() => _errorMessage = 'No account found for this email');
        return;
      }

      // 2. Versuch dich einzuloggen
      debugPrint('Attempting sign-in...');
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.signInWithEmailAndPassword(
        email,
        _passwordController.text, // Passwort nicht trimmen!
      );
      
      debugPrint('Login result: ${user?.uid ?? "null"}');

      // Falls Email nicht verifiziert ist, Fehler anzeigen
      if (user != null && !user.emailVerified) {
        setState(() => _errorMessage = 'Invalid password'); // Hier könntest du 'Email not verified' schreiben
      }
    } on FirebaseAuthException catch (e) {
      // Spezifische Firebase-Fehler ausgeben
      debugPrint('FIREBASE ERROR: ${e.code} - ${e.message}');
      setState(() => _errorMessage = _getErrorMessage(e.code));
    } catch (e) {
      // Generischer Fehler
      debugPrint('GENERIC ERROR: $e');
      setState(() => _errorMessage = 'Login failed');
    } finally {
      setState(() => _isLoading = false); // Ladezustand deaktivieren
    }
  }

  // Hilfsmethode: Fehlercode in benutzerfreundliche Nachricht umwandeln
  String _getErrorMessage(String code) {
    switch (code) {
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-not-found':
        return 'No account found for this email';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'invalid-email':
        return 'Please enter a valid email';
      default:
        return 'Login failed. Please try again';
    }
  }

  @override
  void dispose() {
    // Controller beim Verwerfen des Widgets freigeben
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
