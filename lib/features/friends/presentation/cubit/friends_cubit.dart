// lib/features/friends/presentation/cubit/friends_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/common/models/user_model.dart';
import 'friends_state.dart';

class FriendsCubit extends Cubit<FriendsState> {
  FriendsCubit() : super(FriendsInitial());

  final String _currentUserId = 'u1';

  late List<UserModel> _allUsers;
  late Set<String> _friendIds;

  Future<void> fetchAllUsers() async {
    try {
      emit(FriendsLoading());
      await Future.delayed(const Duration(milliseconds: 800));
      _allUsers = _getMockUsers();

      final currentUser = _allUsers.firstWhere((user) => user.id == _currentUserId);
      _friendIds = Set<String>.from(currentUser.friendIds);

      emit(FriendsLoaded(allUsers: _allUsers, friendIds: _friendIds));
    } catch (e) {
      emit(const FriendsError('Failed to load users.'));
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

  void addFriend(String userId) {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      final updatedFriendIds = Set<String>.from(currentState.friendIds)..add(userId);
      _friendIds = updatedFriendIds;
      emit(FriendsLoaded(
        allUsers: currentState.allUsers,
        friendIds: updatedFriendIds,
        searchTerm: currentState.searchTerm,
      ));
    }
  }

  void removeFriend(String userId) {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      final updatedFriendIds = Set<String>.from(currentState.friendIds)..remove(userId);
      _friendIds = updatedFriendIds;
      emit(FriendsLoaded(
        allUsers: currentState.allUsers,
        friendIds: updatedFriendIds,
        searchTerm: currentState.searchTerm,
      ));
    }
  }

  List<UserModel> _getMockUsers() {
    return [
      UserModel(id: 'u1', name: 'Current User', username: 'current_user', email: '', profileImageUrl: 'https://i.pravatar.cc/150?u=current_user', friendIds: ['u2']),
      UserModel(id: 'u2', name: 'Jane Doe', username: 'jane_doe', email: '', profileImageUrl: 'https://i.pravatar.cc/150?u=jane_doe'),
      UserModel(id: 'u3', name: 'John Smith', username: 'john_smith', email: '', profileImageUrl: 'https://i.pravatar.cc/150?u=john_smith'),
      UserModel(id: 'u4', name: 'Alex Johnson', username: 'alex_j', email: '', profileImageUrl: 'https://i.pravatar.cc/150?u=alex_johnson'),
      UserModel(id: 'u5', name: 'Peter Jones', username: 'peterj', email: '', profileImageUrl: 'https://i.pravatar.cc/150?u=peter_jones'),
      UserModel(id: 'u6', name: 'Sarah Lynn', username: 'sarahl', email: '', profileImageUrl: 'https://i.pravatar.cc/150?u=sarah_lynn'),
    ];
  }
}
