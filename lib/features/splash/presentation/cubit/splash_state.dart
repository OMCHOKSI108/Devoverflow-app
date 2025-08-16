// lib/features/splash/presentation/cubit/splash_state.dart
import 'package:equatable/equatable.dart';

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object> get props => [];
}

class SplashInitial extends SplashState {}

// State when we determine the user is already logged in
class SplashAuthenticated extends SplashState {}

// State when we determine the user is NOT logged in
class SplashUnauthenticated extends SplashState {}