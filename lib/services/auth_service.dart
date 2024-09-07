import 'dart:convert';
import 'package:chat_app/model/user_model.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // final String baseUrl = "https://chat-app-95gd.onrender.com";
  final String baseUrl = "http://192.168.1.4:3000";
  // Signup method
  Future<Map<String, dynamic>> signup(User user) async {
    print(user.toJsonSignup());
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJsonSignup()),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sign up. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Login method
  Future<Map<String, dynamic>> login(User user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJsonLogin()),
    );

    if (response.statusCode == 200) {
      print(response.body);
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login');
    }
  }
}
