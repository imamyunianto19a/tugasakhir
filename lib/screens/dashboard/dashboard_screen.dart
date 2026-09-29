import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/session_manager.dart';
import '../../core/utils/toast.dart';
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

/// Bagian 2 - Dashboard Absensi dengan UI Kontras Tinggi & Modern:
/// Greeting Banner Gradient, Status Absen Hari Ini, Stat Cards, & Akses Peta.
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
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => IconButton(
              icon: Icon(themeProvider.isDarkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined),
              tooltip: 'Ganti Tema',
              onPressed: () =>
                  themeProvider.toggleTheme(!themeProvider.isDarkMode),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
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
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
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
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
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
    if (hour < 11) return 'Selamat Pagi 🌅';
    if (hour < 15) return 'Selamat Siang ☀️';
    if (hour < 18) return 'Selamat Sore 🌇';
    return 'Selamat Malam 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final absenProvider = context.watch<AbsenProvider>();
    final stat = absenProvider.statistik;
    final today =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => context.read<AbsenProvider>().loadStatistik(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Gradient Header (Kontras Tinggi & Modern)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F766E), const Color(0xFF0A2328)]
                    : [const Color(0xFF0F766E), const Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF99F6E4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userName ?? 'Pengguna',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        (userName ?? 'P').isNotEmpty
                            ? (userName ?? 'P')[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 14, color: Color(0xFF99F6E4)),
                      const SizedBox(width: 6),
                      Text(
                        today,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status Absen Hari Ini
          _TodayCard(stat: stat),
          const SizedBox(height: 16),

          // Rekap Bulan Ini - Metric Cards Berwarna Kontras
          const Text(
            'Rekap Absensi Bulan Ini',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Total Absen',
                  value: '${stat.totalAbsen}',
                  icon: Icons.date_range_rounded,
                  bgColor: const Color(0xFF0F766E),
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Hadir',
                  value: '${stat.totalMasuk}',
                  icon: Icons.check_circle_rounded,
                  bgColor: const Color(0xFF059669),
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Izin',
                  value: '${stat.totalIzin}',
                  icon: Icons.assignment_late_rounded,
                  bgColor: const Color(0xFF0284C7),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons: Absen Masuk & Pulang
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Absen Masuk',
                  color: const Color(0xFF0D9488),
                  isLoading: absenProvider.isCheckingIn,
                  onPressed: () => _handleCheckIn(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Absen Pulang',
                  color: const Color(0xFFD97706),
                  isLoading: absenProvider.isCheckingOut,
                  onPressed: () => _handleCheckOut(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed:
                absenProvider.isCheckingIn ? null : () => _handleIzin(context),
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Ajukan Izin'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 12),

          // Button Map
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AbsenMapScreen()),
              );
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text('Lihat Lokasi Saya di Peta'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
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

    final alasan = await showDialog<String>(
      context: context,
      builder: (_) => const _IzinDialog(),
    );
    if (alasan == null) return;

    await provider.checkIn(status: AbsenModel.statusIzin, alasanIzin: alasan);
    showToast(provider.lastMessage ?? 'Pengajuan izin gagal');
  }
}

/// Kartu status absen hari ini (Kontras Tinggi).
class _TodayCard extends StatelessWidget {
  final AbsenStatistik stat;
  const _TodayCard({required this.stat});

  String _time(DateTime? d) =>
      d == null ? '--:--' : DateFormat('HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    final today = stat.hariIni;
    final String statusLabel;
    final Color statusColor;
    final Color badgeBg;

    if (today == null) {
      statusLabel = 'Belum Absen';
      statusColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFFFBEB);
    } else if (today.isIzin) {
      statusLabel = 'Izin';
      statusColor = const Color(0xFF0284C7);
      badgeBg = const Color(0xFFF0F9FF);
    } else if (today.hasCheckedOut) {
      statusLabel = 'Selesai';
      statusColor = const Color(0xFF059669);
      badgeBg = const Color(0xFFECFDF5);
    } else {
      statusLabel = 'Sudah Masuk';
      statusColor = const Color(0xFF0D9488);
      badgeBg = const Color(0xFFF0FDFA);
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.access_time_filled_rounded,
                        size: 20, color: Color(0xFF0D9488)),
                    SizedBox(width: 8),
                    Text(
                      'Absen Hari Ini',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1.2),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: 'Jam Masuk',
                    value: _time(today?.checkIn),
                    icon: Icons.login_rounded,
                    color: const Color(0xFF059669),
                  ),
                ),
                Container(
                    height: 36,
                    width: 1,
                    color: Colors.grey.withValues(alpha: 0.3)),
                Expanded(
                  child: _TimeTile(
                    label: 'Jam Pulang',
                    value: today?.isIzin == true ? '-' : _time(today?.checkOut),
                    icon: Icons.logout_rounded,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            if (today?.isIzin == true &&
                (today?.alasanIzin ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: Color(0xFF0284C7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Alasan: ${today!.alasanIzin}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0284C7),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if ((today?.checkInAddress ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 16, color: Color(0xFF0D9488)),
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

class _TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TimeTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color bgColor;
  final Color textColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: textColor.withValues(alpha: 0.9)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.edit_note_rounded, color: Color(0xFF0D9488)),
          SizedBox(width: 8),
          Text('Ajukan Izin'),
        ],
      ),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Tuliskan alasan izin (mis. Sakit, Acara keluarga)',
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(90, 42),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Kirim'),
        ),
      ],
    );
  }
}
