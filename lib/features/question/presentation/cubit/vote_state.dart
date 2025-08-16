// lib/features/question/presentation/cubit/vote_state.dart
import 'package:equatable/equatable.dart';

abstract class VoteState extends Equatable {
  final int voteCount;

  const VoteState(this.voteCount);

  @override
  List<Object> get props => [voteCount];
}

class VoteInitial extends VoteState {
  const VoteInitial(super.voteCount);
}
