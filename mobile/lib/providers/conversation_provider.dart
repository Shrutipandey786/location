import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/conversation_summary.dart';
import '../services/auth_api_service.dart';
import '../services/deletion_storage_service.dart';

class ConversationProvider extends ChangeNotifier {
  final AuthApiService _apiService = AuthApiService();

  List<ConversationSummary> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = "";

  List<ConversationSummary> get conversations => List.unmodifiable(_conversations);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  Future<void> fetchConversations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getConversations();
      if (response.data != null && response.data is List) {
        final listData = response.data as List<dynamic>;
        _conversations = listData
            .map((item) => ConversationSummary.fromJson(item as Map<String, dynamic>))
            .where((s) => !DeletionStorageService().isPeerCleared(s.peerId))
            .toList();
      } else {
        _conversations = [];
      }
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        _errorMessage = e.response!.data['message'].toString();
      } else {
        _errorMessage = e.message ?? "Network error loading conversations.";
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> searchConversations(String query) async {
    _searchQuery = query;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.searchConversations(query);
      if (response.data != null && response.data is List) {
        final listData = response.data as List<dynamic>;
        _conversations = listData
            .map((item) => ConversationSummary.fromJson(item as Map<String, dynamic>))
            .where((s) => !DeletionStorageService().isPeerCleared(s.peerId))
            .toList();
      } else {
        _conversations = [];
      }
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        _errorMessage = e.response!.data['message'].toString();
      } else {
        _errorMessage = e.message ?? "Network error searching conversations.";
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
