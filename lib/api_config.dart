import 'logger.dart' as logger;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Base URLs - can be switched between local and production
  static const String baseUrlLocal = 'http://localhost:3000/api';
  // Updated to user-provided backend
  static const String baseUrlProduction =
      'https://devoverflow-backend.onrender.com/api';

  // Current base URL - reads from environment
  static String get baseUrl {
    final environment = dotenv.env['ENVIRONMENT'] ?? 'development';
    if (environment == 'production') {
      return dotenv.env['BASE_URL_PRODUCTION'] ?? baseUrlProduction;
    } else {
      return dotenv.env['BASE_URL_LOCAL'] ?? baseUrlLocal;
    }
  }

  // Timeout configurations
  static const Duration connectionTimeout = Duration(seconds: 120);
  static const Duration receiveTimeout = Duration(seconds: 120);

  // API Endpoints
  static const String auth = '/auth';
  static const String users = '/users';
  static const String questions = '/questions';
  static const String answers = '/answers';
  static const String bookmarks = '/bookmarks';
  static const String gamification = '/gamification';
  static const String chat = '/chat';
  static const String groups = '/groups';
  static const String search = '/search';
  static const String notifications = '/notifications';
  static const String upload = '/upload';
  static const String admin = '/admin';

  // Authentication Endpoints
  static const String register = '/auth/register';
  static const String registerAdmin = '/auth/register-admin';
  static const String login = '/auth/login';
  static const String verifyEmail = '/auth/verify';
  static const String resendVerification = '/auth/resend-verification';
  static const String setupAdmin = '/auth/setup-admin';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String getCurrentUser = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String changePassword = '/auth/change-password';

  // User Endpoints
  static const String getAllUsers = '/users';
  static const String getUserSettings = '/users/settings';
  static const String updateUserSettings = '/users/settings';
  static const String getUserSuggestions = '/users/suggestions';
  static const String getUserNotifications = '/users/notifications';
  static const String markAllNotificationsRead =
      '/users/notifications/read-all';
  static const String markNotificationRead = '/users/notifications/';
  static const String getUserReputation = '/users/';
  static const String getUserSummary = '/users/';
  static const String getUserActivity = '/users/';
  static const String getUserFollowing = '/users/';
  static const String getUserFollowers = '/users/';
  static const String followUser = '/users/';
  static const String unfollowUser = '/users/';
  static const String getUserProfile = '/users/';
  static const String getUserConnectionStatus = '/users/';

  // Friends/Social Endpoints
  static const String getFriends = '/users/friends';
  static const String addFriend = '/users/friends';
  static const String removeFriend = '/users/friends';

  // Questions Endpoints
  static const String getAllQuestions = '/questions';
  static const String getQuestionsByUser = '/questions/user/';
  static const String searchQuestions = '/questions/search';
  static const String getSingleQuestion = '/questions/';
  static const String createQuestion = '/questions';
  static const String updateQuestion = '/questions/';
  static const String deleteQuestion = '/questions/';
  static const String voteOnQuestion = '/questions/';

  // Answers Endpoints
  static const String postAnswer = '/answers/';
  static const String updateAnswer = '/answers/';
  static const String deleteAnswer = '/answers/';
  static const String acceptAnswer = '/answers/';
  static const String voteOnAnswer = '/answers/';
  static const String getAnswersByQuestion = '/answers/question/';
  static const String getAnswersByUser = '/answers/user/';

  // Bookmarks Endpoints
  static const String getBookmarks = '/bookmarks';
  static const String addBookmark = '/bookmarks';
  static const String deleteBookmark = '/bookmarks/';
  static const String addQuestionBookmark = '/bookmarks/question/';
  static const String removeQuestionBookmark = '/bookmarks/question/';
  static const String checkQuestionBookmark = '/bookmarks/check/';

  // Gamification Endpoints
  static const String getReputation = '/gamification/reputation';
  static const String getReputationHistory = '/gamification/reputation/history';
  static const String getBadges = '/gamification/badges';
  static const String getPrivileges = '/gamification/privileges';
  static const String getLeaderboard = '/gamification/leaderboard';

  // AI Chat Endpoints
  static const String getChatSessions = '/chat/sessions';
  static const String getChatMessages = '/chat/sessions/';
  static const String createChatSession = '/chat/sessions';
  static const String sendChatMessage = '/chat/sessions/';
  static const String deleteChatSession = '/chat/sessions/';

  // AI (server-side AI features) - documented under /api/ai
  static const String aiStatus = '/ai/status';
  static const String aiSimilarQuestions = '/ai/similar-questions';
  static const String aiAnswerSuggestion = '/ai/answer-suggestion';
  static const String aiTagSuggestions = '/ai/tag-suggestions';
  static const String aiChatbot = '/ai/chatbot';
  static const String aiQuestionImprovements = '/ai/question-improvements';

  // Flowchart endpoints
  static const String createFlowchart = '/ai/flowchart';
  static const String getFlowchart = '/ai/flowchart/';
  static const String getFlowchartRender = '/ai/flowchart/';

  // Groups Endpoints
  static const String getAllGroups = '/groups';
  static const String createGroup = '/groups';
  static const String getGroupDetails = '/groups/';
  static const String joinGroup = '/groups/';
  static const String leaveGroup = '/groups/';
  static const String postGroupQuestion = '/groups/';
  static const String getGroupQuestions = '/groups/';

  // Search Endpoints
  static const String advancedSearch = '/search';
  static const String getSearchSuggestions = '/search/suggestions';
  static const String getTrendingTopics = '/search/trending';

  // Notifications Endpoints
  static const String getNotifications = '/users/notifications';
  static const String markNotificationAsRead = '/users/notifications/';
  static const String markAllNotificationsAsRead =
      '/users/notifications/read-all';
  static const String deleteNotification = '/users/notifications/';

  // Upload Endpoints
  static const String uploadFile = '/upload';

  // Admin Endpoints
  static const String createReport = '/admin/reports';
  static const String getAllReports = '/admin/reports';
  static const String resolveReport = '/admin/reports/';
  static const String getAdminStats = '/admin/stats';
  static const String deleteContent = '/admin/content/';
  static const String manageUser = '/admin/users/';
  static const String getAllUsersAdmin = '/admin/users';
  static const String deleteUser = '/admin/users/';
  static const String updateUserDetails = '/admin/users/';
  static const String getAllQuestionsAdmin = '/admin/questions';
  static const String editQuestionAdmin = '/admin/questions/';
  static const String getAllAnswersAdmin = '/admin/answers';
  static const String editAnswerAdmin = '/admin/answers/';
  static const String getAllCommentsAdmin = '/admin/comments';
  static const String addCommentAdmin = '/admin/comments';
  static const String editCommentAdmin = '/admin/comments/';
  static const String deleteCommentAdmin = '/admin/comments/';

  // HTTP Headers
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormData = 'multipart/form-data';
  static String authorizationHeader(String token) => 'Bearer $token';

  // Debug logging
  // If endpoint already looks like a full URL, don't prefix the baseUrl again
  static String _loggedUri(String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }
    return '$baseUrl$endpoint';
  }

  static void logRequest(
    String method,
    String endpoint, [
    Map<String, dynamic>? data,
  ]) {
    logger.logInfo('🚀 API $method: ${_loggedUri(endpoint)}');
    if (data != null) logger.logInfo('📦 Data: $data');
  }

  static void logResponse(
    String method,
    String endpoint,
    int statusCode, [
    dynamic data,
  ]) {
    logger.logInfo('✅ API $method $statusCode: ${_loggedUri(endpoint)}');
    if (data != null && data is Map<String, dynamic>) {
      logger.logInfo('📦 Response: ${data['success'] ?? 'No success field'}');
    }
  }

  static void logError(String method, String endpoint, String error) {
    logger.logError('❌ API $method ERROR: $baseUrl$endpoint - $error');
  }
}
