// lib/features/profile/presentation/cubit/profile_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/core/services/api_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ApiService _apiService = ApiService();

  // Expose apiService for image upload
  ApiService get apiService => _apiService;

  ProfileCubit() : super(ProfileInitial());

  Future<void> loadUserProfile() async {
    try {
      emit(ProfileLoading());
      // Fetch the current user's profile from your live backend.
      final user = await _apiService.getMyProfile();
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> updateUserProfile({
    String? bio,
    String? location,
    String? website,
    String? imageUrl,
  }) async {
    try {
      // We only emit loading if the state is already loaded to avoid UI jumps
      if (state is ProfileLoaded) {
        emit(ProfileLoading());
      }

      // Call the API to update the profile
      await _apiService.updateMyProfile(
        bio: bio,
        location: location,
        website: website,
        imageUrl: imageUrl,
      );

      emit(const ProfileUpdateSuccess('Profile updated successfully!'));
      // Reload the profile to show the new data.
      await loadUserProfile();
    } catch (e) {
      emit(ProfileError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
