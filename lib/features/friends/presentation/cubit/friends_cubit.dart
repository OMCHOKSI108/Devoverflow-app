// lib/features/friends/presentation/cubit/friends_cubit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/core/services/api_service.dart';
import 'package:devoverflow/common/models/user_model.dart';
import 'friends_state.dart';

class FriendsCubit extends Cubit<FriendsState> {
  final ApiService _apiService = ApiService();

  FriendsCubit() : super(FriendsInitial());

  Future<void> fetchAllUsers() async {
    try {
      emit(FriendsLoading());

      // Fetch all users and the current user's profile in parallel to get the friend list.
      final futureAllUsers = _apiService.searchUsers();
      final futureMyProfile = _apiService.getMyProfile();

      final results = await Future.wait([futureAllUsers, futureMyProfile]);

      final allUsers = results[0] as List<UserModel>;
      final myProfile = results[1] as UserModel;
      final friendIds = Set<String>.from(myProfile.friendIds);

      emit(FriendsLoaded(allUsers: allUsers, friendIds: friendIds));
    } catch (e) {
      emit(FriendsError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void searchUsers(String searchTerm) {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      emit(FriendsLoaded(
        allUsers: currentState.allUsers,
        friendIds: currentState.friendIds,
        searchTerm: searchTerm,
      ));
    }
  }

  Future<void> addFriend(String userId) async {
    try {
      await _apiService.addFriend(userId);
      // After adding a friend, refresh the user list to show the change.
      await fetchAllUsers();
    } catch (e) {
      // In a real app, you might want to show an error message.
      debugPrint('Failed to add friend: $e');
    }
  }

  Future<void> removeFriend(String userId) async {
    try {
      // Your API docs don't have an unfollow endpoint, so we use the placeholder.
      await _apiService.removeFriend(userId);
      // After removing a friend, refresh the user list.
      await fetchAllUsers();
    } catch (e) {
      debugPrint('Failed to remove friend: $e');
    }
  }
}
