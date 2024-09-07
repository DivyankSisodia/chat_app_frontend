import 'package:chat_app/model/user_model.dart';
import 'package:chat_app/screen/login.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _email = '';
  String _password = '';

  final AuthService _authService = AuthService();

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission();

      if(settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else {
        print('User declined or has not accepted permission');
      }

      String? deviceToken = await messaging.getToken();

      User user = User(username: _username, email: _email, password: _password, deviceToken: deviceToken!);

      try {
        final response = await _authService.signup(user);
        if (kDebugMode) {
          print('Signup successful: ${response['token']}');
        }
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => LoginScreen()));
      } catch (e) {
        print('Signup failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signup')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Username'),
                onSaved: (value) => _username = value!,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (value) => _email = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (value) => _password = value!,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signup,
                child: const Text('Signup'),
              ),
              const Gap(50),
              TextButton(onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              }, child: Text('Already have an account? Login'))
            ],
          ),
        ),
      ),
    );
  }
}
