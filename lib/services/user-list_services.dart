import 'dart:async';
import 'dart:convert';

import 'package:chat_app/model/user_list_model.dart';
import 'package:http/http.dart' as http;

// https://chat-app-95gd.onrender.com
class UserListServices {
  final String baseUrl = "https://chat-app-95gd.onrender.com";

  Future<List<UserListModel>> getUserList() async {
    print('getUserList');
    final response = await http.get(Uri.parse('$baseUrl/users'));
    print('url hit hua');
    try {
      if (response.statusCode == 200) {
        print(response.body);
        final List<dynamic> data = jsonDecode(response.body);
        print(data);
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
