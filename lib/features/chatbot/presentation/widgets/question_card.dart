// lib/features/home/presentation/widgets/question_card.dart
import 'package:flutter/material.dart';
import 'package:devoverflow/common/models/question_model.dart';

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
          Text(
            question.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
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