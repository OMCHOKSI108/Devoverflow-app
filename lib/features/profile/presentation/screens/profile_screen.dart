// lib/features/profile/presentation/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:devoverflow/common/widgets/primary_button.dart';
import 'package:devoverflow/features/auth/presentation/cubit/auth_status_cubit.dart';
import 'package:devoverflow/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:devoverflow/features/profile/presentation/cubit/profile_state.dart';
import 'package:devoverflow/features/profile/presentation/widgets/guest_profile_view.dart';
import 'package:devoverflow/common/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    if (context.read<ProfileCubit>().state is ProfileInitial) {
      context.read<ProfileCubit>().loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          BlocBuilder<AuthStatusCubit, AuthStatus>(
            builder: (context, authState) {
              if (authState == AuthStatus.authenticated) {
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/edit-profile'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),

        ],
      ),
      body: BlocBuilder<AuthStatusCubit, AuthStatus>(
        builder: (context, authState) {
          if (authState == AuthStatus.authenticated) {
            return BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profileState) {
                if (profileState is ProfileLoaded) {
                  return _AuthenticatedProfileView(user: profileState.user);
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          }
          return const GuestProfileView();
        },
      ),
    );
  }
}

class _AuthenticatedProfileView extends StatelessWidget {
  final UserModel user;
  const _AuthenticatedProfileView({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(radius: 50, backgroundImage: NetworkImage(user.profileImageUrl)),
            const SizedBox(height: 20),
            Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('@${user.username}', style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 16),
            Text(user.bio ?? 'No bio available.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white70)),
            const Divider(height: 40),
            PrimaryButton(
              text: 'Edit Profile',
              onPressed: () => context.push('/edit-profile'),
            ),
            const SizedBox(height: 16),
            // The "View Friends" button is now correctly located here.
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () => context.push('/friends'),
              child: const Text('View Friends'),
            ),
          ],
        ),
      ),
    );
  }
}
