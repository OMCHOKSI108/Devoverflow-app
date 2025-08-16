// lib/features/question/presentation/cubit/question_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/common/models/question_model.dart';
import 'package:devoverflow/features/home/presentation/cubit/home_cubit.dart';
import 'question_state.dart';

class QuestionCubit extends Cubit<QuestionState> {
  final HomeCubit homeCubit;

  QuestionCubit({required this.homeCubit}) : super(QuestionInitial());

  Future<void> submitQuestion({
    required String title,
    required String body,
    required String tags,
  }) async {
    try {
      emit(QuestionSubmitting());
      await Future.delayed(const Duration(seconds: 1));

      final newQuestion = Question(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        author: 'Current User',
        authorImageUrl: 'https://i.pravatar.cc/150?u=current_user',
        votes: 0,
        answers: 0,
        tags: tags.split(',').map((t) => t.trim()).toList(),
        timestamp: DateTime.now(),
      );

      homeCubit.addQuestion(newQuestion);
      emit(QuestionSubmitSuccess());
    } catch (e) {
      emit(const QuestionSubmitError('Failed to submit question.'));
    }
  }
}
