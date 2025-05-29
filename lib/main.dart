import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/workout/workout_form_screen.dart';
import 'screens/workout/workout_list_screen.dart';
import 'screens/workout/workout_details_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/metrics/metrics_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strong One',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
          background: Colors.grey[900]!,
          surface: Colors.grey[850]!,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.amber,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.amber,
          textTheme: ButtonTextTheme.primary,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.grey[850],
          indicatorColor: Colors.amber.withOpacity(0.3),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(color: Colors.amber),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.grey[850],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.amber, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.amber),
          prefixIconColor: Colors.amber,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/workout/list',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/workout/list': (context) => const WorkoutListScreen(),
        '/workout/new': (context) => const WorkoutFormScreen(),
        '/workout/details': (context) => const WorkoutDetailsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/metrics': (context) => const MetricsScreen(),
      },
    );
  }
}
