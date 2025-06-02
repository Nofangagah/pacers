import 'package:flutter/material.dart';
import 'package:pacer/pages/auth/login_page.dart';
import 'package:pacer/pages/auth/register_page.dart';
import 'package:pacer/pages/homepage/home_page.dart';
import 'package:pacer/pages/homepage/set_weight.dart';
import 'package:pacer/pages/profilePage/edit_profile_page.dart';
import 'package:pacer/pages/profilePage/profile_page.dart';
import 'package:pacer/pages/splashScreen/splash_screen.dart';

// import 'package:pacer/service/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(), // splash
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile': (context) => const ProfilePage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/home': (context) => const HomePage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/set-weight') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => SetWeightPage(userId: args['userId']),
          );
        }
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('Route ${settings.name} tidak ditemukan'),
                ),
              ),
        );
      },
    );
  }
}
