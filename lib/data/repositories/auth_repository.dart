import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/session_manager.dart';
import '../models/user_model.dart';
import 'profile_repository.dart';

/// REST API autentikasi (tugas 1.1 & 1.2).
class AuthRepository {
  final ApiClient _client = ApiClient.instance;
  final ProfileRepository _profileRepository = ProfileRepository();

  /// POST /api/register  body: {name, email, password}
  /// Response: {message, data: {token, user: {...}}}
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(ApiConstants.register, data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return _saveSession(response);
  }

  /// POST /api/login  body: {email, password}
  Future<UserModel> login({required String email, required String password}) async {
    final response = await _client.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });
    return _saveSession(response);
  }

  /// Bonus 5.1 - Logout: hapus token lokal.
  Future<void> logout() => SessionManager.clearSession();

  /// Menyimpan token ke SharedPreferences dari response `{data: {token, user}}`.
  Future<UserModel> _saveSession(Map<String, dynamic> response) async {
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'] as Map)
        : response;

    final token = (data['token'] ?? response['token'])?.toString();
    if (token == null || token.isEmpty) {
      throw ApiException('Token tidak ditemukan pada response server.');
    }
    await SessionManager.saveToken(token);

    // Jika response tidak menyertakan objek user, ambil dari GET /profile
    // (token sudah tersimpan sehingga interceptor otomatis memakainya).
    final UserModel user = data['user'] is Map
        ? UserModel.fromJson(Map<String, dynamic>.from(data['user'] as Map))
        : await _profileRepository.getProfile();

    await SessionManager.saveUserBasic(name: user.name, email: user.email);
    return user;
  }
}
