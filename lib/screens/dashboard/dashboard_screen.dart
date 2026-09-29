import 'package:flutter/material.dart';
import '../../core/utils/toast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/session_manager.dart';
import '../../data/models/absen_model.dart';
import '../../providers/absen_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';
import '../profil/profil_screen.dart';
import '../riwayat/riwayat_screen.dart';
import 'absen_map_screen.dart';

/// Bagian 2 - Dashboard Absensi: greeting, absen masuk/pulang/izin,
/// lokasi (Geolocator), akses peta, statistik & absen hari ini.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _cachedName;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AbsenProvider>().loadStatistik();
      context.read<ProfileProvider>().loadProfile();
      _loadCachedName();
    });
  }

  Future<void> _loadCachedName() async {
    final name = await SessionManager.getUserName();
    if (mounted) setState(() => _cachedName = name);
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _handleIzin(BuildContext context) async {
    final provider = context.read<AbsenProvider>();

    final alasan = await showDialog<String>(
      context: context,
      builder: (_) => const _IzinDialog(),
    );
    if (alasan == null) return;

    await provider.checkIn(status: AbsenModel.statusIzin, alasanIzin: alasan);
    showToast(provider.lastMessage ?? 'Pengajuan izin gagal');
  }

  @override
  Widget build(BuildContext context) {
    final profileName = context.watch<ProfileProvider>().user?.name;
    final pages = [
      _DashboardHome(userName: profileName ?? _cachedName),
      const RiwayatScreen(),
      const ProfilScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi PPKD'),
        automaticallyImplyLeading: false,
        actions: [
          // Bonus 5.3 - toggle dark mode
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => IconButton(
              icon: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
              tooltip: 'Ganti Tema',
              onPressed: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
            ),
          ),
          // Bonus 5.1 - logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: IndexedStack(index: _currentTab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final String? userName;
  const _DashboardHome({required this.userName});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final absenProvider = context.watch<AbsenProvider>();
    final stat = absenProvider.statistik;
    final today = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () => context.read<AbsenProvider>().loadStatistik(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 2.1 - Nama pengguna, tanggal, greeting
          Text('$_greeting,', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            userName ?? 'Pengguna',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(today, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          // 2.5 - Absen hari ini
          _TodayCard(stat: stat),
          const SizedBox(height: 12),

          // 2.5 - Statistik bulan ini
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rekap Bulan Ini', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: 'Total Absen', value: '${stat.totalAbsen}'),
                      _StatItem(label: 'Masuk', value: '${stat.totalMasuk}'),
                      _StatItem(label: 'Izin', value: '${stat.totalIzin}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2.2 & 2.3 - Tombol Absen Masuk / Pulang
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Absen Masuk',
                  color: Colors.green,
                  isLoading: absenProvider.isCheckingIn,
                  onPressed: () => _handleCheckIn(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Absen Pulang',
                  color: Colors.orange,
                  isLoading: absenProvider.isCheckingOut,
                  onPressed: () => _handleCheckOut(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: absenProvider.isCheckingIn ? null : () => _handleIzin(context),
            icon: const Icon(Icons.assignment_late_outlined),
            label: const Text('Ajukan Izin'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 12),

          // 2.4 - Menampilkan Google Map untuk lokasi
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AbsenMapScreen()),
              );
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text('Lihat Lokasi Saya di Peta'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckIn(BuildContext context) async {
    final provider = context.read<AbsenProvider>();
    await provider.checkIn();
    showToast(provider.lastMessage ?? 'Absen masuk gagal');
  }

  Future<void> _handleCheckOut(BuildContext context) async {
    final provider = context.read<AbsenProvider>();
    await provider.checkOut();
    showToast(provider.lastMessage ?? 'Absen pulang gagal');
  }

  Future<void> _handleIzin(BuildContext context) async {
    final provider = context.read<AbsenProvider>();
    final controller = TextEditingController();

    String? errorText;

    final alasan = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Ajukan Izin'),
          content: TextField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Alasan izin, mis. izin sakit',
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  setDialogState(() => errorText = 'Alasan izin wajib diisi');
                  return;
                }
                Navigator.pop(ctx, text);
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (alasan == null) return;

    await provider.checkIn(status: AbsenModel.statusIzin, alasanIzin: alasan);
    showToast(provider.lastMessage ?? 'Pengajuan izin gagal');
  }
}

/// Kartu status absen hari ini.
class _TodayCard extends StatelessWidget {
  final AbsenStatistik stat;
  const _TodayCard({required this.stat});

  String _time(DateTime? d) => d == null ? '--:--' : DateFormat('HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    final today = stat.hariIni;
    final String statusLabel;
    final Color statusColor;
    if (today == null) {
      statusLabel = 'Belum absen';
      statusColor = Colors.grey;
    } else if (today.isIzin) {
      statusLabel = 'Izin';
      statusColor = Colors.blue;
    } else if (today.hasCheckedOut) {
      statusLabel = 'Selesai';
      statusColor = Colors.green;
    } else {
      statusLabel = 'Sudah masuk';
      statusColor = Colors.orange;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Absen Hari Ini', style: TextStyle(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12)),
                  side: BorderSide(color: statusColor),
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'Jam Masuk', value: _time(today?.checkIn)),
                _StatItem(
                  label: 'Jam Pulang',
                  value: today?.isIzin == true ? '-' : _time(today?.checkOut),
                ),
              ],
            ),
            if (today?.isIzin == true && (today?.alasanIzin ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Alasan: ${today!.alasanIzin}', style: const TextStyle(color: Colors.grey)),
            ],
            if ((today?.checkInAddress ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      today!.checkInAddress!,
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
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}




class _IzinDialog extends StatefulWidget {
  const _IzinDialog();

  @override
  State<_IzinDialog> createState() => _IzinDialogState();
}

class _IzinDialogState extends State<_IzinDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'Alasan izin wajib diisi');
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajukan Izin'),
      content: TextField(
        controller: _controller,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: 'Alasan izin, mis. izin sakit',
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Kirim'),
        ),
      ],
    );
  }
}