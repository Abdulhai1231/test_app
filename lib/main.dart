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
import 'firebase_options.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_navigation_screen.dart';

// Globaler Navigationsschlüssel für Navigation ohne BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Sicherstellen, dass Flutter Widgets korrekt initialisiert sind
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase mit plattformspezifischen Optionen initialisieren
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App mit mehreren Providern für State Management starten
  runApp(
    MultiProvider(
      providers: [
        // AuthService Provider für Authentifizierungsfunktionen
        Provider<AuthService>(create: (_) => AuthService()),
        
        // StreamProvider für Authentifizierungsstatus des Benutzers
        StreamProvider<UserModel?>(
          create: (context) => Provider.of<AuthService>(context, listen: false).user,
          initialData: null,
        ),
        
        // ThemeProvider für App-Design-Einstellungen
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // FamilyService für Familienbezogene Funktionen
        Provider<FamilyService>(create: (_) => FamilyService()),

        // DatabaseService, der sich bei Benutzeränderungen aktualisiert
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

class DefaultFirebaseOptions {
  static var currentPlatform;
}

// Hauptwidget der Anwendung
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Einkaufsliste',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: const AuthWrapper(),
          routes: {
            '/home': (context) => MainAppScreen(),
          },
        );
      },
    );
  }
}

// Widget, das den Authentifizierungsstatus überwacht und entsprechend navigiert
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return StreamBuilder<UserModel?>(
      stream: authService.user,
      builder: (context, snapshot) {
        // Ladeindikator während der Authentifizierungsprüfung
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Wenn Benutzer angemeldet ist, zeige Hauptansicht
        if (snapshot.hasData) {
          return const MainAppScreen();
        } 
        // Wenn nicht angemeldet, zeige Willkommensbildschirm
        else {
          return const WelcomeScreen();
        }
      },
    );
  }
}

// Hauptbildschirm mit Bottom-Navigation
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0; // Index des aktuell ausgewählten Tabs

  // Bildschirme für die einzelnen Navigationselemente
  final List<Widget> _screens = [
    const HomeScreen(),
    const ListsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack behält den Zustand beim Tab-Wechsel
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // Bottom-Navigation für die Hauptnavigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Startseite'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Listen'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Einstellungen'),
        ],
      ),
    );
  }
}