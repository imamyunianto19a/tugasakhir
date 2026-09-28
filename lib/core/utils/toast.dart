import 'package:flutter/material.dart';

/// Key global untuk ScaffoldMessenger (dipasang di MaterialApp pada main.dart)
/// sehingga notifikasi bisa dipanggil dari mana saja tanpa BuildContext dan
/// tanpa plugin tambahan.
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

/// Menampilkan notifikasi singkat (SnackBar).
void showToast(String message) {
  final messenger = messengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
}
