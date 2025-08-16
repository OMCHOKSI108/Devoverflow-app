// lib/features/question/presentation/cubit/vote_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'vote_state.dart';

class VoteCubit extends Cubit<VoteState> {
  VoteCubit(int initialVotes) : super(VoteInitial(initialVotes));

  void upvote() {
    emit(VoteInitial(state.voteCount + 1));
  }

  void downvote() {
    emit(VoteInitial(state.voteCount - 1));
  }
}
