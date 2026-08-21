import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/user.dart';
import '../services/auth_api_service.dart';
import '../services/deletion_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiService _apiService = AuthApiService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, String> _fieldErrors = {};

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, String> get fieldErrors => Map.unmodifiable(_fieldErrors);
  bool get isAuthenticated => _currentUser != null;

  void clearErrors() {
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      await _apiService.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();

    try {
      await DeletionStorageService().clearAllLocalDeletions();
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final userMap = (data.containsKey('user') && data['user'] is Map<String, dynamic>)
            ? data['user'] as Map<String, dynamic>
            : data;
        _currentUser = User.fromJson(userMap);
      } else {
        await checkAuthStatus();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final response = await _apiService.getCurrentUser();
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final userMap = (data.containsKey('user') && data['user'] is Map<String, dynamic>)
            ? data['user'] as Map<String, dynamic>
            : data;
        _currentUser = User.fromJson(userMap);
      } else {
        _currentUser = null;
      }
    } catch (_) {
      _currentUser = null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await DeletionStorageService().clearAllLocalDeletions();
      await _apiService.logout();
    } catch (_) {
      // Ignore network errors during logout
    } finally {
      _currentUser = null;
      notifyListeners();
    }
  }

  void _handleDioError(DioException e) {
    _fieldErrors.clear();

    if (e.response != null && e.response?.data != null) {
      final responseData = e.response!.data;

      if (responseData is Map<String, dynamic>) {
        _errorMessage = responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            'An authentication error occurred.';

        final errors = responseData['errors'];
        if (errors is Map) {
          errors.forEach((key, value) {
            _fieldErrors[key.toString()] = value.toString();
          });
        } else if (errors is List) {
          for (var err in errors) {
            if (err is Map && err.containsKey('field') && err.containsKey('defaultMessage')) {
              _fieldErrors[err['field'].toString()] = err['defaultMessage'].toString();
            }
          }
        }
      } else if (responseData is String && responseData.isNotEmpty) {
        _errorMessage = responseData;
      } else {
        _errorMessage = e.message ?? 'An error occurred during network request.';
      }
    } else {
      if (e.message != null && e.message!.contains('XMLHttpRequest')) {
        _errorMessage = 'CORS Error: Backend blocked cross-origin request. Please configure SecurityConfig CORS or launch Chrome with --disable-web-security.';
      } else {
        _errorMessage = e.message ?? 'Network error. Please check your connection.';
      }
    }
  }
}