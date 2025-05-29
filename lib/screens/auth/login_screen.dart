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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
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
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      child: const Text('Login'),
                    ),
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

  Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final email = _emailController.text.trim();
    debugPrint('Attempting login with email: $email');

    // 1. Check if email exists in Firebase
    // ignore: deprecated_member_use
    final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    debugPrint('Available sign-in methods: $methods');

    if (methods.isEmpty) {
      setState(() => _errorMessage = 'No account found for this email');
      return;
    }

    // 2. Attempt login
    debugPrint('Attempting sign-in...');
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.signInWithEmailAndPassword(
      email,
      _passwordController.text, // Don't trim passwords!
    );
    
    debugPrint('Login result: ${user?.uid ?? "null"}');

    if (user != null && !user.emailVerified) {
      setState(() => _errorMessage = 'Invalid password');
    }
  } on FirebaseAuthException catch (e) {
    debugPrint('FIREBASE ERROR: ${e.code} - ${e.message}');
    setState(() => _errorMessage = _getErrorMessage(e.code));
  } catch (e) {
    debugPrint('GENERIC ERROR: $e');
    setState(() => _errorMessage = 'Login failed');
  } finally {
    setState(() => _isLoading = false);
  }
}

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}