import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Para Flutter Web no Chrome (usando a mesma porta do servidor Node)
  static const String _baseUrl = 'http://127.0.0.1:3000/api';
  // Verifica se o servidor está respondendo
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Registro de usuário
  static Future<Map<String, dynamic>> registerUser(
      String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*' // Ou 'http://localhost:55736'
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      print(
          'Status da resposta: ${response.statusCode}'); // Log para o status da resposta
      print(
          'Resposta do servidor: ${response.body}'); // Log do corpo da resposta

      // Verifique se o corpo da resposta não está vazio
      if (response.body.isEmpty) {
        throw Exception('Resposta vazia do servidor');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'],
          'userId': responseData['userId']
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Unknown error occurred'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
