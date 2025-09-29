import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    // Prefer API for current user profile
    try {
      final resp = await ApiService().getCurrentUser();
      final user = resp['user'] ?? {};
      if (user is Map && user.isNotEmpty) {
        _nameCtrl.text = user['name'] ?? '';
        _bioCtrl.text = user['bio'] ?? '';
        _phoneCtrl.text = user['phone'] ?? '';
        _imageBase64 =
            user['profile_image'] ?? prefs.getString('profile_image');
        if (mounted) setState(() {});
        return;
      }
    } catch (e) {
      // fallback to prefs
    }

    _nameCtrl.text = prefs.getString('name') ?? '';
    _bioCtrl.text = prefs.getString('bio') ?? '';
    _phoneCtrl.text = prefs.getString('phone') ?? '';
    _imageBase64 = prefs.getString('profile_image');
    if (mounted) setState(() {});
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    _imageBase64 = base64Encode(bytes);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();

    // Try to save to API first
    try {
      final response = await ApiService().put(
        ApiConfig.updateProfile,
        data: {
          'name': _nameCtrl.text.trim(),
          'bio': _bioCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
        },
      );

      if (response['success'] == true) {
        // API save successful, also save locally
        await prefs.setString('name', _nameCtrl.text.trim());
        await prefs.setString('bio', _bioCtrl.text.trim());
        await prefs.setString('phone', _phoneCtrl.text.trim());
        if (_imageBase64 != null) {
          await prefs.setString('profile_image', _imageBase64!);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
        return;
      }
    } catch (e) {
      // Fall back to local save
    }

    // Fallback: save locally only
    await prefs.setString('name', _nameCtrl.text.trim());
    await prefs.setString('bio', _bioCtrl.text.trim());
    await prefs.setString('phone', _phoneCtrl.text.trim());
    if (_imageBase64 != null) {
      await prefs.setString('profile_image', _imageBase64!);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved locally (offline mode)')),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatar;
    if (_imageBase64 != null) {
      avatar = MemoryImage(base64Decode(_imageBase64!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF667eea),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/change_password'),
            child: const Text(
              'Change Password',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: avatar,
                    child: _imageBase64 == null
                        ? const Icon(Icons.camera_alt, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioCtrl,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Mobile number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                    ),
                    child: const Text('Save Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
