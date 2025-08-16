// lib/features/home/presentation/cubit/home_state.dart
import 'package:equatable/equatable.dart';
import 'package:devoverflow/common/models/question_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final List<Question> questions;

  const HomeLoaded(this.questions);

  @override
  List<Object> get props => [questions];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}