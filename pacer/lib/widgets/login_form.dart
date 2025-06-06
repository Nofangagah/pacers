import 'package:flutter/material.dart';
import 'package:pacer/service/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginForm extends StatefulWidget {
  final bool isRegister;
  const LoginForm({super.key, this.isRegister = false});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;

  void _submit() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('[LoginForm] SharedPreferences cleared');

      Map<String, dynamic> result;

      if (widget.isRegister) {
        print('[LoginForm] Register with name=$name, email=$email');
        result = await AuthService.register(name, email, password);
      } else {
        print('[LoginForm] Login with email=$email');
        result = await AuthService.login(email, password);
      }

      print('[LoginForm] Result from AuthService: $result');

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['success']) {
        if (widget.isRegister) {
          print('[LoginForm] Registration successful');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful, please login.'),
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          print('[LoginForm] Login successful, checking user data in prefs');

          final userWeight = prefs.getDouble('userWeight') ?? 0;
          final userId = prefs.getInt('userId');

          print('[LoginForm] userWeight=$userWeight, userId=$userId');

          if (userWeight <= 0) {
            print('[LoginForm] Redirecting to /set-weight');
            Navigator.pushReplacementNamed(
              context,
              '/set-weight',
              arguments: {'userId': userId},
            );
          } else {
            print('[LoginForm] Redirecting to /home');
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } else {
        print('[LoginForm] Auth failed: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Unknown error')),
        );
      }
    } catch (e, stacktrace) {
      setState(() => _isLoading = false);
      print('[LoginForm] Exception during submit: $e');
      print(stacktrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}


  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.tealAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isRegister)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Name'),
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Email'),
              validator: (value) => value!.isEmpty ? 'Enter your email' : null,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: TextFormField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: _inputDecoration('Password'),
              validator:
                  (value) => value!.length < 6 ? 'Password too short' : null,
            ),
          ),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                        widget.isRegister ? 'Register' : 'Login',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
