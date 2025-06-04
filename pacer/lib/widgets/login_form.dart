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

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();

      Map<String, dynamic> result;

      if (widget.isRegister) {
        result = await AuthService.register(name, email, password);
      } else {
        result = await AuthService.login(email, password);
      }

      if (mounted) {
        if (result['success']) {
          if (widget.isRegister) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful, please login.')),
            );
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            final prefs = await SharedPreferences.getInstance();
            final userWeight = prefs.getInt('userWeight') ?? 0;
            final userId = prefs.getInt('userId');

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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (widget.isRegister)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value!.isEmpty ? 'Enter your name' : null,
            ),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) => value!.isEmpty ? 'Enter your email' : null,
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) =>
                value!.length < 6 ? 'Password too short' : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            child: Text(widget.isRegister ? 'Register' : 'Login'),
          ),
        ],
      ),
    );
  }
}
