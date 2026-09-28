import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/utils/session_manager.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus { idle, loading, success, error }

/// State management untuk Register, Login, dan Logout.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  AuthStatus status = AuthStatus.idle;
  String? errorMessage;
  UserModel? currentUser;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(
      () => _repository.register(name: name, email: email, password: password),
      fallbackError: 'Registrasi gagal',
    );
  }

  Future<bool> login({required String email, required String password}) {
    return _run(
      () => _repository.login(email: email, password: password),
      fallbackError: 'Login gagal',
    );
  }

  Future<bool> _run(Future<UserModel> Function() action, {required String fallbackError}) async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      currentUser = await action();
      status = AuthStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = '$fallbackError: $e';
    }
    status = AuthStatus.error;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _repository.logout();
    currentUser = null;
    status = AuthStatus.idle;
    notifyListeners();
  }

  Future<bool> checkSession() => SessionManager.isLoggedIn();
}
