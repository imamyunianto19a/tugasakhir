/// Helper parsing tanggal dari server.
///
/// API mengirim dua format:
///  - ISO 8601 dengan zona waktu, mis. `2025-04-11T02:25:40.875070Z`
///  - String tanpa zona waktu, mis. `2025-04-11 07:54:40` (nilainya UTC,
///    sama dengan `created_at` pada record yang sama)
/// Keduanya dikonversi ke waktu lokal perangkat.
DateTime? parseServerDate(dynamic value) {
  if (value == null) return null;
  var s = value.toString().trim();
  if (s.isEmpty) return null;

  final hasZone = s.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(s);
  if (!hasZone) {
    s = '${s.replaceFirst(' ', 'T')}Z';
  }
  return DateTime.tryParse(s)?.toLocal();
}

bool isSameDay(DateTime? a, DateTime b) =>
    a != null && a.year == b.year && a.month == b.month && a.day == b.day;

/// Format `yyyy-MM-dd` untuk query param `start` / `end`.
String toApiDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}
