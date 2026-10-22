class User {
  final int id;
  final String email;
  final String username;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  String get initial =>
      username.isNotEmpty ? username[0].toUpperCase() : '?';
}
