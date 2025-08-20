// lib/features/profile/presentation/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:devoverflow/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:devoverflow/features/profile/presentation/cubit/profile_state.dart';
import 'package:devoverflow/common/widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    final profileCubit = context.read<ProfileCubit>();
    if (profileCubit.state is ProfileLoaded) {
      final user = (profileCubit.state as ProfileLoaded).user;
      _bioController = TextEditingController(text: user.bio);
      _locationController = TextEditingController(text: user.location);
      _websiteController = TextEditingController(text: user.website);
    } else {
      _bioController = TextEditingController();
      _locationController = TextEditingController();
      _websiteController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _onSaveChanges() {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileCubit>().updateUserProfile(
        bio: _bioController.text,
        location: _locationController.text,
        website: _websiteController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
            context.pop();
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is! ProfileLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileImage(state.user.profileImageUrl),
                  const SizedBox(height: 30),
                  TextFormField(controller: _bioController, decoration: const InputDecoration(labelText: 'Your Bio'), maxLines: 3),
                  const SizedBox(height: 20),
                  TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location')),
                  const SizedBox(height: 20),
                  TextFormField(controller: _websiteController, decoration: const InputDecoration(labelText: 'Website URL')),
                  const SizedBox(height: 40),
                  PrimaryButton(
                    text: 'Save Changes',
                    isLoading: state is ProfileLoading,
                    onPressed: _onSaveChanges,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileImage(String imageUrl) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage(imageUrl),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.black, size: 20),
              onPressed: () {
                // Your file upload logic would go here
              },
            ),
          ),
        ),
      ],
    );
  }
}
