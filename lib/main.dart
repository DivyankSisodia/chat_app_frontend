import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'screen/home_screen.dart';
import 'screen/signup.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: null);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
    const AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService().init(); // Initialize notification service

  FirebaseOptions androidOptions = const FirebaseOptions(
    apiKey: 'AIzaSyCdnb7LqWTmHgQNj7BXzjAucDj5dmg-NT0',
    appId: '1:798450357422:android:464ceb113a657f179b893f',
    messagingSenderId: '798450357422',
    projectId: 'testing-32a29',
  );

  FirebaseOptions iosOptions = const FirebaseOptions(
    apiKey: 'AIzaSyDeKaHqhaowA2nGXJgkJoqul5QJXtXSo7w',
    appId: '1:798450357422:ios:acce26b0bddea0859b893f',
    messagingSenderId: '798450357422',
    projectId: 'testing-32a29',
  );

  Mixpanel mixpanel = await Mixpanel.init('a1c4517778e7758fc30c37f30a6279d2',
      trackAutomaticEvents: true);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String? username = prefs.getString('username');
  String? email = prefs.getString('email');
  String? id = prefs.getString('id');

  try {
    if (Platform.isAndroid) {
      await Firebase.initializeApp(options: androidOptions);
    } else if (Platform.isIOS) {
      await Firebase.initializeApp(options: iosOptions);
    }
    runApp(
      ProviderScope(
        child: MyApp(
          mixpanel: mixpanel,
          isLoggedIn: token != null && token.isNotEmpty,
          username: username,
          email: email,
          id: id,
        ),
      ),
    );
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final String? username;
  final String? email;
  final String? id;
  final Mixpanel mixpanel;

  const MyApp({
    super.key,
    required this.mixpanel,
    required this.isLoggedIn,
    this.username,
    this.email,
    this.id,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message while in the foreground: ${message.notification}');
      if (message.notification != null) {
        _notificationService.showNotification(
          message.notification!.title ?? 'New Message',
          message.notification!.body ?? '',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
      // Handle navigation here if needed
    });

    // Get the token each time the application loads
    String? token = await messaging.getToken();
    print("FCM Token: $token");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: widget.isLoggedIn
          ? HomeScreen(
          mixpanel: widget.mixpanel,
          username: widget.username ?? '',
          email: widget.email ?? '',
          id: widget.id ?? '',
          onlineStatus: true)
          : SignupScreen(),
    );
  }
}