import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/utils/session_manager.dart';
import '../data/models/user_model.dart';
import '../data/repositories/profile_repository.dart';

/// State management untuk Profil (bagian 4) dan daftar seluruh pengguna.
class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository = ProfileRepository();

  UserModel? user;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  List<UserModel> users = [];
  bool isLoadingUsers = false;

  Future<void> loadProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      user = await _repository.getProfile();
      await SessionManager.saveUserBasic(name: user!.name, email: user!.email);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// PUT /api/profile — API hanya menerima perubahan `name`.
  Future<bool> updateProfile({required String name}) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      user = await _repository.editProfile(name: name);
      await SessionManager.saveUserBasic(name: user!.name, email: user!.email);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// GET /api/users
  Future<void> loadUsers() async {
    isLoadingUsers = true;
    errorMessage = null;
    notifyListeners();
    try {
      users = await _repository.getAllUsers();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoadingUsers = false;
      notifyListeners();
    }
  }
}
