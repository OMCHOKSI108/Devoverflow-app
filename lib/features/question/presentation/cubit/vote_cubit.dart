// lib/features/question/presentation/cubit/vote_cubit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/core/services/api_service.dart';
import 'vote_state.dart';

class VoteCubit extends Cubit<VoteState> {
  final ApiService _apiService = ApiService();
  final String answerId;

  VoteCubit(int initialVotes, {required this.answerId})
      : super(VoteInitial(initialVotes));

  Future<void> upvote() async {
    try {
      // Optimistically update the UI first for a faster user experience.
      final currentVotes = state.voteCount;
      emit(VoteInitial(currentVotes + 1));
      // Then, make the API call.
      await _apiService.voteOnAnswer(answerId, 'up');
    } catch (e) {
      // If the API call fails, revert the vote count and handle the error.
      emit(VoteInitial(state.voteCount - 1));
      // Optionally, you can show a snackbar or error message here.
      debugPrint('Upvote failed: $e');
    }
  }

  Future<void> downvote() async {
    try {
      final currentVotes = state.voteCount;
      emit(VoteInitial(currentVotes - 1));
      await _apiService.voteOnAnswer(answerId, 'down');
    } catch (e) {
      emit(VoteInitial(state.voteCount + 1));
      debugPrint('Downvote failed: $e');
    }
  }
}
