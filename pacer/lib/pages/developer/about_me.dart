import 'package:flutter/material.dart';

class DataDiri extends StatelessWidget {
  const DataDiri({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Me'),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: const AssetImage('assets/profile.jpeg'),
                onBackgroundImageError: (exception, stackTrace) {
                  debugPrint('Gagal load gambar: $exception');
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Nofan Zohrial',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Mahasiswa Teknik Informatika',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.school, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Jurusan:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 10),
                          Text('Teknik Informatika'),
                        ],
                      ),
                      Divider(height: 25),
                      Row(
                        children: [
                          Icon(Icons.cake, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Tanggal Lahir:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 10),
                          Text('04 November 2003'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
