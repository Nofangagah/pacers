import 'package:flutter/material.dart';
import 'package:pacer/pages/konversi/konversi_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pacer/pages/profilePage/profile_page.dart';
import 'package:pacer/pages/running/running_page.dart';
import 'package:pacer/pages/activity/activity_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int? _userId;
  List<Widget> _pages = [Container(), Container(), Container(), Container()]; // placeholder

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) {
      return;
    }

    setState(() {
      _userId = userId;
      _pages = [
        const RunningPage(),
        ActivityPage(userId: _userId!),
        const CurrencyTimePage(),
        const ProfilePage(),
      ];
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = _userId != null && _pages.length == 4;

    return Scaffold(
      body: SafeArea(
        child: isInitialized
            ? IndexedStack(
                index: _selectedIndex,
                children: _pages,
              )
            : const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: isInitialized
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.directions_run),
                  label: 'Activity',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.currency_exchange),
                  label: 'Currency & Time',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            )
          : null,
    );
  }
}


