import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chat_app/model/chat_model.dart';

class ApiService {
  final String baseUrl = 'https://chat-app-95gd.onrender.com'; // Replace with your API base URL

  Future<List<Message>> fetchChatHistory(String senderId, String receiverId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/history/$senderId/$receiverId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      print(jsonData);
      return jsonData.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chat history');
    }
  }
}