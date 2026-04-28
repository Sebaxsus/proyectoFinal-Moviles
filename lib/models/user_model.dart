class UserModel {

  final String username;
  final String? token;

  const UserModel({
    required this.username,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {

    return UserModel(
      username: json['username'] as String,
      token: json['token'] as String?,
    );

  }

  Map<String, dynamic> toJson() => {
    'username': username,
    if (token != null) 'token': token,
  };

  @override
  String toString() => 'UserModel(username: $username)';
  
}