import 'package:http/http.dart';

class User {
  final String? username;
  final String email;
  final String password;
  final String deviceToken;

  const User({this.username, required this.email, required this.password, required this.deviceToken});

  Map<String, dynamic> toJsonSignup() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'device_token': deviceToken,
    };
  }

  Map<String, dynamic> toJsonLogin() {
    return {
      'email': email,
      'password': password,
      'device_token': deviceToken,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      email: json['email'],
      password: '',
      deviceToken: json['device_token'],
    );
  }
}
