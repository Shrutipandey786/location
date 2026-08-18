import 'dart:async';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AuthApiService {
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;

  AuthApiService._internal() {
    _init();
  }

  Dio? _dioInstance;
  final Completer<void> _initCompleter = Completer<void>();

  Future<void> _init() async {
    try {
      String baseUrl = 'http://172.16.2.18:8080/api';
      if (kIsWeb) {
        baseUrl = 'http://localhost:8080/api';
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          extra: kIsWeb ? {'withCredentials': true} : {},
        ),
      );

      if (!kIsWeb) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final cookieJar = PersistCookieJar(
          storage: FileStorage("${appDocDir.path}/.cookies/"),
        );
        dio.interceptors.add(CookieManager(cookieJar));
      }

      _dioInstance = dio;
    } catch (e) {
      debugPrint("AuthApiService initialization error: $e");
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  Future<Dio> _getDio() async {
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }
    return _dioInstance!;
  }

  Future<Response> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final dio = await _getDio();
    return await dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<Response> login({
    required String email,
    required String password,
  }) async {
    final dio = await _getDio();
    return await dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<Response> logout() async {
    final dio = await _getDio();
    return await dio.post('/auth/logout');
  }

  Future<Response> getCurrentUser() async {
    final dio = await _getDio();
    return await dio.get('/auth/me');
  }

  Future<Response> getDashboard() async {
    final dio = await _getDio();
    return await dio.get('/dashboard');
  }

  Future<Response> updateLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final dio = await _getDio();
    final Map<String, dynamic> data = {
      'latitude': latitude,
      'longitude': longitude,
    };
    if (address != null) {
      data['address'] = address;
    }
    return await dio.post(
      '/location/update',
      data: data,
    );
  }

  Future<Response> updateDeviceStatus({
    int? batteryLevel,
    bool? online,
    bool? isBroadcasting,
    String? statusMessage,
  }) async {
    final dio = await _getDio();
    final Map<String, dynamic> data = {};
    if (batteryLevel != null) data['batteryLevel'] = batteryLevel;
    if (online != null) data['online'] = online;
    if (isBroadcasting != null) data['isBroadcasting'] = isBroadcasting;
    if (statusMessage != null) data['statusMessage'] = statusMessage;

    return await dio.post(
      '/device/status',
      data: data,
    );
  }

  Future<Response> getConversations() async {
    final dio = await _getDio();
    return await dio.get('/conversations');
  }

  Future<Response> getConversationDetail(dynamic peerId) async {
    final dio = await _getDio();
    return await dio.get('/conversations/$peerId');
  }

  Future<Response> searchConversations(String query) async {
    final dio = await _getDio();
    return await dio.get(
      '/conversations/search',
      queryParameters: {'query': query},
    );
  }

  Future<Response> sendMessage(dynamic peerId, Map<String, dynamic> data) async {
    final dio = await _getDio();
    return await dio.post(
      '/conversations/$peerId/messages',
      data: data,
    );
  }

  Future<Response> sendLocationMessage(dynamic peerId, double latitude, double longitude, {String? address, String? text}) async {
    final dio = await _getDio();
    return await dio.post(
      '/conversations/$peerId/location',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (text != null) 'text': text,
      },
    );
  }

  Future<Response> sendMediaMessage(dynamic peerId, String type, {String? cameraImageUrl, int? pttDurationSeconds, String? text}) async {
    final dio = await _getDio();
    return await dio.post(
      '/conversations/$peerId/media',
      data: {
        'type': type,
        if (cameraImageUrl != null) 'cameraImageUrl': cameraImageUrl,
        if (pttDurationSeconds != null) 'pttDurationSeconds': pttDurationSeconds,
        if (text != null) 'text': text,
      },
    );
  }

  Future<String> getBaseUrl() async {
    final dio = await _getDio();
    return dio.options.baseUrl;
  }

  Future<Response> sendVoiceMessage(
    dynamic peerId,
    String filePath,
    int durationSeconds, {
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final dio = await _getDio();
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'pttDurationSeconds': durationSeconds,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (address != null) 'address': address,
    });

    return await dio.post(
      '/conversations/' + peerId.toString() + '/voice',
      data: formData,
    );
  }

  Future<Response> markConversationAsRead(dynamic peerId) async {
    final dio = await _getDio();
    return await dio.put('/conversations/$peerId/read');
  }

  Future<Response> getActivities({String? type}) async {
    final dio = await _getDio();
    final Map<String, dynamic> queryParams = {};
    if (type != null && type.isNotEmpty && type != 'ALL') {
      queryParams['type'] = type;
    }
    return await dio.get(
      '/activities',
      queryParameters: queryParams,
    );
  }

  Future<Response> getProfile() async {
    final dio = await _getDio();
    return await dio.get('/profile');
  }

  Future<Response> getDeviceTelemetry() async {
    final dio = await _getDio();
    return await dio.get('/device/telemetry');
  }

  Future<Response> getSettings() async {
    final dio = await _getDio();
    return await dio.get('/settings');
  }

  Future<Response> updateSettings(Map<String, dynamic> data) async {
    final dio = await _getDio();
    return await dio.put('/settings', data: data);
  }
}
