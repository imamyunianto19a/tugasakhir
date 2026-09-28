import '../../core/utils/date_utils.dart';

/// Model pengguna. Bentuknya mengikuti objek user pada response API:
/// `{id, name, email, email_verified_at, created_at, updated_at}`.
class UserModel {
  final int? id;
  final String name;
  final String email;
  final DateTime? createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.createdAt,
  });

  /// [json] adalah objek user itu sendiri (bukan pembungkus `data`).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse((json['id'] ?? '').toString()),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      createdAt: parseServerDate(json['created_at']),
    );
  }
}
