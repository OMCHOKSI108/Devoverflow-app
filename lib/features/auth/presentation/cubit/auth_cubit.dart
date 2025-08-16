// lib/features/auth/presentation/cubit/auth_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';
import 'auth_status_cubit.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthStatusCubit authStatusCubit;

  AuthCubit({required this.authStatusCubit}) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    try {
      emit(AuthLoading());
      // Simulate a network call
      await Future.delayed(const Duration(seconds: 1));

      // On success, update the global auth status
      authStatusCubit.setAuthenticated();

      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      // Simulate a network call
      await Future.delayed(const Duration(seconds: 1));
      emit(AuthVerificationSent(email));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  void signOut() {
    // Reset the global authentication status to guest.
    authStatusCubit.setGuest();
    // Emit a success state to trigger navigation back to the welcome screen.
    emit(AuthSuccess());
  }
}
