import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/result_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final userName = prefs.getString('userName');
  runApp(MyApp(startScreen: userName == null ? const WelcomeScreen() : const HomeScreen()));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4CAF50);

    final light = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );

    final dark = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plant Guard Vision',
      theme: light,
      darkTheme: dark,
      themeMode: ThemeMode.system,
      home: startScreen,
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/home': (_) => const HomeScreen(),
        '/result': (_) => const ResultScreen(),
      },
    );
  }
}
