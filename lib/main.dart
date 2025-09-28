import 'package:flutter/material.dart';
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
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // seed default users if not present
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('all_users')) {
    final seed = [
      {"name": "Aarav Kumar", "email": "aarav.kumar@gmail.com"},
      {"name": "Priya Sharma", "email": "priya.sharma@gmail.com"},
      {"name": "Rohan Patel", "email": "rohan.patel@gmail.com"},
      {"name": "Sneha Gupta", "email": "sneha.gupta@gmail.com"},
      {"name": "Vikram Singh", "email": "vikram.singh@gmail.com"},
      {"name": "Ananya Verma", "email": "ananya.verma@gmail.com"},
      {"name": "Karan Joshi", "email": "karan.joshi@gmail.com"},
      {"name": "Neha Reddy", "email": "neha.reddy@gmail.com"},
      {"name": "Siddharth Mehta", "email": "siddharth.mehta@gmail.com"},
      {"name": "Isha Malhotra", "email": "isha.malhotra@gmail.com"},
      {"name": "Aditya Rao", "email": "aditya.rao@gmail.com"},
      {"name": "Bhavya Singh", "email": "bhavya.singh@gmail.com"},
      {"name": "Chirag Desai", "email": "chirag.desai@gmail.com"},
      {"name": "Diya Nair", "email": "diya.nair@gmail.com"},
      {"name": "Eshan Kapoor", "email": "eshan.kapoor@gmail.com"},
      {"name": "Farhan Ali", "email": "farhan.ali@gmail.com"},
      {"name": "Gauri Iyer", "email": "gauri.iyer@gmail.com"},
      {"name": "Harsh Vyas", "email": "harsh.vyas@gmail.com"},
      {"name": "Ishaan Verma", "email": "ishaan.verma@gmail.com"},
      {"name": "Jiya Shah", "email": "jiya.shah@gmail.com"},
      {"name": "Kavya Menon", "email": "kavya.menon@gmail.com"},
      {"name": "Lakshmi Rao", "email": "lakshmi.rao@gmail.com"},
      {"name": "Manav Gupta", "email": "manav.gupta@gmail.com"},
      {"name": "Naveen Kumar", "email": "naveen.kumar@gmail.com"},
      {"name": "Olivia D'Souza", "email": "olivia.dsouza@gmail.com"},
      {"name": "Pranav Nair", "email": "pranav.nair@gmail.com"},
      {"name": "Rhea Kaur", "email": "rhea.kaur@gmail.com"},
      {"name": "Samar Jain", "email": "samar.jain@gmail.com"},
      {"name": "Tanya Bhatt", "email": "tanya.bhatt@gmail.com"},
      {"name": "Uday Sharma", "email": "uday.sharma@gmail.com"},
      {"name": "Vidya Rao", "email": "vidya.rao@gmail.com"},
    ];
    await prefs.setString('all_users', json.encode(seed));
  }
  if (!prefs.containsKey('friends')) {
    // make first 3 seeded users friends by default
    final users = json.decode(prefs.getString('all_users')!) as List;
    final initialFriends = users.take(3).toList();
    await prefs.setString('friends', json.encode(initialFriends));
  }
  if (!prefs.containsKey('bookmarks')) {
    // seed a couple of bookmarks that resemble StackOverflow links
    final bookmarks = [
      {
        'id': 1,
        'title': 'How to implement feature 1 in Flutter?',
        'excerpt':
            'I am trying to implement feature 1 and facing issues with state management...',
        'link': 'https://stackoverflow.com/questions/1',
      },
      {
        'id': 3,
        'title': 'How to implement feature 3 in Flutter?',
        'excerpt':
            'I am trying to implement feature 3 and facing issues with null safety...',
        'link': 'https://stackoverflow.com/questions/3',
      },
    ];
    await prefs.setString('bookmarks', json.encode(bookmarks));
  }

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
        '/groups': (context) => const GroupListScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/change_password': (context) => const ChangePasswordScreen(),
        '/questions': (context) => const QuestionsScreen(),
      },
    );
  }
}
