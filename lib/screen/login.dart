import 'package:chat_app/screen/home_screen.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../model/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  AuthService _authService = AuthService();
  SharedPreferences? prefs; // Initialize as nullable

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance(); // Await the instance
  }

  late IO.Socket socket;

  void _login() async {
    
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      User user = User(email: emailController.text, password: passwordController.text);

      try {
        final response = await _authService.login(user);
        print("printing res in loginscreen $response");
        if (kDebugMode) {
          print('Login successful in try block: ${response['token']}');
        }

        // Check for null values before storing them or using them
        String username = response['user']['username'] ?? "Unknown";  // Provide a default value if null
        String email = response['user']['email'] ?? "Unknown";
        String id = response['user']['id'];
        bool online_status = response['user']['online_status'];

        print('Username: $username');
        print('Email: $email');
        print('ID: $id');
        print('Online Status: $online_status');

        // Ensure prefs is initialized
        if (prefs != null) {
          await prefs!.setString('token', response['token']);
          await prefs!.setString('id', id);
          await prefs!.setString('email', email);
          await prefs!.setString('username', username);
        }

        print(id);

        // Navigate to HomeScreen and pass the data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              username: username,
              email: email,
              id: id,
              onlineStatus: online_status,
            ),
          ),
        );
      } catch (e) {
        print('Login failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          height: 500,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const Gap(10),
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
