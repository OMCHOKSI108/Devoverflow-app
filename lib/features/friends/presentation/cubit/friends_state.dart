// lib/features/friends/presentation/cubit/friends_state.dart
import 'package:equatable/equatable.dart';
import 'package:devoverflow/common/models/user_model.dart';

abstract class FriendsState extends Equatable {
  const FriendsState();

  @override
  List<Object> get props => [];
}

class FriendsInitial extends FriendsState {}

class FriendsLoading extends FriendsState {}

class FriendsLoaded extends FriendsState {
  final List<UserModel> allUsers;
  final Set<String> friendIds;
  final String searchTerm;

  const FriendsLoaded({
    required this.allUsers,
    required this.friendIds,
    this.searchTerm = '',
  });

  List<UserModel> get filteredUsers {
    if (searchTerm.isEmpty) {
      return allUsers;
    }
    return allUsers
        .where((user) =>
            user.username.toLowerCase().contains(searchTerm.toLowerCase()) ||
            user.username.toLowerCase().contains(searchTerm.toLowerCase()))
        .toList();
  }

  @override
  List<Object> get props => [allUsers, friendIds, searchTerm];
}

class FriendsError extends FriendsState {
  final String message;

  const FriendsError(this.message);

  @override
  List<Object> get props => [message];
}
