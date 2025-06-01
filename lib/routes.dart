import 'package:flutter/material.dart';
import 'models/workout_template.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/workout/workout_templates_screen.dart';
import 'screens/workout/workout_form_screen.dart';
import 'screens/workout/workout_details_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/metrics/metrics_screen.dart';
import 'screens/store/store_screen.dart'; // Importando a nova tela da loja

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String workoutTemplates = '/workout/templates';
  static const String workoutNew = '/workout/new';
  static const String workoutEdit = '/workout/edit';
  static const String workoutDetails = '/workout/details';
  static const String profile = '/profile';
  static const String metrics = '/metrics';
  static const String store = '/store'; // Nova rota para a loja

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    print('\n[Routes] Gerando rota: ${settings.name}');
    if (settings.arguments != null) {
      print('[Routes] Argumentos: ${settings.arguments}');
    }

    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case workoutTemplates:
        return MaterialPageRoute(builder: (_) => const WorkoutTemplatesScreen());
      case workoutNew:
        return MaterialPageRoute(builder: (_) => const WorkoutFormScreen());
      case workoutEdit:
        if (settings.arguments == null) {
          print('[Routes] ERRO: Nenhum argumento fornecido para $workoutEdit');
          throw ArgumentError('Nenhum argumento fornecido para $workoutEdit');
        }
        try {
          final template = settings.arguments as WorkoutTemplate;
          print('[Routes] Template válido para edição: ${template.name}');
          return MaterialPageRoute(
            builder: (_) => WorkoutFormScreen(template: template),
          );
        } catch (e) {
          print('[Routes] ERRO: Argumento inválido para $workoutEdit');
          print('[Routes] Tipo esperado: WorkoutTemplate');
          print('[Routes] Tipo recebido: ${settings.arguments.runtimeType}');
          throw ArgumentError('Argumento inválido para $workoutEdit. Esperado: WorkoutTemplate');
        }
      case workoutDetails:
        if (settings.arguments == null) {
          print('[Routes] ERRO: Nenhum argumento fornecido para $workoutDetails');
          throw ArgumentError('Nenhum argumento fornecido para $workoutDetails');
        }
        try {
          final workout = settings.arguments as WorkoutTemplate;
          print('[Routes] Template válido para detalhes: ${workout.name}');
          return MaterialPageRoute(
            builder: (_) => WorkoutDetailsScreen(workout: workout),
          );
        } catch (e) {
          print('[Routes] ERRO: Argumento inválido para $workoutDetails');
          print('[Routes] Tipo esperado: WorkoutTemplate');
          print('[Routes] Tipo recebido: ${settings.arguments.runtimeType}');
          throw ArgumentError('Argumento inválido para $workoutDetails. Esperado: WorkoutTemplate');
        }
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case metrics:
        return MaterialPageRoute(builder: (_) => const MetricsScreen());
      case store:
        return MaterialPageRoute(builder: (_) => StoreScreen());
      default:
        print('[Routes] ERRO: Rota não encontrada: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Rota não encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }
}