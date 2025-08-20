// lib/features/question/presentation/cubit/question_details_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/core/services/api_service.dart';
import 'package:devoverflow/common/models/answer_model.dart';
import 'package:devoverflow/common/models/question_model.dart';
import 'question_details_state.dart';

class QuestionDetailsCubit extends Cubit<QuestionDetailsState> {
  final ApiService _apiService = ApiService();

  QuestionDetailsCubit() : super(QuestionDetailsInitial());

  Future<void> fetchQuestionDetails(String questionId) async {
    try {
      emit(QuestionDetailsLoading());

      // Fetch both the question and its answers from your live backend in parallel.
      final futureQuestion = _apiService.getQuestionById(questionId);
      final futureAnswers = _apiService.getAnswersForQuestion(questionId);

      // Wait for both API calls to complete.
      final results = await Future.wait([futureQuestion, futureAnswers]);

      final question = results[0] as Question;
      final answers = results[1] as List<AnswerModel>;

      emit(QuestionDetailsLoaded(question: question, answers: answers));
    } catch (e) {
      emit(QuestionDetailsError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

// The logic for accepting an answer will be added here in a future step
// once the voting and user roles are fully connected to the backend.
}
