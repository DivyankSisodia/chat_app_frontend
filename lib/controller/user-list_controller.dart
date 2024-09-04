import 'package:chat_app/services/user-list_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dataProvider = Provider<UserListServices>((ref) {
  return UserListServices();
});

final userListProvider = FutureProvider.autoDispose((ref) {
  final data = ref.watch(dataProvider);
  return data.getUserList();
});

