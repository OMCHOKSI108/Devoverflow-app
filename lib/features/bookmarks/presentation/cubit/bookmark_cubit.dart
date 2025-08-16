// lib/features/bookmarks/presentation/cubit/bookmark_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/common/models/question_model.dart';
import 'bookmark_state.dart';

class BookmarkCubit extends Cubit<BookmarkState> {
  BookmarkCubit() : super(const BookmarksLoaded(bookmarkedQuestions: [], bookmarkedIds: {}));

  // In a real app, you would fetch these from a database.
  final List<Question> _allQuestions = [
    Question(id: '1', title: 'How to manage state in a large Flutter application?', author: 'Jane Doe', authorImageUrl: 'https://i.pravatar.cc/150?u=jane_doe', votes: 125, answers: 12, tags: ['flutter', 'state-management', 'provider'], timestamp: DateTime.now().subtract(const Duration(hours: 2))),
    Question(id: '2', title: 'What is the best way to handle API calls with error handling in Dart?', author: 'John Smith', authorImageUrl: 'https://i.pravatar.cc/150?u=john_smith', votes: 98, answers: 8, tags: ['dart', 'api', 'http'], timestamp: DateTime.now().subtract(const Duration(days: 1))),
    Question(id: '3', title: 'How to implement a clean architecture in Node.js?', author: 'Alex Johnson', authorImageUrl: 'https://i.pravatar.cc/150?u=alex_johnson', votes: 210, answers: 15, tags: ['node.js', 'architecture', 'backend'], timestamp: DateTime.now().subtract(const Duration(days: 3))),
  ];

  void toggleBookmark(String questionId) {
    if (state is BookmarksLoaded) {
      final currentState = state as BookmarksLoaded;
      final currentIds = Set<String>.from(currentState.bookmarkedIds);

      if (currentIds.contains(questionId)) {
        currentIds.remove(questionId);
      } else {
        currentIds.add(questionId);
      }

      final bookmarkedQuestions = _allQuestions
          .where((q) => currentIds.contains(q.id))
          .toList();

      emit(BookmarksLoaded(
        bookmarkedQuestions: bookmarkedQuestions,
        bookmarkedIds: currentIds,
      ));
    }
  }
}
