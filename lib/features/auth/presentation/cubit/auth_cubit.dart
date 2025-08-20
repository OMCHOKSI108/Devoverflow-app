// lib/features/auth/presentation/cubit/auth_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/core/services/api_service.dart';
import 'auth_state.dart';
import 'auth_status_cubit.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthStatusCubit authStatusCubit;
  final ApiService _apiService = ApiService();

  AuthCubit({required this.authStatusCubit}) : super(AuthInitial());

  Future<void> forgotPassword(String email) async {
    try {
      emit(AuthLoading());
      await _apiService.forgotPassword(email: email);
      emit(AuthVerificationSent(
        email,
        message: 'Password reset instructions have been sent to your email',
      ));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> login(String email, String password) async {
    try {
      emit(AuthLoading());
      // Call the real API service to validate credentials.
      await _apiService.login(email: email, password: password);

      // ApiService.login sets its internal token on success; mark the app authenticated.
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
      // Call backend register endpoint
      final result = await _apiService.register(
          username: username, email: email, password: password);

      // Check if verification is required
      if (result['verificationRequired'] == true) {
        emit(AuthVerificationSent(result['email'],
            message: result['message'] ??
                'Please check your email to verify your account'));
        return;
      }

      // If no verification needed, check for token
      final token = result['token'] ??
          result['data']?['token'] ??
          result['data']?['accessToken'];
      if (token is String && token.isNotEmpty) {
        authStatusCubit.setAuthenticated();
        emit(AuthSuccess());
      } else {
        // Fallback to verification message if no token
        emit(AuthVerificationSent(email,
            message: 'Please check your email to complete registration'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void signOut() {
    // Reset the global authentication status to guest.
    authStatusCubit.setGuest();
    // Emit a success state to trigger navigation back to the welcome screen.
    emit(AuthSuccess());
  }
}
