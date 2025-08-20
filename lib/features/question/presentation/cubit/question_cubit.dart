// lib/features/question/presentation/cubit/question_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/core/services/api_service.dart';
import 'package:devoverflow/features/home/presentation/cubit/home_cubit.dart';
import 'question_state.dart';

class QuestionCubit extends Cubit<QuestionState> {
  final ApiService _apiService = ApiService();

  final HomeCubit homeCubit;

  QuestionCubit({
    required this.homeCubit,
  }) : super(QuestionInitial());

  Future<void> submitQuestion({
    required String title,
    required String body,
    required String tags,
  }) async {
    try {
      emit(QuestionSubmitting());

      // Post the new question to your live backend.
      await _apiService.createQuestion(
        title: title,
        body: body,
        tags: tags.split(',').map((t) => t.trim()).toList(),
      );

      // Refresh questions list in home screen
      await homeCubit.fetchQuestions();
      emit(QuestionSubmitSuccess());
    } catch (e) {
      emit(QuestionSubmitError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
