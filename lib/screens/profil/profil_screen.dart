import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../users/users_screen.dart';
import 'edit_profil_screen.dart';

/// 4.1 - Menampilkan data dari GET /api/profile.
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final user = provider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profil',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfilScreen()),
                );
                if (context.mounted) context.read<ProfileProvider>().loadProfile();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ProfileProvider>().loadProfile(),
        child: provider.isLoading && user == null
            ? const Center(child: CircularProgressIndicator())
            : user == null
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      Center(child: Text(provider.errorMessage ?? 'Gagal memuat profil')),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      Center(
                        child: Text(user.email, style: const TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          children: [
                            _ProfileTile(icon: Icons.person_outline, label: 'Nama', value: user.name),
                            const Divider(height: 1),
                            _ProfileTile(icon: Icons.email_outlined, label: 'Email', value: user.email),
                            const Divider(height: 1),
                            _ProfileTile(
                              icon: Icons.calendar_today_outlined,
                              label: 'Terdaftar sejak',
                              value: user.createdAt != null
                                  ? DateFormat('d MMMM yyyy', 'id_ID').format(user.createdAt!)
                                  : '-',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: const Icon(Icons.groups_outlined, color: Colors.blue),
                          title: const Text('Daftar Pengguna'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const UsersScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }
}
