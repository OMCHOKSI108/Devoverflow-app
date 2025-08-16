// lib/features/bookmarks/presentation/cubit/bookmark_state.dart
import 'package:equatable/equatable.dart';
import 'package:devoverflow/common/models/question_model.dart';

abstract class BookmarkState extends Equatable {
  const BookmarkState();

  @override
  List<Object> get props => [];
}

class BookmarksLoading extends BookmarkState {}

class BookmarksLoaded extends BookmarkState {
  final List<Question> bookmarkedQuestions;
  final Set<String> bookmarkedIds;

  const BookmarksLoaded({
    required this.bookmarkedQuestions,
    required this.bookmarkedIds,
  });

  @override
  List<Object> get props => [bookmarkedQuestions, bookmarkedIds];
}
