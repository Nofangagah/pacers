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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Berat badan tidak valid')));
      return;
    }

    setState(() => isLoading = true);

    final success = await UserService.updateProfile(widget.userId, {
      'weight': weight,
    });

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('userWeight', weight);

      // ✅ Tampilkan snackbar sukses
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Berat badan berhasil disimpan')));

      // ⏳ Tambahkan delay sedikit agar snackbar terlihat sebelum pindah halaman
      await Future.delayed(Duration(seconds: 1));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan berat badan')));
    }

    setState(() => isLoading = false);
  }

  // void _skip() {
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (_) => const HomePage()),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Atur Berat Badan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Masukkan berat badanmu (kg)', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Contoh: 70',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : Column(
                  children: [
                    ElevatedButton(
                      onPressed: _saveWeight,
                      child: Text('Simpan'),
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
