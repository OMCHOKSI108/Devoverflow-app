// lib/features/auth/presentation/cubit/auth_state.dart
import 'package:equatable/equatable.dart';

// The abstract class that all our states will extend
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

// The initial state, when nothing has happened yet
class AuthInitial extends AuthState {}

// The state when we are actively trying to log in (e.g., show a loading spinner)
class AuthLoading extends AuthState {}

// The state when login is successful
class AuthSuccess extends AuthState {}

// The state when login fails, carrying an error message
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object> get props => [message];
}

class AuthVerificationSent extends AuthState {
  final String email;

  const AuthVerificationSent(this.email);

  @override
  List<Object> get props => [email];
}
