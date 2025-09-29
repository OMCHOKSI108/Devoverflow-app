import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'welcome.dart';
import 'signup.dart';
import 'login.dart';
import 'forgetpassword.dart';
import 'homescreen.dart';
import 'bookmarks.dart';
import 'myfriends.dart';
import 'allfriends.dart';
import 'aichatbot.dart';
import 'questions.dart';
import 'profile.dart';
import 'change_password.dart';
import 'groups.dart';
import 'user_profile_view.dart';
import 'chat_history.dart';
import 'search.dart';
import 'notifications.dart';
import 'flowchart_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger.dart';
import 'api_config.dart';
import 'api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  initLogger();

  final prefs = await SharedPreferences.getInstance();

  final allUsersSeed = <Map<String, dynamic>>[];

  final friendsSeed = <Map<String, dynamic>>[];

  final bookmarksSeed = <Map<String, dynamic>>[];

  final api = ApiService();

  Future<void> tryFetchAndCache(
    String key,
    Future<List<dynamic>> Function() fetcher,
    List<dynamic> seed,
  ) async {
    try {
      final list = await fetcher();
      if (list.isNotEmpty) {
        await prefs.setString(key, json.encode(list));
        return;
      }
    } catch (e) {}

    if (!prefs.containsKey(key)) {
      await prefs.setString(key, json.encode(seed));
    }
  }

  await tryFetchAndCache('all_users', () async {
    final resp = await api.getAllUsers(page: 1, limit: 100);
    List<dynamic> list = ApiService().extractList(resp, ['users', 'data']);

    // Handle nested data structure: response.data.users
    if (list.isEmpty) {
      final data = resp['data'];
      if (data is Map<String, dynamic> && data['users'] is List) {
        list = data['users'] as List<dynamic>;
      }
    }

    return list;
  }, allUsersSeed);

  await tryFetchAndCache('friends', () async {
    final resp = await api.getFriends(page: 1, limit: 100);
    List<dynamic> list = ApiService().extractList(resp, ['friends', 'data']);

    // Handle nested data structure: response.data.friends
    if (list.isEmpty) {
      final data = resp['data'];
      if (data is Map<String, dynamic> && data['friends'] is List) {
        list = data['friends'] as List<dynamic>;
      }
    }

    return list;
  }, friendsSeed);

  await tryFetchAndCache('bookmarks', () async {
    final resp = await api.getBookmarks(page: 1, limit: 100);
    List<dynamic> list = ApiService().extractList(resp, ['bookmarks', 'data']);

    // Handle nested data structure: response.data.bookmarks
    if (list.isEmpty) {
      final data = resp['data'];
      if (data is Map<String, dynamic> && data['bookmarks'] is List) {
        list = data['bookmarks'] as List<dynamic>;
      }
    }

    return list;
  }, bookmarksSeed);

  // Debug info: print the configured base URL (helps with device vs localhost)
  logInfo('API baseUrl (from .env): ${ApiConfig.baseUrl}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Devoverflow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
      routes: {
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgetpassword': (context) => const ForgetPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/bookmarks': (context) => const BookmarksScreen(),
        '/myfriends': (context) => const MyFriendsScreen(),
        '/allfriends': (context) => const AllFriendsScreen(),
        '/aichatbot': (context) => const AIChatBotScreen(),
        '/chat_history': (context) => const ChatHistoryScreen(),
        '/groups': (context) => const GroupListScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/change_password': (context) => const ChangePasswordScreen(),
        '/questions': (context) => const QuestionsScreen(),
        '/search': (context) => const SearchScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/flowchart': (context) => const FlowchartScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/user_profile_view') {
          final email = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => UserProfileViewScreen(userEmail: email),
          );
        }
        return null;
      },
    );
  }
}
