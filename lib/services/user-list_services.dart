import 'dart:async';
import 'dart:convert';

import 'package:chat_app/model/user_list_model.dart';
import 'package:http/http.dart' as http;

// https://chat-app-95gd.onrender.com
class UserListServices {
  final String baseUrl = "http://192.168.1.10:3000";
  // final String baseUrl = "https://chat-app-95gd.onrender.com";

  Future<List<UserListModel>> getUserList() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    try {
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => UserListModel.fromJson(e)).toList();
      } else {
        print('Failed to load user list. Status code: ${response.statusCode}');
        throw Exception('Failed to load user list');
      }
    } catch (e) {
      print(e);
    }
    return [];
  }
}
