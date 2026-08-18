import 'package:battery_plus/battery_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/dashboard_data.dart';
import '../services/auth_api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final AuthApiService _apiService = AuthApiService();

  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      int? batteryLevel;
      try {
        final battery = Battery();
        batteryLevel = await battery.batteryLevel;
      } catch (e) {
        debugPrint("Battery fetch info: $e");
      }

      double? lat;
      double? lng;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
            );
            lat = position.latitude;
            lng = position.longitude;
          }
        }
      } catch (e) {
        debugPrint("GPS location fetch info: $e");
      }

      if (lat != null && lng != null) {
        await _apiService.updateLocation(latitude: lat, longitude: lng);
      }

      if (batteryLevel != null) {
        await _apiService.updateDeviceStatus(batteryLevel: batteryLevel);
      }

      final response = await _apiService.getDashboard();
      if (response.data != null && response.data is Map<String, dynamic>) {
        _dashboardData = DashboardData.fromJson(response.data as Map<String, dynamic>);
      } else {
        _errorMessage = "Invalid dashboard response format";
      }

      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        _errorMessage = e.response!.data['message'].toString();
      } else {
        _errorMessage = e.message ?? "Network error fetching dashboard data.";
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleBroadcast(bool isBroadcasting) async {
    try {
      await _apiService.updateDeviceStatus(isBroadcasting: isBroadcasting);
      await fetchDashboard();
    } catch (e) {
      debugPrint("Toggle broadcast error: $e");
    }
  }
}
