class UserData {
  UserData({required this.email, required this.password});

  final String email;
  final String password;
  List<String> favorites = [''];

  Map<String, Object?> toMap() {
    return {'email': email, 'password': password, 'favorites': favorites};
  }
}
