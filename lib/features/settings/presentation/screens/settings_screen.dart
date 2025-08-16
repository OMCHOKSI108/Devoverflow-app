// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:devoverflow/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:devoverflow/features/settings/presentation/cubit/settings_state.dart';
import 'package:devoverflow/features/auth/presentation/cubit/auth_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              // --- Appearance Section ---
              _buildSectionHeader(context, 'Appearance'),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Enable to switch to the dark theme'),
                value: state.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  context.read<SettingsCubit>().toggleTheme();
                },
              ),

              // --- Account Section ---
              _buildSectionHeader(context, 'Account'),
              _buildListTile(
                context,
                icon: Icons.logout,
                title: 'Sign Out',
                onTap: () {
                  // Call the sign out method from the global AuthCubit
                  context.read<AuthCubit>().signOut();
                },
              ),

              // --- Danger Zone ---
              _buildSectionHeader(context, 'Danger Zone'),
              _buildListTile(
                context,
                icon: Icons.delete_forever,
                title: 'Delete Account',
                color: Theme.of(context).colorScheme.error,
                onTap: () {
                  _showDeleteConfirmationDialog(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper widget for section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Helper widget for list tiles
  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    final tileColor = color ?? Theme.of(context).colorScheme.onBackground;
    return ListTile(
      leading: Icon(icon, color: tileColor),
      title: Text(title, style: TextStyle(color: tileColor)),
      onTap: onTap,
    );
  }

  // Helper function to show the confirmation dialog
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account?'),
          content: const Text('This action is permanent and cannot be undone. Are you sure you want to delete your account?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () {
                // In a real app, you would call a method in your AuthCubit here.
                // For now, we just print a message and close the dialog.
                print('Account deletion initiated.');
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
