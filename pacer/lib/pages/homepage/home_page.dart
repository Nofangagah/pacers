import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pacer/pages/developer/about_me.dart';
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
  List<Widget> _pages = [
    Container(),
    Container(),
    Container(),
    Container(),
    Container(),
  ]; // placeholder

  @override
  void initState() {
    _loadCurrencyData();
    super.initState();
    _loadUserData();
  }

  Map<String, double> exchangeRates = {};
  String selectedBase = 'USD';
  double amount = 1.0;

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
        const MembershipPage(),
        const DataDiri(),
        const ProfilePage(),
      ];
    });
  }

  Future<void> _loadCurrencyData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedBase = prefs.getString('selectedBase') ?? 'USD';
      exchangeRates = jsonDecode(prefs.getString('exchangeRates') ?? '{}');
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = _userId != null && _pages.length == 5;

    return Scaffold(
      body: SafeArea(
        child:
            isInitialized
                ? IndexedStack(index: _selectedIndex, children: _pages)
                : const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar:
          isInitialized
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
                    icon: Icon(Icons.groups),
                    label: 'Membership',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.info),
                    label: 'About Me',
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
