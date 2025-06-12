import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pacer/pages/kesan_pesan/kesan_pesan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:pacer/pages/auth/login_page.dart';
import 'package:pacer/pages/auth/register_page.dart';
import 'package:pacer/pages/homepage/home_page.dart';
import 'package:pacer/pages/homepage/set_weight.dart';
import 'package:pacer/pages/profilePage/edit_profile_page.dart';
import 'package:pacer/pages/profilePage/profile_page.dart';
import 'package:pacer/pages/splashScreen/splash_screen.dart';
import 'package:pacer/pages/provider/activity_provider.dart'; 
import 'package:provider/provider.dart'; 

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔕 Background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  timeago.setLocaleMessages('id', timeago.IdMessages());

  runApp(
    
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
       
      ],
      child: const MyApp(),
    ),
   
  );

  // Tambahkan listener untuk navigasi dari notifikasi
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    print('🔁 User tapped notification');
    _handleNotificationNavigation(navigatorKey.currentContext!);
  });

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      print('🧊 App opened from terminated by notification');
      _handleNotificationNavigation(navigatorKey.currentContext!);
    }
  });
}

void _handleNotificationNavigation(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('accessToken');

  if (accessToken != null && context.mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  } else if (context.mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, 
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          elevation: 10,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile': (context) => const ProfilePage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/home': (context) => const HomePage(),
        '/kesan-pesan': (context) => const KesanPesanPage(),
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
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} tidak ditemukan'),
            ),
          ),
        );
      },
    );
  }
}