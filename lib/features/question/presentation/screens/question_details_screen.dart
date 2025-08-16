// lib/features/question/presentation/screens/question_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:devoverflow/features/question/presentation/cubit/question_details_cubit.dart';
import 'package:devoverflow/features/question/presentation/cubit/question_details_state.dart';
import 'package:devoverflow/features/question/presentation/widgets/answer_card.dart';
import 'package:devoverflow/features/home/presentation/widgets/question_card.dart';

class QuestionDetailsScreen extends StatelessWidget {
  final String questionId;

  const QuestionDetailsScreen({
    super.key,
    required this.questionId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuestionDetailsCubit()..fetchQuestionDetails(questionId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Question'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<QuestionDetailsCubit, QuestionDetailsState>(
          builder: (context, state) {
            if (state is QuestionDetailsLoading || state is QuestionDetailsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is QuestionDetailsError) {
              return Center(child: Text(state.message));
            }
            if (state is QuestionDetailsLoaded) {
              return ListView.builder(
                itemCount: state.answers.length + 1, // +1 for the question header
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // The first item in the list is the question itself.
                    return QuestionCard(question: state.question);
                  }
                  // The rest of the items are the answers.
                  final answer = state.answers[index - 1];
                  return AnswerCard(answer: answer);
                },
              );
            }
            return const SizedBox.shrink(); // Fallback for any other state
          },
        ),
      ),
    );
  }
}
