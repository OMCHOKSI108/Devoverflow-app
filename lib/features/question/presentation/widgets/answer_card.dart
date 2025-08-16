// lib/features/question/presentation/widgets/answer_card.dart
import 'package:flutter/material.dart';
import 'package:devoverflow/common/models/answer_model.dart';
import 'package:devoverflow/features/question/presentation/widgets/vote_widget.dart'; // <-- ADD THIS IMPORT

class AnswerCard extends StatelessWidget {
  final AnswerModel answer;

  const AnswerCard({super.key, required this.answer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isAccepted = answer.isAcceptedAnswer;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAccepted ? theme.colorScheme.secondary.withOpacity(0.1) : theme.primaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: isAccepted ? Border.all(color: theme.colorScheme.secondary, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(answer.author.profileImageUrl),
                radius: 16,
              ),
              const SizedBox(width: 10),
              Text(
                answer.author.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isAccepted)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
            ],
          ),
          const Divider(height: 24),
          Text(
            answer.body,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 16),
          // FIX: Replace the old Row with our new, functional VoteWidget.
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              VoteWidget(initialVoteCount: answer.votes),
            ],
          )
        ],
      ),
    );
  }
}
