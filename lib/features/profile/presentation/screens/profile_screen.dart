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
    // Load the user profile when the screen is first initialized if the user is authenticated.
    final authState = context.read<AuthStatusCubit>().state;
    if (authState == AuthStatus.authenticated) {
      // We check the state to avoid reloading the profile unnecessarily on tab switches.
      if (context.read<ProfileCubit>().state is ProfileInitial) {
        context.read<ProfileCubit>().loadUserProfile();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
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
                // Show a loader while the profile is being fetched from the API.
                return const Center(child: CircularProgressIndicator());
              },
            );
          }
          // If the user is a guest, show the guest view.
          return const GuestProfileView();
        },
      ),
    );
  }
}

class _AuthenticatedProfileView extends StatefulWidget {
  final UserModel user;
  const _AuthenticatedProfileView({required this.user});

  @override
  State<_AuthenticatedProfileView> createState() =>
      _AuthenticatedProfileViewState();
}

class _AuthenticatedProfileViewState extends State<_AuthenticatedProfileView> {
  Future<void> _showUpdateProfileDialog() async {
    final controller = TextEditingController();
    final bool? shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.image_outlined, color: Colors.blue),
              SizedBox(width: 8),
              Text('Update Profile Picture'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StepRow(
                  stepNumber: '1',
                  text: 'Upload your image to imgur.com',
                ),
                const SizedBox(height: 16),
                const _StepRow(
                  stepNumber: '2',
                  text: 'Copy the direct image link',
                ),
                const SizedBox(height: 16),
                const _StepRow(
                  stepNumber: '3',
                  text: 'Paste the link below',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'https://i.imgur.com/example.jpg',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.link),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Make sure the URL ends with .jpg, .png, or .gif',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(dialogContext, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please enter a valid URL')));
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (shouldUpdate == true && controller.text.isNotEmpty) {
      await _handleUpdateProfile(controller.text);
    }
  }

  Future<void> _handleUpdateProfile(String url) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updating profile picture...')));
      await context.read<ProfileCubit>().updateUserProfile(imageUrl: url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile picture updated successfully!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showUpdateProfileDialog,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(widget.user.profileImageUrl),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.edit, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.user.username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.user.email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              widget.user.bio ?? 'No bio available.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const Divider(height: 40),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Edit Profile',
                    onPressed: () => context.push('/edit-profile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => context.push('/friends'),
                    icon: const Icon(Icons.people_outline),
                    label: const Text('View Friends'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String stepNumber;
  final String text;

  const _StepRow({
    required this.stepNumber,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
