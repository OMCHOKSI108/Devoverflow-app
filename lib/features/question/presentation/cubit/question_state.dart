// lib/features/question/presentation/cubit/question_state.dart
import 'package:equatable/equatable.dart';

abstract class QuestionState extends Equatable {
  const QuestionState();

  @override
  List<Object> get props => [];
}

class QuestionInitial extends QuestionState {}

class QuestionSubmitting extends QuestionState {}

class QuestionSubmitSuccess extends QuestionState {}

class QuestionSubmitError extends QuestionState {
  final String message;

  const QuestionSubmitError(this.message);

  @override
  List<Object> get props => [message];
}