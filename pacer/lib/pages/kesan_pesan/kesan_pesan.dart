import 'package:flutter/material.dart';

class KesanPesanPage extends StatelessWidget {
  const KesanPesanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesan & Pesan'),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(  // <-- Tambahkan ini untuk menghindari overflow
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Kesan:\n'
                    'Mata kuliah Teknologi Pemrograman Mobile sangat bermanfaat dalam mempelajari konsep dasar pengembangan aplikasi mobile. Materi yang disajikan tidak hanya mudah dimengerti, tetapi juga bersifat praktis dan langsung dapat diaplikasikan. Pembelajaran menjadi lebih efektif berkat penjelasan yang jelas dan contoh-contoh relevan yang diberikan.',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pesan:\n'
                    'Pesan saya mungkin materi antara praktikum dan teori kalau bisa disamakan atau selaras sehingga mungkin kita bisa lebih adaptif, karena materi praktikum dan teori cukup jauh berbeda.',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Kembali'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}