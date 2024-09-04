class UserListModel{
  final String id;
  final String username;
  final String email;
  final bool online_status;

  UserListModel({
    required this.id,
    required this.username,
    required this.email,
    required this.online_status
  });

  factory UserListModel.fromJson(Map<String, dynamic> json){
    return UserListModel(
      id: json['_id'],
      username: json['username'],
      email: json['email'],
      online_status: json['online_status']
    );
  }
}