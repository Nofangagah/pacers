import 'package:flutter/material.dart';

class KesanPesanPage extends StatelessWidget {
  const KesanPesanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesan & Pesan'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Kesan & Pesan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Kesan:\n'
                  'Aplikasi ini sangat membantu dalam memantau aktivitas lari dan kesehatan. '
                  'Fitur-fitur seperti membership, konversi mata uang, dan pengingat event sangat bermanfaat. '
                  'Tampilan aplikasi juga modern dan mudah digunakan.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pesan:\n'
                  'Semoga aplikasi ini terus dikembangkan dengan fitur-fitur baru yang inovatif. '
                  'Terima kasih kepada dosen dan teman-teman yang telah membimbing selama proses pembuatan aplikasi ini.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}