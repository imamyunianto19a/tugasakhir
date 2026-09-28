import '../../core/utils/date_utils.dart';

/// Satu record absensi. Field mengikuti response API `/absen/*`:
/// `id, user_id, check_in, check_in_location, check_in_address, check_out,
/// check_out_location, check_out_address, status, alasan_izin, check_in_lat,
/// check_in_lng, check_out_lat, check_out_lng`.
class AbsenModel {
  static const String statusMasuk = 'masuk';
  static const String statusIzin = 'izin';

  final int id;
  final int? userId;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? checkInAddress;
  final String? checkOutAddress;
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final String status;
  final String? alasanIzin;

  AbsenModel({
    required this.id,
    this.userId,
    this.checkIn,
    this.checkOut,
    this.checkInAddress,
    this.checkOutAddress,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    required this.status,
    this.alasanIzin,
  });

  bool get isIzin => status == statusIzin;
  bool get hasCheckedOut => checkOut != null;
  DateTime? get tanggal => checkIn;
  bool get hasCheckInLocation => checkInLat != null && checkInLng != null;
  bool get hasCheckOutLocation => hasCheckedOut && checkOutLat != null && checkOutLng != null;

  factory AbsenModel.fromJson(Map<String, dynamic> json) {
    // Endpoint history tidak mengirim *_lat / *_lng, hanya string
    // "check_in_location": "-6.2, 106.8" -> dipakai sebagai cadangan.
    final inLoc = _parseLatLng(json['check_in_location']);
    final outLoc = _parseLatLng(json['check_out_location']);

    return AbsenModel(
      id: _toInt(json['id']) ?? 0,
      userId: _toInt(json['user_id']),
      checkIn: parseServerDate(json['check_in']),
      checkOut: parseServerDate(json['check_out']),
      checkInAddress: json['check_in_address']?.toString(),
      checkOutAddress: json['check_out_address']?.toString(),
      checkInLat: _toDouble(json['check_in_lat']) ?? inLoc?[0],
      checkInLng: _toDouble(json['check_in_lng']) ?? inLoc?[1],
      checkOutLat: _toDouble(json['check_out_lat']) ?? outLoc?[0],
      checkOutLng: _toDouble(json['check_out_lng']) ?? outLoc?[1],
      status: (json['status'] ?? statusMasuk).toString(),
      alasanIzin: json['alasan_izin']?.toString(),
    );
  }

  static int? _toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// "-6.2, 106.8" -> [-6.2, 106.8]
  static List<double>? _parseLatLng(dynamic v) {
    if (v == null) return null;
    final parts = v.toString().split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return [lat, lng];
  }
}

/// Hasil aksi absen (check-in / check-out): pesan dari server + data absen.
///
/// Pesan perlu ditampilkan apa adanya karena server bisa membalas 200 untuk
/// kasus khusus, mis. "Status izin tidak memerlukan absen keluar".
class AbsenResult {
  final String message;
  final AbsenModel? data;

  AbsenResult({required this.message, this.data});
}

/// Ringkasan untuk Dashboard (2.5), dihitung dari data `/absen/history`
/// karena API tidak menyediakan endpoint statistik khusus.
class AbsenStatistik {
  final int totalMasuk;
  final int totalIzin;
  final AbsenModel? hariIni;

  AbsenStatistik({this.totalMasuk = 0, this.totalIzin = 0, this.hariIni});

  int get totalAbsen => totalMasuk + totalIzin;
  bool get sudahAbsenMasuk => hariIni != null && !hariIni!.isIzin;
  bool get sudahIzin => hariIni != null && hariIni!.isIzin;
  bool get sudahAbsenPulang => hariIni?.hasCheckedOut ?? false;

  factory AbsenStatistik.fromHistory(List<AbsenModel> history) {
    final now = DateTime.now();
    AbsenModel? today;
    for (final e in history) {
      if (isSameDay(e.checkIn, now)) {
        today = e;
        break;
      }
    }
    return AbsenStatistik(
      totalMasuk: history.where((e) => !e.isIzin).length,
      totalIzin: history.where((e) => e.isIzin).length,
      hariIni: today,
    );
  }
}
