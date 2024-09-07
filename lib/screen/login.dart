import 'package:chat_app/screen/home_screen.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../model/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late Mixpanel mixpanel;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  SharedPreferences? prefs; // Initialize as nullable

  @override
  void initState() {
    super.initState();
    _initializePrefs();
    _initializeMixpanel(); // Initialize Mixpanel here
  }

  Future<void> _initializeMixpanel() async {
    // Replace with your Mixpanel project token
    mixpanel = await Mixpanel.init('a1c4517778e7758fc30c37f30a6279d2',
        trackAutomaticEvents: false);
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance(); // Await the instance
  }

  late IO.Socket socket;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Initialize Firebase Messaging
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request notification permissions
      NotificationSettings settings = await messaging.requestPermission();

      // Check if the user has granted permission for notifications
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else {
        print('User declined or has not accepted permission');
        // You might want to handle this case, e.g., show a dialog to the user
        return; // Exit the function if permission is not granted
      }

      // Get the device token for push notifications
      String? deviceToken = await messaging.getToken();

      if (deviceToken == null) {
        print('Failed to get device token');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get device token')),
        );
        return; // Exit the function if no device token is available
      }

      print('Device Token: $deviceToken');

      // Create a User object with the retrieved device token
      User user = User(
        email: emailController.text,
        password: passwordController.text,
        deviceToken: deviceToken,
      );

      print('User after printing device token: ${user.toJsonLogin()}');

      try {
        // Attempt to log in using the AuthService
        final response = await _authService.login(user);
        print("Response in login screen: $response");

        if (kDebugMode) {
          print('Login successful in try block: ${response['token']}');
        }

        // Extract user data from the response
        String username = response['user']['username'] ?? "Unknown";
        String email = response['user']['email'] ?? "Unknown";
        String id = response['user']['id'];
        bool onlineStatus = response['user']['online_status'];

        print('Username: $username');
        print('Email: $email');
        print('ID: $id');
        print('Online Status: $onlineStatus');

        // Store user data and token in SharedPreferences
        if (prefs != null) {
          await prefs!.setString('token', response['token']);
          await prefs!.setString('id', id);
          await prefs!.setString('email', email);
          await prefs!.setString('username', username);
        }

        // Track user login with Mixpanel
        mixpanel.identify(id);
        mixpanel.getPeople().set("\$name", username);
        mixpanel.getPeople().set("\$email", email);
        mixpanel
            .getPeople()
            .set("Last Login Date", DateTime.now().toIso8601String());

        // Track the login event
        mixpanel.track("User Login", properties: {
          "Username": username,
          "Email": email,
        });
        print('User login tracked with Mixpanel');

        // Navigate to HomeScreen and pass the user data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              username: username,
              email: email,
              id: id,
              onlineStatus: onlineStatus,
            ),
          ),
        );
      } catch (e) {
        // Handle login errors
        print('Login failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
