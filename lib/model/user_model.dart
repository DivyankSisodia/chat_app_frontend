class User{
  final String? username;
  final String email;
  final String password;

  const User({
    this.username,
    required this.email,
    required this.password
  });

  Map<String, dynamic> toJsonSignup(){
    return {
      'username': username,
      'email': email,
      'password': password,
    };
  }

  Map<String, dynamic> toJsonLogin(){
    return {
      'email': email,
      'password': password,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      email: json['email'],
      password: '',
    );
  }
}