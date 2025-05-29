import 'package:einkaufsliste/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:einkaufsliste/screens/home_screen.dart';
import 'package:einkaufsliste/screens/lists_screen.dart';
import 'package:einkaufsliste/screens/settings_screen.dart';
import 'package:einkaufsliste/screens/welcome_screen.dart';

import 'services/auth_service.dart';
import 'providers/theme_provider.dart';
import 'services/database_service.dart';
import 'services/family_service.dart';
import 'models/user_model.dart';

import 'screens/auth/auth_screen.dart';
import 'screens/main_navigation_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<UserModel?>(
          create: (context) => Provider.of<AuthService>(context, listen: false).user,
          initialData: null,
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<FamilyService>(create: (_) => FamilyService()),

        /// ✅ ProxyProvider that rebuilds DatabaseService when UserModel changes
        ProxyProvider<UserModel?, DatabaseService>(
          update: (context, user, _) => DatabaseService(
            userId: user?.uid ?? '',
            familyId: user?.familyId ?? '',
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Shopping App',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home:  AuthWrapper(),
          routes: {
          '/home': (context) => MainAppScreen(),
        },
        );
      },
    );
  }
}

  class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // User is logged in, show the full MainAppScreen with tabs
          return const MainAppScreen();
        } else {
          // User is NOT logged in
          return const WelcomeScreen();
        }
      },
    );
  }
}



class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ListsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lists'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
