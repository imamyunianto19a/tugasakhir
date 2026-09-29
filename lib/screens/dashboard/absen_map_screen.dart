import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/models/absen_model.dart';
import '../../providers/absen_provider.dart';

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
        markers.add(
          Marker(
            markerId: const MarkerId('check_in'),
            position: checkInPos,
            icon: absen.isIzin
                ? BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  )
                : BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: absen.isIzin ? 'Lokasi Izin' : 'Check-in',
              snippet: absen.isIzin && (absen.alasanIzin ?? '').isNotEmpty
                  ? 'Alasan: ${absen.alasanIzin}'
                  : absen.checkInAddress,
            ),
          ),
        );
      }
      if (absen.hasCheckOutLocation) {
        markers.add(
          Marker(
            markerId: const MarkerId('check_out'),
            position: LatLng(absen.checkOutLat!, absen.checkOutLng!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: 'Check-out',
              snippet: absen.checkOutAddress,
            ),
          ),
        );
      }
      target = checkInPos ?? _fallback;
      info = (absen.isIzin && (absen.alasanIzin ?? '').isNotEmpty)
          ? 'Izin: ${absen.alasanIzin}\n${absen.checkInAddress ?? ''}'
          : (absen.checkInAddress ?? 'Lokasi absen');
    } else {
      final position = provider.currentPosition;
      target = position != null
          ? LatLng(position.latitude, position.longitude)
          : _fallback;
      info = provider.currentAddress ??
          'Lat: ${target.latitude}, Lng: ${target.longitude}';
      markers.add(
        Marker(
          markerId: const MarkerId('lokasi_saya'),
          position: target,
          infoWindow: InfoWindow(title: 'Lokasi Anda', snippet: info),
        ),
      );
    }

    final String appBarTitle = absen != null
        ? (absen.isIzin ? 'Detail Lokasi Izin' : 'Detail Lokasi Absen')
        : 'Lokasi Saya';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: target,
                    zoom: 17,
                  ),
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
