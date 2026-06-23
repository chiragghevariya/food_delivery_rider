import '../utils/json_utils.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
  });

  bool get isRider => role == 'rider';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: toInt(json['id']),
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'],
        role: json['role'] ?? '',
      );
}
