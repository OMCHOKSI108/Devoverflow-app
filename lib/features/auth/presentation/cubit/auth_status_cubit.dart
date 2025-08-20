// lib/features/auth/presentation/cubit/auth_status_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthStatus { unknown, authenticated, unverified, guest }

class AuthStatusCubit extends Cubit<AuthStatus> {
  AuthStatusCubit() : super(AuthStatus.unknown);

  void setAuthenticated() => emit(AuthStatus.authenticated);
  void setUnverified() => emit(AuthStatus.unverified);
  void setGuest() => emit(AuthStatus.guest);
  void setUnknown() => emit(AuthStatus.unknown);
}
