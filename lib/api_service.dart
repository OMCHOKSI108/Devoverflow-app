import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
// shared_preferences moved to AuthService
import 'auth_service.dart';
import 'api_config.dart';
import 'logger.dart' as logger;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  // Get stored JWT token (delegates to AuthService)
  Future<String?> _getToken() async => await AuthService.getToken();

  // Store JWT token (delegates to AuthService)
  Future<void> _storeToken(String token) async =>
      await AuthService.setToken(token);

  // Remove stored token (delegates to AuthService)
  Future<void> _removeToken() async => await AuthService.clearToken();

  // Try to extract token from various response shapes returned by different backends
  String? _extractTokenFromResponse(dynamic response) {
    if (response == null) return null;
    try {
      if (response is Map<String, dynamic>) {
        // Common keys
        if (response['token'] != null) return response['token'].toString();
        if (response['accessToken'] != null)
          return response['accessToken'].toString();
        if (response['data'] is Map<String, dynamic>) {
          final data = response['data'] as Map<String, dynamic>;
          if (data['token'] != null) return data['token'].toString();
          if (data['accessToken'] != null)
            return data['accessToken'].toString();
        }
        // Sometimes token is nested under 'user' or 'auth'
        if (response['user'] is Map<String, dynamic>) {
          final user = response['user'] as Map<String, dynamic>;
          if (user['token'] != null) return user['token'].toString();
          if (user['accessToken'] != null)
            return user['accessToken'].toString();
        }
        if (response['auth'] is Map<String, dynamic>) {
          final auth = response['auth'] as Map<String, dynamic>;
          if (auth['token'] != null) return auth['token'].toString();
          if (auth['accessToken'] != null)
            return auth['accessToken'].toString();
        }
      }
    } catch (_) {
      // ignore parse errors
    }
    return null;
  }

  // Get default headers with authentication
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{'Content-Type': ApiConfig.contentTypeJson};

    if (includeAuth) {
      final token = await _getToken();
      logger.logInfo(
        'API headers: includeAuth=$includeAuth, token present=${token != null}',
      );
      if (token != null) {
        headers['Authorization'] = ApiConfig.authorizationHeader(token);
      }
    }

    return headers;
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    ApiConfig.logResponse(
      'RESPONSE',
      response.request?.url.toString() ?? '',
      response.statusCode,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = json.decode(response.body);
        return data;
      } catch (e) {
        throw Exception('Invalid JSON response: ${response.body}');
      }
    } else {
      try {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Unknown error';
        final errors = errorData['errors'] ?? [];

        if (response.statusCode == 401) {
          // Token expired or invalid
          _removeToken();
        }

        throw ApiException(
          message: message,
          statusCode: response.statusCode,
          errors: errors is List ? errors.cast<String>() : [message],
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          message: 'HTTP ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
          errors: ['HTTP ${response.statusCode}'],
        );
      }
    }
  }

  // Generic GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final finalUri = queryParams != null
          ? uri.replace(queryParameters: queryParams)
          : uri;

      ApiConfig.logRequest('GET', endpoint, queryParams);

      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await _client
          .get(finalUri, headers: headers)
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      ApiConfig.logError('GET', endpoint, e.toString());
      rethrow;
    }
  }

  // Generic POST request
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    bool includeAuth = true,
    int retryCount = 2,
  }) async {
    int attempts = 0;
    while (attempts <= retryCount) {
      final stopwatch = Stopwatch()..start();
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
        final body = data != null ? json.encode(data) : null;

        ApiConfig.logRequest('POST', endpoint, data);

        final headers = await _getHeaders(includeAuth: includeAuth);
        final response = await _client
            .post(uri, headers: headers, body: body)
            .timeout(ApiConfig.connectionTimeout);

        stopwatch.stop();
        ApiConfig.logResponse('POST', endpoint, response.statusCode, {
          'time': '${stopwatch.elapsedMilliseconds}ms',
        });

        return _handleResponse(response);
      } catch (e) {
        stopwatch.stop();
        ApiConfig.logError(
          'POST',
          endpoint,
          '${e.toString()} (Time: ${stopwatch.elapsedMilliseconds}ms)',
        );
        if (e is TimeoutException && attempts < retryCount) {
          attempts++;
          ApiConfig.logRequest('RETRY POST', endpoint, {'attempt': attempts});
          continue;
        }
        rethrow;
      }
    }
  }

  // Generic PUT request
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final body = data != null ? json.encode(data) : null;

      ApiConfig.logRequest('PUT', endpoint, data);

      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await _client
          .put(uri, headers: headers, body: body)
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      ApiConfig.logError('PUT', endpoint, e.toString());
      rethrow;
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String endpoint, {bool includeAuth = true}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      ApiConfig.logRequest('DELETE', endpoint);

      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await _client
          .delete(uri, headers: headers)
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      ApiConfig.logError('DELETE', endpoint, e.toString());
      rethrow;
    }
  }

  // File upload
  Future<dynamic> uploadFile(File file, {String fieldName = 'file'}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.uploadFile}');

      ApiConfig.logRequest('UPLOAD', ApiConfig.uploadFile, {'file': file.path});

      final headers = await _getHeaders();
      headers.remove('Content-Type'); // Let http package set it for multipart

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path),
      );

      final streamedResponse = await request.send().timeout(
        ApiConfig.connectionTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      ApiConfig.logError('UPLOAD', ApiConfig.uploadFile, e.toString());
      rethrow;
    }
  }

  // Authentication methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await post(
      ApiConfig.login,
      data: {'email': email, 'password': password},
      includeAuth: false,
    );

    if (response['success'] == true) {
      final token = _extractTokenFromResponse(response);
      if (token != null) await _storeToken(token);
    }

    return response;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await post(
      ApiConfig.register,
      // Backend expects 'username' instead of 'name'
      data: {'username': name, 'email': email, 'password': password},
      includeAuth: false,
    );

    if (response['success'] == true) {
      final token = _extractTokenFromResponse(response);
      if (token != null) await _storeToken(token);
    }

    return response;
  }

  Future<Map<String, dynamic>> registerAdmin(
    String name,
    String email,
    String password, {
    String? adminSecret,
  }) async {
    final response = await post(
      ApiConfig.registerAdmin,
      // Backend expects 'username' instead of 'name'
      data: {
        'username': name,
        'email': email,
        'password': password,
        if (adminSecret != null) 'adminSecret': adminSecret,
      },
      includeAuth: false,
    );

    if (response['success'] == true && response['token'] != null) {
      await _storeToken(response['token']);
    }

    if (response['success'] == true) {
      final token = _extractTokenFromResponse(response);
      if (token != null) await _storeToken(token);
    }

    return response;
  }

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    final response = await get(
      '${ApiConfig.verifyEmail}/$token',
      includeAuth: false,
    );

    if (response['success'] == true) {
      final tok = _extractTokenFromResponse(response);
      if (tok != null) await _storeToken(tok);
    }

    return response;
  }

  Future<Map<String, dynamic>> resendVerification(String email) async {
    return await post(
      ApiConfig.resendVerification,
      data: {'email': email},
      includeAuth: false,
    );
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await post(
      ApiConfig.forgotPassword,
      data: {'email': email},
      includeAuth: false,
    );
  }

  Future<Map<String, dynamic>> resetPassword(
    String token,
    String newPassword,
  ) async {
    return await post(
      ApiConfig.resetPassword,
      data: {'token': token, 'password': newPassword},
      includeAuth: false,
    );
  }

  // Groups API methods
  Future<Map<String, dynamic>> getAllGroups() async {
    return await get(ApiConfig.getAllGroups);
  }

  Future<Map<String, dynamic>> createGroup(
    String name,
    String description,
  ) async {
    return await post(
      ApiConfig.createGroup,
      data: {'name': name, 'description': description},
    );
  }

  Future<Map<String, dynamic>> getGroupDetails(String groupId) async {
    return await get('${ApiConfig.getGroupDetails}/$groupId');
  }

  Future<Map<String, dynamic>> joinGroup(String groupId) async {
    return await post('${ApiConfig.joinGroup}/$groupId/join');
  }

  Future<Map<String, dynamic>> leaveGroup(String groupId) async {
    return await post('${ApiConfig.leaveGroup}/$groupId/leave');
  }

  Future<Map<String, dynamic>> postGroupQuestion(
    String groupId,
    String title,
    String body,
  ) async {
    return await post(
      '${ApiConfig.postGroupQuestion}/$groupId/questions',
      data: {'title': title, 'body': body},
    );
  }

  Future<Map<String, dynamic>> getGroupQuestions(String groupId) async {
    return await get('${ApiConfig.getGroupQuestions}/$groupId/questions');
  }

  // Search API methods
  Future<Map<String, dynamic>> searchQuestions(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      ApiConfig.searchQuestions,
      queryParams: {
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
  }

  // Notifications API methods
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      ApiConfig.getNotifications,
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
    );
  }

  Future<Map<String, dynamic>> markNotificationAsRead(
    String notificationId,
  ) async {
    return await put(
      '${ApiConfig.markNotificationAsRead}/$notificationId/read',
    );
  }

  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    return await put(ApiConfig.markAllNotificationsAsRead);
  }

  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    return await delete('${ApiConfig.deleteNotification}/$notificationId');
  }

  Future<void> logout() async {
    await _removeToken();
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await get(ApiConfig.getCurrentUser);
  }

  Future<Map<String, dynamic>> getBookmarks({
    int page = 1,
    int limit = 100,
  }) async {
    return await get(
      ApiConfig.getBookmarks,
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
    );
  }

  Future<Map<String, dynamic>> addBookmark(String questionId) async {
    return await post('${ApiConfig.addBookmark}/$questionId');
  }

  Future<Map<String, dynamic>> removeBookmark(String questionId) async {
    return await delete('${ApiConfig.deleteBookmark}/$questionId');
  }

  Future<Map<String, dynamic>> checkBookmark(String questionId) async {
    return await get('${ApiConfig.checkQuestionBookmark}/$questionId');
  }

  // Convenience methods for commonly used endpoints
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 100,
  }) async {
    return await get(
      ApiConfig.getAllUsers,
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
    );
  }

  Future<Map<String, dynamic>> getFriends({
    int page = 1,
    int limit = 100,
  }) async {
    return await get(
      ApiConfig.getFriends,
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
    );
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token != null;
  }

  // Helper: extract a List from common response keys
  List<dynamic> extractList(dynamic resp, [List<String>? keys]) {
    if (resp == null) return [];
    final tryKeys =
        keys ?? ['items', 'data', 'users', 'friends', 'bookmarks', 'questions'];
    if (resp is List) return resp;
    if (resp is Map<String, dynamic>) {
      for (final k in tryKeys) {
        if (resp[k] is List) return resp[k] as List<dynamic>;
      }
    }
    return [];
  }

  Future<Map<String, dynamic>> aiStatus() async {
    return await get(ApiConfig.aiStatus, includeAuth: false);
  }

  Future<Map<String, dynamic>> aiSimilarQuestions(
    String questionTitle,
    String questionBody,
  ) async {
    return await post(
      ApiConfig.aiSimilarQuestions,
      data: {'questionTitle': questionTitle, 'questionBody': questionBody},
      includeAuth: false,
    );
  }

  Future<Map<String, dynamic>> aiAnswerSuggestion(
    String questionTitle,
    String questionBody,
    List<String> tags,
  ) async {
    return await post(
      ApiConfig.aiAnswerSuggestion,
      data: {
        'questionTitle': questionTitle,
        'questionBody': questionBody,
        'tags': tags,
      },
    );
  }

  Future<Map<String, dynamic>> aiTagSuggestions(
    String questionTitle,
    String questionBody,
  ) async {
    return await post(
      ApiConfig.aiTagSuggestions,
      data: {'questionTitle': questionTitle, 'questionBody': questionBody},
    );
  }

  Future<Map<String, dynamic>> aiChatbot(
    String message, {
    String? context,
  }) async {
    return await post(
      ApiConfig.aiChatbot,
      data: {'message': message, if (context != null) 'context': context},
    );
  }

  Future<Map<String, dynamic>> aiQuestionImprovements(
    String questionTitle,
    String questionBody,
  ) async {
    return await post(
      ApiConfig.aiQuestionImprovements,
      data: {'questionTitle': questionTitle, 'questionBody': questionBody},
    );
  }

  // Flowchart methods
  Future<Map<String, dynamic>> createFlowchart(
    String prompt, {
    bool render = true,
    String output = 'png',
  }) async {
    return await post(
      ApiConfig.createFlowchart,
      data: {'prompt': prompt, 'render': render, 'output': output},
    );
  }

  Future<Map<String, dynamic>> getFlowchart(String flowId) async {
    return await get('${ApiConfig.getFlowchart}$flowId');
  }

  Future<Map<String, dynamic>> getFlowchartRender(String flowId) async {
    return await get('${ApiConfig.getFlowchartRender}$flowId/render');
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final List<String> errors;

  ApiException({
    required this.message,
    required this.statusCode,
    required this.errors,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode, Errors: ${errors.join(', ')})';
  }
}
