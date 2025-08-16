import '../old_files/ask_question_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

// --- DATA MODEL for a Question ---
// In a real app, this would be in its own file (e.g., models/question_model.dart)
class Question {
  final String id;
  final String title;
  final String author;
  final String authorImageUrl;
  final int votes;
  final int answers;
  final List<String> tags;
  final DateTime timestamp;

  Question({
    required this.id,
    required this.title,
    required this.author,
    required this.authorImageUrl,
    required this.votes,
    required this.answers,
    required this.tags,
    required this.timestamp,
  });
}

// --- HOME SCREEN WIDGET ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock data to simulate fetching questions from your backend
  final List<Question> _questions = [
    Question(
      id: '1',
      title: 'How to manage state in a large Flutter application?',
      author: 'Jane Doe',
      authorImageUrl: 'https://i.pravatar.cc/150?u=jane_doe',
      votes: 125,
      answers: 12,
      tags: ['flutter', 'state-management', 'provider'],
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Question(
      id: '2',
      title: 'What is the best way to handle API calls with error handling in Dart?',
      author: 'John Smith',
      authorImageUrl: 'https://i.pravatar.cc/150?u=john_smith',
      votes: 98,
      answers: 8,
      tags: ['dart', 'api', 'http'],
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Question(
      id: '3',
      title: 'How to implement a clean architecture in Node.js?',
      author: 'Alex Johnson',
      authorImageUrl: 'https://i.pravatar.cc/150?u=alex_johnson',
      votes: 210,
      answers: 15,
      tags: ['node.js', 'architecture', 'backend'],
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add navigation logic for other tabs here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows body to go behind the bottom nav bar
      appBar: AppBar(
        title: const Text('DevOverflow', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2C3E50).withOpacity(0.8),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 28),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=current_user'),
              radius: 18,
            ),
          ),
        ],
      ),
      // Use a gradient background consistent with the app's theme
      backgroundColor: const Color(0xFF2C3E50),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 80), // Padding to avoid overlap with FAB/NavBar
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          return QuestionCard(question: _questions[index]);
        },
      ),
      // Floating Action Button to ask a new question
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AskQuestionScreen()));
        },
        backgroundColor: const Color(0xFFF2C94C),
        child: const Icon(Icons.add, color: Color(0xFF2C3E50)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // Bottom navigation bar with glassmorphism effect
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            color: Colors.white.withOpacity(0.1),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildNavItem(Icons.home_filled, 'Home', 0),
                _buildNavItem(Icons.search, 'Search', 1),
                const SizedBox(width: 40), // The space for the FAB
                _buildNavItem(Icons.bookmark_border, 'Bookmarks', 2),
                _buildNavItem(Icons.person_outline, 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? const Color(0xFFF2C94C) : Colors.white70,
        size: 28,
      ),
      onPressed: () => _onItemTapped(index),
      tooltip: label,
    );
  }
}


// --- QUESTION CARD WIDGET ---
// In a real app, this would be in its own file (e.g., widgets/question_card.dart)
class QuestionCard extends StatelessWidget {
  final Question question;

  const QuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author and timestamp
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(question.authorImageUrl),
                radius: 16,
              ),
              const SizedBox(width: 10),
              Text(
                question.author,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${DateTime.now().difference(question.timestamp).inHours}h ago',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Question Title
          Text(
            question.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Tags
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: question.tags.map((tag) => Chip(
              label: Text(tag),
              backgroundColor: const Color(0xFFF2C94C).withOpacity(0.2),
              labelStyle: const TextStyle(color: Color(0xFFF2C94C), fontWeight: FontWeight.bold),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            )).toList(),
          ),
          const Divider(color: Colors.white24, height: 32),
          // Stats (Votes, Answers)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(Icons.arrow_upward, '${question.votes} Votes'),
              _buildStatItem(Icons.comment_outlined, '${question.answers} Answers'),
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: Colors.white70),
                onPressed: () {},
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}
