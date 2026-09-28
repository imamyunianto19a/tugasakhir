import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/date_utils.dart';
import '../models/absen_model.dart';

/// REST API absensi (tugas 2, 3, dan bonus 5.2).
class AbsenRepository {
  final ApiClient _client = ApiClient.instance;

  /// POST /api/absen/check-in
  /// body masuk: {check_in_lat, check_in_lng, check_in_address, status: "masuk"}
  /// body izin : {..., status: "izin", alasan_izin: "..."}
  Future<AbsenResult> checkIn({
    required double latitude,
    required double longitude,
    required String address,
    String status = AbsenModel.statusMasuk,
    String? alasanIzin,
  }) async {
    final response = await _client.post(ApiConstants.absenCheckIn, data: {
      'check_in_lat': latitude.toString(),
      'check_in_lng': longitude.toString(),
      'check_in_address': address,
      'status': status,
      if (status == AbsenModel.statusIzin) 'alasan_izin': alasanIzin,
    });
    return _toResult(response);
  }

  /// POST /api/absen/check-out
  /// body: {check_out_lat, check_out_lng, check_out_location, check_out_address}
  Future<AbsenResult> checkOut({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await _client.post(ApiConstants.absenCheckOut, data: {
      'check_out_lat': latitude.toString(),
      'check_out_lng': longitude.toString(),
      'check_out_location': '$latitude, $longitude',
      'check_out_address': address,
    });
    return _toResult(response);
  }

  /// GET /api/absen/history?start=yyyy-MM-dd&end=yyyy-MM-dd  (keduanya opsional)
  Future<List<AbsenModel>> getHistory({DateTime? start, DateTime? end}) async {
    final response = await _client.get(
      ApiConstants.absenHistory,
      query: {
        if (start != null) 'start': toApiDate(start),
        if (end != null) 'end': toApiDate(end),
      },
    );
    final list = response['data'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => AbsenModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Statistik & absen hari ini (2.5): dihitung dari riwayat bulan berjalan.
  Future<AbsenStatistik> getStatistik() async {
    final now = DateTime.now();
    final history = await getHistory(start: DateTime(now.year, now.month, 1));
    return AbsenStatistik.fromHistory(history);
  }

  /// DELETE /api/absen/{id}  (Bonus 5.2)
  Future<String> deleteAbsen(int id) async {
    final response = await _client.delete(ApiConstants.absenDelete(id));
    return (response['message'] ?? 'Data absen berhasil dihapus').toString();
  }

  AbsenResult _toResult(Map<String, dynamic> response) {
    final data = response['data'];
    return AbsenResult(
      message: (response['message'] ?? '').toString(),
      data: data is Map ? AbsenModel.fromJson(Map<String, dynamic>.from(data)) : null,
    );
  }
}
