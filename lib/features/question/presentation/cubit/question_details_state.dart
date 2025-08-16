// lib/features/question/presentation/cubit/question_details_state.dart
import 'package:equatable/equatable.dart';
import 'package:devoverflow/common/models/question_model.dart';
import 'package:devoverflow/common/models/answer_model.dart';

// The abstract class must be defined before the classes that extend it.
abstract class QuestionDetailsState extends Equatable {
  const QuestionDetailsState();

  @override
  List<Object> get props => [];
}

class QuestionDetailsInitial extends QuestionDetailsState {}

class QuestionDetailsLoading extends QuestionDetailsState {}

class QuestionDetailsLoaded extends QuestionDetailsState {
  final Question question;
  final List<AnswerModel> answers;

  const QuestionDetailsLoaded({required this.question, required this.answers});

  @override
  List<Object> get props => [question, answers];
}

class QuestionDetailsError extends QuestionDetailsState {
  final String message;

  const QuestionDetailsError(this.message);

  @override
  List<Object> get props => [message];
}
