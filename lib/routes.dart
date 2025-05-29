import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/workout/workout_templates_screen.dart';
import 'screens/workout/workout_form_screen.dart';
import 'screens/workout/workout_details_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/metrics/metrics_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String workoutTemplates = '/workout/templates';
  static const String workoutForm = '/workout/new';
  static const String workoutDetails = '/workout/details';
  static const String profile = '/profile';
  static const String metrics = '/metrics';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        home: (context) => const HomeScreen(),
        workoutTemplates: (context) => const WorkoutTemplatesScreen(),
        workoutForm: (context) => const WorkoutFormScreen(),
        workoutDetails: (context) => const WorkoutDetailsScreen(),
        profile: (context) => const ProfileScreen(),
        metrics: (context) => const MetricsScreen(),
      };
} 