import 'package:flutter/material.dart';
import '../../core/utils/toast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/absen_model.dart';
import '../../providers/absen_provider.dart';
import '../dashboard/absen_map_screen.dart';

/// Bagian 3 - Riwayat Absensi: GET /api/absen/history, tampilkan tanggal,
/// jam masuk/keluar, dan lokasi. Filter rentang tanggal lewat query
/// `start` & `end`. Bonus 5.2: hapus data absen.
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() => context.read<AbsenProvider>().loadHistory(range: _range);

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (picked == null || !mounted) return;
    setState(() => _range = picked);
    _load();
  }

  void _clearRange() {
    setState(() => _range = null);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AbsenProvider>();
    final fmt = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter tanggal',
            onPressed: _pickRange,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_range != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text('${fmt.format(_range!.start)} - ${fmt.format(_range!.end)}'),
                  onDeleted: _clearRange,
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: provider.isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : provider.history.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Center(child: Text('Belum ada riwayat absensi')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.history.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = provider.history[index];
                            return _RiwayatCard(
                              item: item,
                              onTap: item.hasCheckInLocation
                                  ? () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => AbsenMapScreen(absen: item)),
                                      )
                                  : null,
                              onDelete: () => _confirmDelete(context, item),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AbsenModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Absen'),
        content: const Text('Yakin ingin menghapus data absen ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<AbsenProvider>();
              final success = await provider.deleteAbsen(item.id);
              showToast(provider.lastMessage ?? (success ? 'Data absen dihapus' : 'Gagal menghapus data'),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _RiwayatCard extends StatelessWidget {
  final AbsenModel item;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  const _RiwayatCard({required this.item, required this.onTap, required this.onDelete});

  String _time(DateTime? d) => d == null ? '-' : DateFormat('HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    final tanggal = item.tanggal != null
        ? DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(item.tanggal!)
        : '-';
    final statusColor = item.isIzin ? Colors.blue : Colors.green;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(tanggal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  Chip(
                    label: Text(item.isIzin ? 'Izin' : 'Masuk', style: TextStyle(color: statusColor, fontSize: 12)),
                    side: BorderSide(color: statusColor),
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Hapus',
                  ),
                ],
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.login,
                      label: 'Masuk',
                      value: _time(item.checkIn),
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.logout,
                      label: 'Pulang',
                      value: item.isIzin ? '-' : _time(item.checkOut),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              if (item.isIzin && (item.alasanIzin ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Alasan: ${item.alasanIzin}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              if ((item.checkInAddress ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.checkInAddress!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
