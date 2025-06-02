import 'package:flutter/material.dart';
import 'package:pacer/service/auth_service.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Image.asset(
        'assets/google_logo.png', // Ganti sesuai path gambar kamu
        height: 24,
        width: 24,
      ),
      label: const Text('Login dengan Google'),
      onPressed: () async {
        final result = await AuthService.signInWithGoogle();

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result['message'])));

          if (result['success']) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      },
    );
  }
}
