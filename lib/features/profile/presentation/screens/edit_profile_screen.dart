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
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final profileCubit = context.read<ProfileCubit>();
    if (profileCubit.state is ProfileLoaded) {
      final user = (profileCubit.state as ProfileLoaded).user;
      _nameController = TextEditingController(text: user.name);
      _emailController = TextEditingController(text: user.email);
      _mobileController = TextEditingController(text: user.mobileNumber);
      _bioController = TextEditingController(text: user.bio);
    } else {
      // Initialize with empty controllers if state is not loaded
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _mobileController = TextEditingController();
      _bioController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onSaveChanges() {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileCubit>().updateUserProfile(
        name: _nameController.text,
        email: _emailController.text,
        mobileNumber: _mobileController.text,
        bio: _bioController.text,
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
            context.pop(); // Go back to profile screen on success
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileImage(),
                  const SizedBox(height: 30),
                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                  const SizedBox(height: 20),
                  TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address')),
                  const SizedBox(height: 10),
                  const Text('Changing email will require re-verification.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 20),
                  TextFormField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile Number (Optional)')),
                  const SizedBox(height: 20),
                  TextFormField(controller: _bioController, decoration: const InputDecoration(labelText: 'Your Bio'), maxLines: 3),
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

  Widget _buildProfileImage() {
    return Stack(
      children: [
        const CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=current_user'),
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
                // Add logic to pick an image from the gallery
              },
            ),
          ),
        ),
      ],
    );
  }
}
