// lib/features/friends/presentation/screens/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:devoverflow/features/friends/presentation/cubit/friends_cubit.dart';
import 'package:devoverflow/features/friends/presentation/cubit/friends_state.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FriendsCubit()..fetchAllUsers(),
      child: const FriendsView(),
    );
  }
}

class FriendsView extends StatelessWidget {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                context.read<FriendsCubit>().searchUsers(value);
              },
              decoration: const InputDecoration(
                hintText: 'Search by name or username...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<FriendsCubit, FriendsState>(
              builder: (context, state) {
                if (state is FriendsLoading || state is FriendsInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is FriendsError) {
                  return Center(child: Text(state.message));
                }
                if (state is FriendsLoaded) {
                  final users = state.filteredUsers;
                  if (users.isEmpty) {
                    return const Center(child: Text('No users found.'));
                  }
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isFriend = state.friendIds.contains(user.id);
                      // Don't show the current user in the list
                      if (user.id == 'u1') return const SizedBox.shrink();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user.profileImageUrl),
                        ),
                        title: Text(user.username),
                        subtitle: Text(user.email),
                        trailing: IconButton(
                          icon: isFriend
                              ? const Icon(Icons.person_remove,
                                  color: Colors.redAccent)
                              : const Icon(Icons.person_add,
                                  color: Colors.green),
                          onPressed: () {
                            if (isFriend) {
                              context
                                  .read<FriendsCubit>()
                                  .removeFriend(user.id);
                            } else {
                              context.read<FriendsCubit>().addFriend(user.id);
                            }
                          },
                          tooltip: isFriend ? 'Remove Friend' : 'Add Friend',
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
