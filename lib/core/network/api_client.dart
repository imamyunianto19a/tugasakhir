import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../utils/session_manager.dart';

/// Exception khusus supaya UI bisa menampilkan pesan error API dengan rapi.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Client HTTP tunggal (singleton) yang dipakai oleh seluruh repository.
///
/// - Menambahkan header `Authorization: Bearer <token>` otomatis jika
///   token sudah tersimpan di SharedPreferences (lihat [SessionManager]).
/// - Menormalkan error Dio menjadi [ApiException] dengan pesan yang
///   ramah agar mudah ditampilkan lewat SnackBar/Toast.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SessionManager.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    try {
      final res = await _dio.post(path, data: data);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data}) async {
    try {
      final res = await _dio.put(path, data: data);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await _dio.delete(path);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    // Beberapa API mengembalikan body kosong / string pada aksi tertentu
    // (mis. DELETE). Bungkus supaya tetap aman diakses sebagai Map.
    return {'raw': data};
  }

  /// Mengambil pesan error dari response API.
  ///
  /// Format error dari API:
  ///  - `{"message": "Email atau password salah", "data": null}`
  ///  - `{"message": "...", "errors": {"email": ["Email sudah terdaftar."]}}`
  /// Untuk error validasi, pesan pertama pada `errors` lebih spesifik.
  String? _extractMessage(dynamic data) {
    if (data is! Map) return null;

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first != null) return first.toString();
    }
    final message = data['message'];
    return message?.toString();
  }

  ApiException _handleError(DioException e) {
    final msg = _extractMessage(e.response?.data);
    if (msg != null && msg.isNotEmpty) return ApiException(msg);

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Koneksi ke server timeout. Coba lagi.');
      case DioExceptionType.connectionError:
        return ApiException('Tidak dapat terhubung ke server. Periksa internet Anda.');
      default:
        return ApiException(e.response?.statusMessage ?? 'Terjadi kesalahan pada server.');
    }
  }
}
