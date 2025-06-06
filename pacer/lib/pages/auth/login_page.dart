import 'package:flutter/material.dart';
import 'package:pacer/widgets/googlesignin_button.dart';
import 'package:pacer/widgets/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'),
      automaticallyImplyLeading: false, // Hide back button
      centerTitle: true,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0, // Remove shadow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const LoginForm(isRegister: false),
            const SizedBox(height: 16),
            const GoogleSignInButton(),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text("Don't have an account? Register here.", style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}
