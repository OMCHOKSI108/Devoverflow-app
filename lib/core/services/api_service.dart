// lib/core/services/api_service.dart
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:devoverflow/common/models/question_model.dart';
import 'package:devoverflow/common/models/answer_model.dart';
import 'package:devoverflow/common/models/user_model.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    init();
  }

  // Private fields
  final String _baseUrl = 'https://devoverflow-backend.onrender.com/api';
  String? _token;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _kTokenKey = 'devoverflow_token';

  // Public getters
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  String _handleError(http.Response response) {
    try {
      final data = json.decode(response.body);
      return data['message'] ?? 'Unknown error occurred';
    } catch (_) {
      return 'Error: ${response.statusCode}';
    }
  }

  // Token management
  Future<void> init() async {
    await _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final stored = await _secureStorage.read(key: _kTokenKey);
      if (stored != null && stored.isNotEmpty) {
        _token = stored;
      }
    } catch (_) {
      // ignore storage errors; continue without token
    }
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    try {
      await _secureStorage.write(key: _kTokenKey, value: token);
    } catch (_) {}
  }

  Future<void> clearToken() async {
    _token = null;
    try {
      await _secureStorage.delete(key: _kTokenKey);
    } catch (_) {}
  }

  // Auth APIs
  Future<void> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: _getHeaders(),
        body: json.encode({
          'email': email,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      log('Error in forgot password: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
    String? name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _getHeaders(),
        body: json.encode({
          'email': email,
          'password': password,
          'username': username,
          'name': name,
        }),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Try to save token if present
        final token = body['data']?['token'] ?? body['token'];
        if (token is String && token.isNotEmpty) {
          await _saveToken(token);
        }
        return body as Map<String, dynamic>;
      }
      throw Exception(_handleError(response));
    } catch (e) {
      log('Error in register: $e');
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _getHeaders(),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        final token = body['data']?['token'] ?? body['token'];
        if (token is String && token.isNotEmpty) {
          await _saveToken(token);
        }
        return;
      }
      throw Exception(_handleError(response));
    } catch (e) {
      log('Error in login: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await clearToken();
  }

  // User APIs
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final map = json.decode(response.body)['data'];
        return UserModel.fromJson(map);
      }
      return null;
    } catch (e) {
      log('Error getting current user: $e');
      return null;
    }
  }

  Future<void> updateProfile({
    required String username,
    required String name,
    String? location,
    String? portfolioWebsite,
    String? bio,
    String? imageUrl,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/profile'),
        headers: _getHeaders(),
        body: json.encode({
          'username': username,
          'name': name,
          if (location != null) 'location': location,
          if (portfolioWebsite != null) 'website': portfolioWebsite,
          if (bio != null) 'bio': bio,
          if (imageUrl != null) 'profileImageUrl': imageUrl,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      log('Error updating profile: $e');
      rethrow;
    }
  }

  // Question APIs
  Future<List<Question>> getAllQuestions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/questions'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['data']?['items'] ?? data['data'] ?? [];
        if (items is List) {
          return items.map((map) => Question.fromJson(map)).toList();
        }
      }
      return <Question>[];
    } catch (e) {
      log('Error getting questions: $e');
      return <Question>[];
    }
  }

  Future<Question> getQuestionById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/questions/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final obj = data['data'] ?? data;
        if (obj is Map<String, dynamic>) {
          return Question.fromJson(obj);
        }
        throw Exception('Invalid question data');
      }
      throw Exception(_handleError(response));
    } catch (e) {
      log('Error getting question: $e');
      rethrow;
    }
  }

  Future<List<AnswerModel>> getAnswers(String questionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/answers/question/$questionId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body)['data'] ?? [];
        return list.map((map) => AnswerModel.fromJson(map)).toList();
      }

      return [];
    } catch (e) {
      log('Error getting answers: $e');
      return [];
    }
  }

  Future<void> createAnswer(String questionId, String body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/answers/$questionId'),
        headers: _getHeaders(),
        body: json.encode({'body': body}),
      );

      if (response.statusCode != 201) {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      log('Error creating answer: $e');
      rethrow;
    }
  }

  Future<void> voteOnAnswer(String answerId, String direction) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/answers/$answerId/vote'),
        headers: _getHeaders(),
        body: json.encode({'direction': direction}),
      );

      if (response.statusCode != 200) {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      log('Error voting answer: $e');
      rethrow;
    }
  }

  Future<void> acceptAnswer(String answerId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/answers/$answerId/accept'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      log('Error accepting answer: $e');
      rethrow;
    }
  }

  // Bookmark APIs
  Future<List<Question>> getBookmarks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bookmarks'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['data'] ?? [];
        if (list is List && list.isNotEmpty) {
          return list.map((map) => Question.fromJson(map)).toList();
        }
      }
      return <Question>[];
    } catch (e) {
      log('Error getting bookmarks: $e');
      return <Question>[];
    }
  }

  // Friends API helpers used by cubits
  Future<void> addFriend(String userId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/friends/$userId'),
      headers: _getHeaders(),
    );
    if (response.statusCode != 200) throw Exception(_handleError(response));
  }

  Future<void> removeFriend(String userId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/friends/$userId'),
      headers: _getHeaders(),
    );
    if (response.statusCode != 200) throw Exception(_handleError(response));
  }

  // Backwards-compatible alias
  // ignore: unused_element
  Future<List<AnswerModel>> getAnswersForQuestion(String questionId) async {
    return getAnswers(questionId);
  }

  Future<void> addBookmark(String questionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bookmarks/$questionId'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      log('Error adding bookmark: $e');
      rethrow;
    }
  }

  Future<void> removeBookmark(String questionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/bookmarks/$questionId'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception(_handleError(response));
      }
    } catch (e) {
      log('Error removing bookmark: $e');
      rethrow;
    }
  }

  // Search APIs
  /// Search users. If [query] is null or empty, fetches all users.
  Future<List<UserModel>> searchUsers([String? query]) async {
    try {
      final uri = (query == null || query.isEmpty)
          ? Uri.parse('$_baseUrl/users')
          : Uri.parse('$_baseUrl/users/search?q=$query');

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body)['data'] ?? [];
        return list.map((map) => UserModel.fromJson(map)).toList();
      }
      return [];
    } catch (e) {
      log('Error searching users: $e');
      return [];
    }
  }

  Future<List<Question>> searchQuestions({
    required String query,
    List<String>? tags,
  }) async {
    try {
      final queryParams = {
        'q': query,
        if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
      };

      final uri = Uri.parse('$_baseUrl/questions/search')
          .replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body)['data'] ?? [];
        return list.map((map) => Question.fromJson(map)).toList();
      }
      return <Question>[];
    } catch (e) {
      log('Error searching questions: $e');
      return <Question>[];
    }
  }

  // ---- Additional helpers expected by callers ----
  Future<UserModel> getMyProfile() async {
    final user = await getCurrentUser();
    if (user == null) throw Exception('User not authenticated');
    return user;
  }

  Future<void> updateMyProfile({
    String? bio,
    String? location,
    String? website,
    String? imageUrl,
  }) async {
    await updateProfile(
      username: '',
      name: '',
      location: location,
      portfolioWebsite: website,
      bio: bio,
      imageUrl: imageUrl,
    );
  }

  Future<Question> createQuestion({
    required String title,
    required String body,
    List<String>? tags,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/questions'),
      headers: _getHeaders(),
      body: json.encode({
        'title': title,
        'body': body,
        if (tags != null) 'tags': tags,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final map = json.decode(response.body)['data'];
      return Question.fromJson(map);
    }
    throw Exception(_handleError(response));
  }

  Future<String> getChatbotResponse(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chatbot'),
        headers: _getHeaders(),
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['data']?['reply'] ?? body['reply'] ?? body['message'] ?? '';
      }
      return '';
    } catch (e) {
      log('Chatbot error: $e');
      return '';
    }
  }
}
