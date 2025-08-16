// lib/features/splash/presentation/cubit/splash_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> checkAuthentication() async {
    // This is where you would check for a user token, e.g., from SharedPreferences
    // or FlutterSecureStorage. We'll simulate this with a delay.
    await Future.delayed(const Duration(seconds: 3));

    // For demonstration, let's assume the user is not logged in.
    // In your real app, you'd have a condition like:
    // final bool hasToken = await authService.hasToken();
    // if (hasToken) {
    //   emit(SplashAuthenticated());
    // } else {
    //   emit(SplashUnauthenticated());
    // }

    // For now, we will always go to the unauthenticated route.
    emit(SplashUnauthenticated());
  }
}