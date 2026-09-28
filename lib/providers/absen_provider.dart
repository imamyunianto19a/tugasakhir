import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../core/network/api_client.dart';
import '../data/models/absen_model.dart';
import '../data/repositories/absen_repository.dart';

/// State management untuk Dashboard Absensi (bagian 2) dan Riwayat (bagian 3).
class AbsenProvider extends ChangeNotifier {
  final AbsenRepository _repository = AbsenRepository();

  bool isCheckingIn = false;
  bool isCheckingOut = false;

  /// Pesan terakhir dari server / error, untuk ditampilkan di toast.
  String? lastMessage;

  AbsenStatistik statistik = AbsenStatistik();
  bool isLoadingStatistik = false;

  List<AbsenModel> history = [];
  bool isLoadingHistory = false;

  Position? currentPosition;
  String? currentAddress;

  /// 2.3 - Mengambil latitude & longitude perangkat via Geolocator.
  Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw ApiException('Layanan lokasi (GPS) tidak aktif. Aktifkan GPS terlebih dahulu.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw ApiException('Izin lokasi ditolak.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw ApiException('Izin lokasi ditolak permanen. Aktifkan lewat pengaturan aplikasi.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    currentPosition = position;
    currentAddress = null;

    try {
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final text = [p.street, p.subLocality, p.locality, p.administrativeArea]
            .where((e) => e != null && e.isNotEmpty)
            .join(', ');
        currentAddress = text.isEmpty ? null : text;
      }
    } catch (_) {
      // Reverse-geocoding opsional; jika gagal pakai koordinat sebagai alamat.
    }

    notifyListeners();
    return position;
  }

  /// API mewajibkan alamat; jika reverse-geocoding gagal, pakai koordinat.
  String _addressOf(Position p) => currentAddress ?? '${p.latitude}, ${p.longitude}';

  /// 2.2 - Absen Masuk, atau Izin bila [status] == "izin" (wajib [alasanIzin]).
  Future<bool> checkIn({String status = AbsenModel.statusMasuk, String? alasanIzin}) async {
    isCheckingIn = true;
    lastMessage = null;
    notifyListeners();
    try {
      final position = await getCurrentLocation();
      final result = await _repository.checkIn(
        latitude: position.latitude,
        longitude: position.longitude,
        address: _addressOf(position),
        status: status,
        alasanIzin: alasanIzin,
      );
      lastMessage = result.message;
      await loadStatistik();
      return true;
    } on ApiException catch (e) {
      lastMessage = e.message;
      return false;
    } catch (e) {
      lastMessage = 'Absen masuk gagal: $e';
      return false;
    } finally {
      isCheckingIn = false;
      notifyListeners();
    }
  }

  /// 2.2 - Absen Pulang
  Future<bool> checkOut() async {
    isCheckingOut = true;
    lastMessage = null;
    notifyListeners();
    try {
      final position = await getCurrentLocation();
      final result = await _repository.checkOut(
        latitude: position.latitude,
        longitude: position.longitude,
        address: _addressOf(position),
      );
      lastMessage = result.message;
      await loadStatistik();
      return true;
    } on ApiException catch (e) {
      lastMessage = e.message;
      return false;
    } catch (e) {
      lastMessage = 'Absen pulang gagal: $e';
      return false;
    } finally {
      isCheckingOut = false;
      notifyListeners();
    }
  }

  /// 2.5 - Statistik bulan ini & absen hari ini.
  Future<void> loadStatistik() async {
    isLoadingStatistik = true;
    notifyListeners();
    try {
      statistik = await _repository.getStatistik();
    } catch (_) {
      // Biarkan statistik lama tampil bila request gagal.
    } finally {
      isLoadingStatistik = false;
      notifyListeners();
    }
  }

  /// 3.1 - Riwayat absensi, opsional difilter rentang tanggal.
  Future<void> loadHistory({DateTimeRange? range}) async {
    isLoadingHistory = true;
    notifyListeners();
    try {
      history = await _repository.getHistory(start: range?.start, end: range?.end);
    } on ApiException catch (e) {
      lastMessage = e.message;
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Bonus 5.2 - Hapus data absen (DELETE /absen/{id}).
  Future<bool> deleteAbsen(int id) async {
    try {
      lastMessage = await _repository.deleteAbsen(id);
      history.removeWhere((e) => e.id == id);
      notifyListeners();
      loadStatistik();
      return true;
    } on ApiException catch (e) {
      lastMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
