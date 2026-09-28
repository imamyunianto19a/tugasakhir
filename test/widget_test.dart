import 'package:flutter_test/flutter_test.dart';
import 'package:tugasakhir/data/models/absen_model.dart';

void main() {
  test('AbsenModel membaca response /absen/history dari API', () {
    final absen = AbsenModel.fromJson({
      'id': 1,
      'user_id': 1,
      'check_in': '2025-04-10 07:54:40',
      'check_in_location': '-6.2, 106.8',
      'check_in_address': 'Jakarta',
      'check_out': '2025-04-10 07:56:51',
      'check_out_location': '-6.2, 106.8',
      'check_out_address': 'Jakarta',
      'status': 'masuk',
      'alasan_izin': null,
    });

    expect(absen.id, 1);
    expect(absen.isIzin, false);
    expect(absen.hasCheckedOut, true);
    expect(absen.checkInLat, -6.2);
    expect(absen.checkInLng, 106.8);
  });
}
