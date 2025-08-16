// lib/features/question/presentation/cubit/question_details_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/common/models/answer_model.dart';
import 'package:devoverflow/common/models/question_model.dart';
import 'package:devoverflow/common/models/user_model.dart';
import 'package:devoverflow/common/models/comment_model.dart';
import 'question_details_state.dart';

class QuestionDetailsCubit extends Cubit<QuestionDetailsState> {
  QuestionDetailsCubit() : super(QuestionDetailsInitial());

  Future<void> fetchQuestionDetails(String questionId) async {
    try {
      emit(QuestionDetailsLoading());
      await Future.delayed(const Duration(milliseconds: 800));

      final question = _getMockQuestion(questionId);
      final answers = _getMockAnswers(questionId);

      emit(QuestionDetailsLoaded(question: question, answers: answers));
    } catch (e) {
      emit(const QuestionDetailsError('Failed to load question details.'));
    }
  }

  Question _getMockQuestion(String id) {
    return Question(
      id: id,
      title: 'How to manage state in a large Flutter application?',
      author: 'Jane Doe',
      authorImageUrl: 'https://i.pravatar.cc/150?u=jane_doe',
      votes: 125,
      answers: 2,
      tags: ['flutter', 'state-management', 'provider'],
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  List<AnswerModel> _getMockAnswers(String questionId) {
    final user1 = UserModel(id: 'u1', name: 'Peter Jones', username: 'peterj', email: '', profileImageUrl: 'https://i.pravatar.cc/150?u=peter_jones');
    final user2 = UserModel(id: 'u2', name: 'Sarah Lynn', username: 'sarahl', email: '', profileImageUrl: 'https://i.pravatar.cc/150?u=sarah_lynn');
    final user3 = UserModel(id: 'u3', name: 'Current User', username: 'current_user', email: '', profileImageUrl: 'https://i.pravatar.cc/150?u=current_user');

    return [
      AnswerModel(
          id: 'a1',
          body: 'For large applications, I highly recommend using the BLoC library. It helps separate business logic from the UI and scales very well with complex features. Make sure to use the latest version with Cubit for simpler cases.',
          author: user1,
          votes: 45,
          isAcceptedAnswer: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 90)),
          comments: [
            CommentModel(id: 'c1', body: 'Great point! I agree completely.', author: user3, timestamp: DateTime.now().subtract(const Duration(minutes: 80)))
          ]
      ),
      AnswerModel(
          id: 'a2',
          body: 'While BLoC is great, don\'t overlook Riverpod. It offers compile-time safety and can be more flexible than Provider or BLoC in some scenarios. It has a slightly steeper learning curve but is very powerful.',
          author: user2,
          votes: 22,
          timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
          comments: []
      ),
    ];
  }
}
