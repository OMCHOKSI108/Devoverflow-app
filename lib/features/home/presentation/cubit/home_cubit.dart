// lib/features/home/presentation/cubit/home_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/common/models/question_model.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  // The list of questions is now managed inside the cubit
  List<Question> _questions = [
    Question(id: '1', title: 'How to manage state in a large Flutter application?', author: 'Jane Doe', authorImageUrl: 'https://i.pravatar.cc/150?u=jane_doe', votes: 125, answers: 12, tags: ['flutter', 'state-management', 'provider'], timestamp: DateTime.now().subtract(const Duration(hours: 2))),
    Question(id: '2', title: 'What is the best way to handle API calls with error handling in Dart?', author: 'John Smith', authorImageUrl: 'https://i.pravatar.cc/150?u=john_smith', votes: 98, answers: 8, tags: ['dart', 'api', 'http'], timestamp: DateTime.now().subtract(const Duration(days: 1))),
    Question(id: '3', title: 'How to implement a clean architecture in Node.js?', author: 'Alex Johnson', authorImageUrl: 'https://i.pravatar.cc/150?u=alex_johnson', votes: 210, answers: 15, tags: ['node.js', 'architecture', 'backend'], timestamp: DateTime.now().subtract(const Duration(days: 3))),
  ];

  Future<void> fetchQuestions() async {
    try {
      emit(HomeLoading());
      await Future.delayed(const Duration(milliseconds: 1500));
      emit(HomeLoaded(_questions));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  // NEW: Method to add a question to the list
  void addQuestion(Question newQuestion) {
    // Add the new question to the top of the list
    _questions.insert(0, newQuestion);
    // Emit a new state with the updated list
    emit(HomeLoaded(List.from(_questions)));
  }
}
