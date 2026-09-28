/// Kumpulan konstanta REST API.
///
/// Disesuaikan dengan Postman Collection "ABSENSI PPKD B1":
/// `{{base_url}}` = https://absensib1.mobileprojp.com dan seluruh
/// endpoint berada di bawah prefix `/api`.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://absensib1.mobileprojp.com/api';

  // Autentikasi
  static const String register = '/register'; // POST
  static const String login = '/login'; // POST

  // Absensi
  static const String absenCheckIn = '/absen/check-in'; // POST
  static const String absenCheckOut = '/absen/check-out'; // POST
  static const String absenHistory = '/absen/history'; // GET ?start=&end=
  static String absenDelete(int id) => '/absen/$id'; // DELETE

  // Profil
  static const String profile = '/profile'; // GET & PUT

  // Data seluruh pengguna
  static const String users = '/users'; // GET
}
