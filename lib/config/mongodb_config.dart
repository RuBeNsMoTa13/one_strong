import 'package:flutter_dotenv/flutter_dotenv.dart';

class MongoDBConfig {
  // Credenciais do MongoDB Atlas
  static String get username => dotenv.env['MONGODB_USER'] ?? '';
  static String get password => dotenv.env['MONGODB_PASSWORD'] ?? '';
  static String get host => dotenv.env['MONGODB_HOST'] ?? '';
  static String get database => dotenv.env['MONGODB_DATABASE'] ?? '';

  // Conexão com o MongoDB Atlas
  static String get connectionString {
    return 'mongodb+srv://$username:$password@$host/$database?ssl=true&sslValidate=false&tlsAllowInvalidCertificates=true&tlsAllowInvalidHostnames=true&retryWrites=true&w=majority';
  }
  
  static int get port => int.parse(dotenv.env['PORT'] ?? '3000');

  // Collections
  static const String usersCollection = 'users';
  static const String workoutTemplatesCollection = 'workout_templates';
  static const String exerciseProgressCollection = 'exercise_progress';

  // Configurações de conexão
  static const int connectionTimeout = 30000; // 30 segundos
  static const int maxConnectionRetries = 3;
} 