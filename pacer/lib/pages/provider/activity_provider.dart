// lib/providers/activity_provider.dart
import 'package:flutter/material.dart';
import 'package:pacer/models/activity_model.dart';
import 'package:pacer/service/activity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityProvider with ChangeNotifier {
  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ActivityModel> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fungsi untuk memuat aktivitas
  Future<void> fetchActivities(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); 

    try {
      final prefs = await SharedPreferences.getInstance();
      final int? currentUserId = prefs.getInt('userId');
      if (currentUserId == null) {
        throw Exception("User ID not found in SharedPreferences");
      }
      _activities = await ActivityService.getActivities(currentUserId);
    } catch (e) {
      _errorMessage = e.toString();
      print('Error fetching activities: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  // Fungsi untuk me-refresh aktivitas (sama seperti fetch)
  Future<void> refreshActivities(int userId) async {
    await fetchActivities(userId);
  }

  // Fungsi untuk menghapus aktivitas dan kemudian me-refresh daftar
  Future<void> deleteActivityAndUpdate(int activityId, int userId) async {
    try {
      await ActivityService.deleteActivity(activityId);
      await fetchActivities(userId); // Muat ulang aktivitas setelah penghapusan
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners(); // Perbarui pendengar tentang error
      throw e; // Lemparkan kembali error agar bisa ditangkap di UI
    }
  }
}