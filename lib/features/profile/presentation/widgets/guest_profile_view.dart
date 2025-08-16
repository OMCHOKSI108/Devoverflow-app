// lib/features/profile/presentation/widgets/guest_profile_view.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:devoverflow/common/widgets/primary_button.dart';

class GuestProfileView extends StatelessWidget {
  const GuestProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.person_off_outlined,
            size: 100,
            color: Colors.white54,
          ),
          const SizedBox(height: 20),
          const Text(
            'You are browsing as a guest',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create an account to save your progress, ask questions, and view your profile.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          PrimaryButton(
            text: 'Sign Up or Login',
            onPressed: () {
              // This will take the user to the welcome screen to start the auth flow
              context.go('/welcome');
            },
          ),
        ],
      ),
    );
  }
}
