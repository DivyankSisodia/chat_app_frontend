
import 'package:chat_app/controller/user-list_controller.dart';
import 'package:chat_app/screen/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/socket_services.dart';
import '../model/user_list_model.dart';
import 'individual_chat_screen.dart';

// New provider for real-time user status
final userStatusProvider =
    StateNotifierProvider<UserStatusNotifier, Map<String, bool>>((ref) {
  return UserStatusNotifier();
});

class UserStatusNotifier extends StateNotifier<Map<String, bool>> {
  UserStatusNotifier() : super({});

  void updateUserStatus(String userId, bool isOnline) {
    state = {...state, userId: isOnline};
  }

  void setInitialStatus(List<UserListModel> users) {
    state = {for (var user in users) user.id: user.online_status};
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  final String username;
  final String email;
  final String id;
  final bool onlineStatus;
  final Mixpanel? mixpanel;

  const HomeScreen({
    super.key,
    this.mixpanel,
    required this.username,
    required this.email,
    required this.id,
    required this.onlineStatus,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  SharedPreferences? prefs;
  late SocketService socketService;
  late Mixpanel mixpanel;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
    _initializeSocket();
    _initializeMixpanel();
    _trackHomeScreenOpen();
  }

  Future<void> _initializeMixpanel() async {
    mixpanel = await Mixpanel.init("a1c4517778e7758fc30c37f30a6279d2",
        trackAutomaticEvents: true);
  }

  Future<void> _trackHomeScreenOpen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int homeScreenOpens = prefs.getInt('homeScreenOpens') ?? 0;
    homeScreenOpens++;
    await prefs.setInt('homeScreenOpens', homeScreenOpens);

    // Track with Mixpanel
    mixpanel.track("Home Screen Opened", properties: {
      "open_count": homeScreenOpens,
    });

    print("Home screen opened $homeScreenOpens times");
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  void _initializeSocket() {
    socketService = SocketService();
    socketService.on('connect', (_) {
      print('Socket connected');
      socketService.emit('user_connected', {
        'userId': widget.id,
        'username': widget.username,
      });
    });

    socketService.on('user_status_change', (data) {
      print('User status changed: $data');
      ref.read(userStatusProvider.notifier).updateUserStatus(
            data['userId'],
            data['online_status'],
          );
    });

    socketService.on('initial_user_list', (data) {
      final users =
          (data as List).map((e) => UserListModel.fromJson(e)).toList();
      ref.read(userStatusProvider.notifier).setInitialStatus(users);
    });
  }

  void _logout() async {
    print('Logout');
    if (prefs != null) {
      await prefs!.clear();
    }
    socketService.disconnect();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => SignupScreen()));
    print('Logout successful');
  }

  @override
  Widget build(BuildContext context) {
    widget.mixpanel?.track('HomeScreen');
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${widget.username}, ${widget.onlineStatus}'),
        elevation: 5,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            
            const Text(
              'Welcome to the chat app',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Gap(100),
            SizedBox(
              height: 400,
              width: 500,
              child: Consumer(builder: (context, ref, child) {
                final userListAsync = ref.watch(userListProvider);
                final userStatus = ref.watch(userStatusProvider);

                return userListAsync.when(
                  data: (userList) {
                    final filteredUsers = userList
                        .where((user) => user.username != widget.username)
                        .toList();
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isOnline =
                            userStatus[user.id] ?? user.online_status;
                        return ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  senderId: widget.id,
                                  receiverId: user.id,
                                  username: user.username,
                                  onlineStatus: isOnline,
                                ),
                              ),
                            );
                          },
                          title: Text(user.username),
                          subtitle: Text(user.email),
                          leading: isOnline
                              ? const Icon(Icons.circle, color: Colors.green)
                              : const Icon(Icons.circle, color: Colors.red),
                        );
                      },
                    );
                  },
                  loading: () => SizedBox(
                      height: 100, child: const CircularProgressIndicator()),
                  error: (error, stack) => Text('Error: $error'),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
