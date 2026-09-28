import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

/// REST API profil (tugas 4) dan data seluruh pengguna.
class ProfileRepository {
  final ApiClient _client = ApiClient.instance;

  /// GET /api/profile  -> {message, data: {id, name, email, ...}}
  Future<UserModel> getProfile() async {
    final response = await _client.get(ApiConstants.profile);
    return UserModel.fromJson(_unwrapMap(response));
  }

  /// PUT /api/profile  body: {name}
  Future<UserModel> editProfile({required String name}) async {
    final response = await _client.put(ApiConstants.profile, data: {'name': name});
    return UserModel.fromJson(_unwrapMap(response));
  }

  /// GET /api/users  -> {message, data: [ {...}, {...} ]}
  Future<List<UserModel>> getAllUsers() async {
    final response = await _client.get(ApiConstants.users);
    final list = response['data'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, dynamic> _unwrapMap(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }
}
