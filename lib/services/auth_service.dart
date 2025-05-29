import 'database_service.dart';
import '../models/user.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    try {
      // Busca o usuário pelo email
      final user = await DatabaseService.getUserByEmail(email);
      if (user == null) return false;

      // Verifica a senha
      // TODO: Implementar hash da senha
      if (user.password != password) return false;

      // Salva a sessão do usuário
      await DatabaseService.saveUserSession(user);
      return true;
    } catch (e) {
      print('[AuthService] Erro ao fazer login: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    await DatabaseService.clearUserSession();
  }

  static Future<User?> getCurrentUser() async {
    return DatabaseService.getCurrentUser();
  }
} 