// lib/features/question/presentation/widgets/vote_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/features/question/presentation/cubit/vote_cubit.dart';
import 'package:devoverflow/features/question/presentation/cubit/vote_state.dart';

class VoteWidget extends StatelessWidget {
  final int initialVoteCount;
  final String answerId;

  const VoteWidget({
    super.key,
    required this.initialVoteCount,
    required this.answerId,
  });

  @override
  Widget build(BuildContext context) {
    // Provide the VoteCubit specifically to this widget instance.
    return BlocProvider(
      create: (context) => VoteCubit(initialVoteCount, answerId: answerId),
      child: BlocBuilder<VoteCubit, VoteState>(
        builder: (context, state) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => context.read<VoteCubit>().upvote(),
                icon: const Icon(Icons.arrow_upward),
                color: Colors.white70,
              ),
              Text(
                '${state.voteCount}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => context.read<VoteCubit>().downvote(),
                icon: const Icon(Icons.arrow_downward),
                color: Colors.white70,
              ),
            ],
          );
        },
      ),
    );
  }
}
