import 'database_service.dart';
import '../models/user.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userIdKey = 'userId';
  static const String _userEmailKey = 'userEmail';

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

  static Future<mongo.ObjectId?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString(_userIdKey);
    if (userIdStr == null) return null;
    return mongo.ObjectId.parse(userIdStr);
  }

  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<void> saveUserSession(mongo.ObjectId userId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId.toHexString());
    await prefs.setString(_userEmailKey, email);
  }

  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
  }
} 