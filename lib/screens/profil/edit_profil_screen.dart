import 'package:flutter/material.dart';
import '../../core/utils/toast.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// 4.2 - Form edit profil, kirim ke PUT /api/profile.
///
/// Sesuai Postman Collection, API hanya menerima `name`. Email
/// ditampilkan sebagai informasi (tidak bisa diubah).
class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ProfileProvider>();
    final success = await provider.updateProfile(name: _nameController.text.trim());
    if (!mounted) return;
    if (success) {
      showToast('Profil berhasil diperbarui');
      Navigator.of(context).pop();
    } else {
      showToast(provider.errorMessage ?? 'Gagal memperbarui profil');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(controller: _nameController, label: 'Nama', icon: Icons.person_outline),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    helperText: 'Email tidak dapat diubah',
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(label: 'Simpan Perubahan', isLoading: provider.isSaving, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
