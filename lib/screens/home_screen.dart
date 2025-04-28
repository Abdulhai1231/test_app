import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key}); // Proper Widget constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/shopping.png'), // Make sure to add the image in `pubspec.yaml`
            const Text('Welcome to the Home Screen!'), // Just some content
          ],
        ),
      ),
    );
  }
}
