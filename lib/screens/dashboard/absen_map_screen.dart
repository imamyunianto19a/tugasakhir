import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/models/absen_model.dart';
import '../../providers/absen_provider.dart';

/// 2.4 - Menampilkan Google Map untuk lokasi absen.
///
/// - Tanpa [absen]: menampilkan posisi perangkat saat ini.
/// - Dengan [absen] (dibuka dari detail riwayat): menampilkan titik
///   check-in dan check-out dari data server.
///
/// PENTING: agar Google Maps tampil, tambahkan API key di:
/// - Android: android/app/src/main/AndroidManifest.xml
///     <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_KEY"/>
/// - iOS: ios/Runner/AppDelegate.swift -> GMSServices.provideAPIKey("YOUR_KEY")
class AbsenMapScreen extends StatefulWidget {
  final AbsenModel? absen;
  const AbsenMapScreen({super.key, this.absen});

  @override
  State<AbsenMapScreen> createState() => _AbsenMapScreenState();
}

class _AbsenMapScreenState extends State<AbsenMapScreen> {
  static const LatLng _fallback = LatLng(-6.200000, 106.816666); // Jakarta
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Lokasi perangkat hanya dibutuhkan jika tidak membuka detail absen.
    if (widget.absen == null) {
      final provider = context.read<AbsenProvider>();
      try {
        if (provider.currentPosition == null) {
          await provider.getCurrentLocation();
        }
      } catch (_) {
        // Tampilkan peta dengan posisi default bila lokasi gagal diambil.
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final absen = widget.absen;
    final provider = context.watch<AbsenProvider>();

    final Set<Marker> markers = {};
    LatLng target;
    String info;

    if (absen != null) {
      LatLng? checkInPos;
      if (absen.hasCheckInLocation) {
        checkInPos = LatLng(absen.checkInLat!, absen.checkInLng!);
        markers.add(Marker(
          markerId: const MarkerId('check_in'),
          position: checkInPos,
          infoWindow: InfoWindow(title: 'Check-in', snippet: absen.checkInAddress),
        ));
      }
      if (absen.hasCheckOutLocation) {
        markers.add(Marker(
          markerId: const MarkerId('check_out'),
          position: LatLng(absen.checkOutLat!, absen.checkOutLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: 'Check-out', snippet: absen.checkOutAddress),
        ));
      }
      target = checkInPos ?? _fallback;
      info = absen.checkInAddress ?? 'Lokasi absen';
    } else {
      final position = provider.currentPosition;
      target = position != null ? LatLng(position.latitude, position.longitude) : _fallback;
      info = provider.currentAddress ?? 'Lat: ${target.latitude}, Lng: ${target.longitude}';
      markers.add(Marker(
        markerId: const MarkerId('lokasi_saya'),
        position: target,
        infoWindow: InfoWindow(title: 'Lokasi Anda', snippet: info),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: Text(absen != null ? 'Detail Lokasi Absen' : 'Lokasi Saya')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: target, zoom: 17),
                  markers: markers,
                  myLocationEnabled: absen == null,
                  myLocationButtonEnabled: absen == null,
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(info),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
