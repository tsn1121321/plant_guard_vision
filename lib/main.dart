import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PlantGuardApp());
}

class PlantGuardApp extends StatelessWidget {
  const PlantGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF006E00),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PlantGuard Vision',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        fontFamily: 'Roboto',
      ),
      home: const _Bootstrap(),
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/app': (_) => const AppShell(),
      },
    );
  }
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  Future<bool>? _future;

  Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasName = (prefs.getString('userName') ?? '').trim().isNotEmpty;
    final onboarded = prefs.getBool('onboarded') ?? false;
    return hasName || onboarded;
  }

  @override
  void initState() {
    super.initState();
    _future = _checkOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final done = snap.data!;
        return done ? const AppShell() : const WelcomeScreen();
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Histórico'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
        indicatorColor: theme.colorScheme.primary.withOpacity(0.15),
      ),
    );
  }
}
