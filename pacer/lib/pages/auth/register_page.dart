import 'package:flutter/material.dart';
import 'package:pacer/widgets/googlesignin_button.dart';
import 'package:pacer/widgets/login_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        automaticallyImplyLeading: false, // Hide back button
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0, // Remove shadow
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const LoginForm(isRegister: true),
                        const SizedBox(height: 16),
                        const GoogleSignInButton(),
                         const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                          child: const Text(
                            "Already have an account? Login here.",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}