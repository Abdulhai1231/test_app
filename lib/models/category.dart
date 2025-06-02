import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

// Beispielklasse Category (könnte in eigenem Datei sein)
class Category {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
  });
}

class _AuthScreenState extends State<AuthScreen> {
  // Formular-Schlüssel für Validierung
  final _formKey = GlobalKey<FormState>();

  // Controller für Textfelder
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Ladezustand und Fehlermeldung
  bool _isLoading = false;
  String? _errorMessage;

  // Funktion zum Einloggen
  Future<void> _login() async {
    // Prüfen, ob das Formular gültig ist
    if (!_formKey.currentState!.validate()) return;

    // Ladezustand setzen und Fehlermeldung löschen
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // AuthService aus Provider holen (ohne Listener)
    final authService = Provider.of<AuthService>(context, listen: false);

    // Versuch, mit E-Mail & Passwort einzuloggen
    final user = await authService.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // Ladezustand zurücksetzen
    setState(() {
      _isLoading = false;
    });

    // Falls Login fehlschlägt, Fehlermeldung anzeigen
    if (user == null) {
      setState(() {
        _errorMessage = 'Login failed. Please check your credentials.';
      });
    } else {
      // Bei Erfolg: Optional Login-Screen schließen
      Navigator.of(context).pop();
      // Navigation kann auch anders gehandhabt werden,
      // z.B. AuthWrapper lauscht auf User-Änderungen und navigiert automatisch
    }
  }

  @override
  void dispose() {
    // Controller freigeben, um Speicherlecks zu vermeiden
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Fehler anzeigen, falls vorhanden
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),

              // E-Mail Eingabe
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || !value.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),

              // Passwort Eingabe
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) =>
                    value == null || value.length < 6 ? 'Enter min. 6 chars' : null,
              ),
              const SizedBox(height: 24),

              // Ladeindikator oder Login-Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
