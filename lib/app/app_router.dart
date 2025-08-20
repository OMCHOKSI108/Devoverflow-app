// lib/app/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import the MainScaffold which contains the Bottom Navigation Bar
import 'package:devoverflow/features/main_scaffold/presentation/screens/main_scaffold.dart';

// Import all the screens for the routes
import 'package:devoverflow/features/splash/presentation/screens/splash_screen.dart';
import 'package:devoverflow/features/auth/presentation/screens/welcome_screen.dart';
import 'package:devoverflow/features/auth/presentation/screens/login_screen.dart';
import 'package:devoverflow/features/auth/presentation/screens/signup_screen.dart';
import 'package:devoverflow/features/auth/presentation/screens/verification_pending_screen.dart';
import 'package:devoverflow/features/home/presentation/screens/home_screen.dart';
import 'package:devoverflow/features/search/presentation/screens/search_screen.dart';
import 'package:devoverflow/features/bookmarks/presentation/screens/bookmarks_screen.dart';
import 'package:devoverflow/features/profile/presentation/screens/profile_screen.dart';
import 'package:devoverflow/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:devoverflow/features/question/presentation/screens/question_details_screen.dart';
import 'package:devoverflow/features/question/presentation/screens/ask_question_screen.dart';
import 'package:devoverflow/features/friends/presentation/screens/friends_screen.dart';
import 'package:devoverflow/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:devoverflow/features/settings/presentation/screens/settings_screen.dart';
import 'package:devoverflow/features/notifications/presentation/screens/notifications_screen.dart';

// This is the navigator key for the root navigator.
// It's used to push pages on top of the entire app (e.g., a full-screen dialog).
final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    navigatorKey: _rootNavigatorKey,
    routes: [
      // These are the top-level routes that do NOT show the bottom navigation bar.
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) {
          final Map<String, dynamic> params;
          if (state.extra is Map<String, dynamic>) {
            params = state.extra as Map<String, dynamic>;
          } else {
            params = {'email': 'your email'};
          }
          return VerificationPendingScreen(
            email: params['email'] as String,
            message: params['message'] as String? ??
                'Please check your email to verify your account',
          );
        },
      ),

      // These are full-screen routes that appear over the main scaffold.
      GoRoute(
        path: '/question/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final String questionId = state.pathParameters['id'] ?? '0';
          return QuestionDetailsScreen(questionId: questionId);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/ask-question',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AskQuestionScreen(),
      ),
      GoRoute(
        path: '/friends',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/chatbot',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChatbotScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // This StatefulShellRoute is the core of your tab navigation.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(child: navigationShell);
        },
        branches: [
          // Branch 1: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen()),
            ],
          ),
          // Branch 2: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/search',
                  builder: (context, state) => const SearchScreen()),
            ],
          ),
          // Branch 3: Bookmarks
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/bookmarks',
                  builder: (context, state) => const BookmarksScreen()),
            ],
          ),
          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen()),
            ],
          ),
        ],
      ),
    ],
    // Optional: Add error handling for routes that don't exist
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}
