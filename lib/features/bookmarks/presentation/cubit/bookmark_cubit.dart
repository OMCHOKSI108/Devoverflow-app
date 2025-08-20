// lib/features/bookmarks/presentation/cubit/bookmark_cubit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/core/services/api_service.dart';
import 'bookmark_state.dart';

class BookmarkCubit extends Cubit<BookmarkState> {
  final ApiService _apiService = ApiService();

  BookmarkCubit() : super(BookmarksLoading());

  Future<void> fetchBookmarks() async {
    try {
      emit(BookmarksLoading());
      final questions = await _apiService.getBookmarks();
      final ids = questions.map((q) => q.id).toSet();
      emit(BookmarksLoaded(bookmarkedQuestions: questions, bookmarkedIds: ids));
    } catch (e) {
      debugPrint('Failed to fetch bookmarks: $e');
      // Emit a loaded state with empty lists on failure.
      emit(const BookmarksLoaded(bookmarkedQuestions: [], bookmarkedIds: {}));
    }
  }

  Future<void> toggleBookmark(String questionId) async {
    final currentState = state;
    if (currentState is BookmarksLoaded) {
      final currentIds = Set<String>.from(currentState.bookmarkedIds);
      try {
        if (currentIds.contains(questionId)) {
          await _apiService.removeBookmark(questionId);
        } else {
          await _apiService.addBookmark(questionId);
        }
        // After toggling, refresh the list of bookmarks to show the change.
        await fetchBookmarks();
      } catch (e) {
        // Handle the error, e.g., by showing a snackbar to the user.
        debugPrint('Failed to toggle bookmark: $e');
      }
    }
  }
}
