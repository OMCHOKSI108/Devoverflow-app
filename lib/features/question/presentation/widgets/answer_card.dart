// lib/features/question/presentation/widgets/answer_card.dart
import 'package:flutter/material.dart';
import 'package:devoverflow/common/models/answer_model.dart';
import 'package:devoverflow/features/question/presentation/widgets/vote_widget.dart';

class AnswerCard extends StatelessWidget {
  final AnswerModel answer;
  final bool isQuestionAuthor;
  final VoidCallback onAccept;

  const AnswerCard({
    super.key,
    required this.answer,
    required this.isQuestionAuthor,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isAccepted = answer.isAcceptedAnswer;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Use theme colors for the card background
        color: isAccepted
            ? theme.colorScheme.secondary.withValues(alpha: 26)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isAccepted
            ? Border.all(color: theme.colorScheme.secondary, width: 2)
            : Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(answer.authorImageUrl),
                radius: 16,
              ),
              const SizedBox(width: 10),
              Text(
                answer.authorName,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Conditionally show the "Accept Answer" button
              if (isQuestionAuthor && !isAccepted)
                TextButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check, color: Colors.green),
                  label: const Text('Accept',
                      style: TextStyle(color: Colors.green)),
                ),
              const Spacer(),
              VoteWidget(
                initialVoteCount: answer.votes,
                answerId: answer.id,
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          // In the future, you would load real comments here.
          // For now, we show a placeholder.
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 153), // 0.6 * 255 ≈ 153
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
