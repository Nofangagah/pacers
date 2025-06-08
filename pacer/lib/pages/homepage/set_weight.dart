import 'package:flutter/material.dart';
import 'package:pacer/service/user_service.dart';
import 'package:pacer/pages/homepage/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetWeightPage extends StatefulWidget {
  final int userId;

  const SetWeightPage({super.key, required this.userId});

  @override
  State<SetWeightPage> createState() => _SetWeightPageState();
}

class _SetWeightPageState extends State<SetWeightPage> {
  final TextEditingController weightController = TextEditingController();
  bool isLoading = false;

  void _saveWeight() async {
    final weight = double.tryParse(weightController.text);
    if (weight == null || weight <= 0 || weight > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Berat badan tidak valid'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final success = await UserService.updateProfile(widget.userId, {
      'weight': weight,
    });

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('userWeight', weight);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Berat badan berhasil disimpan'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal menyimpan berat badan'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Atur Berat Badan', style: theme.textTheme.titleLarge),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Masukkan berat badanmu (kg)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Contoh: 70',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
                hintStyle: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  )
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _saveWeight,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: Text(
                          'Simpan',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      // TextButton(onPressed: _skip, child: Text('Lewati')),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}