import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';

/// Menampilkan seluruh pengguna dari GET /api/users ("All data user").
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Pengguna')),
      body: RefreshIndicator(
        onRefresh: () => context.read<ProfileProvider>().loadUsers(),
        child: provider.isLoadingUsers
            ? const Center(child: CircularProgressIndicator())
            : provider.users.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(provider.errorMessage ?? 'Belum ada data pengguna')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final u = provider.users[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?'),
                          ),
                          title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(u.email),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
