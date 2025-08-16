// lib/features/profile/presentation/cubit/profile_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/common/models/user_model.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());

  late UserModel _currentUser;

  Future<void> loadUserProfile() async {
    try {
      emit(ProfileLoading());
      // Simulate fetching user data from an API
      await Future.delayed(const Duration(milliseconds: 500));
      _currentUser = UserModel(
        id: 'u1',
        name: 'Current User',
        username: 'current_user',
        email: 'user@example.com',
        profileImageUrl: 'https://i.pravatar.cc/150?u=current_user',
        bio: 'Flutter enthusiast and coffee lover. Building cool things with code.',
      );
      emit(ProfileLoaded(_currentUser));
    } catch (e) {
      emit(const ProfileError('Failed to load profile.'));
    }
  }

  Future<void> updateUserProfile({
    required String name,
    required String email,
    String? mobileNumber,
    String? bio,
  }) async {
    try {
      emit(ProfileLoading());
      // Simulate saving data to the backend
      await Future.delayed(const Duration(seconds: 1));

      // In a real app, you would get the updated user object back from the API
      _currentUser = UserModel(
        id: _currentUser.id,
        name: name,
        username: _currentUser.username,
        email: email,
        profileImageUrl: _currentUser.profileImageUrl,
        bio: bio,
        mobileNumber: mobileNumber,
      );

      emit(const ProfileUpdateSuccess('Profile updated successfully!'));
      // After success, emit the loaded state again with the new data
      emit(ProfileLoaded(_currentUser));

    } catch (e) {
      emit(const ProfileError('Failed to update profile.'));
    }
  }
}
