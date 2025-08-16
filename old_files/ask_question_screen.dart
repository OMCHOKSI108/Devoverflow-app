import 'package:flutter/material.dart';

class AskQuestionScreen extends StatelessWidget {
  const AskQuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask a Question'),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      backgroundColor: const Color(0xFF2C3E50),
      body: const Center(
        child: Text(
          'Question Form UI Goes Here',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
