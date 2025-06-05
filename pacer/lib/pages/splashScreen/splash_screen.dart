import 'package:flutter/material.dart';
import 'package:pacer/service/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final userWeight = prefs.getInt('userWeight') ?? 0;
    final userId = prefs.getInt('userId');

    await Future.delayed(const Duration(seconds: 2));

    if (accessToken == null) {
      print("🔓 [Splash] User belum login.");
      Navigator.pushReplacementNamed(context, '/login');
    } else if (userId == null) {
      print("❌ [Splash] userId null. Tidak bisa kirim token.");
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      print("✅ [Splash] User login, ID: $userId");

      // Inisialisasi notifikasi
      await NotificationService().initNotification(userId);

      if (userWeight <= 0) {
        Navigator.pushReplacementNamed(
          context,
          '/set-weight',
          arguments: {'userId': userId},
        );
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/pacer.jpg',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
