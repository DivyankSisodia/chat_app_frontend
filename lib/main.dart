import 'package:chat_app/screen/login.dart';
import 'package:chat_app/screen/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'screen/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fetch SharedPreferences and determine if the user is logged in
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  String? username = prefs.getString('username'); // Assuming you store username
  String? email = prefs.getString('email');       // Assuming you store email
  String? id = prefs.getString('id');             // Assuming you store id

  runApp(ProviderScope(
    child: MyApp(
      isLoggedIn: token != null && token.isNotEmpty,
      username: username,
      email: email,
      id: id,
    ),
  ));
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("32a897f3-b76a-4ab3-8b7f-4d940f34605c");
  OneSignal.Notifications.requestPermission(true);
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? username;
  final String? email;
  final String? id;

  const MyApp({super.key, required this.isLoggedIn, this.username, this.email, this.id});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: isLoggedIn
          ? HomeScreen(username: username ?? '', email: email ?? '', id: id ?? '', onlineStatus: true)
          : SignupScreen(),
    );
  }
}
