import 'package:devoverflow/login_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // Required for the blur effect

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;

  // New state to control which view is shown (form or verification message)
  bool _isVerificationSent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      // In a real app, you would call your backend API here.
      print('Signing up user: ${_emailController.text}');

      // Instead of navigating, we now just update the state to show the message.
      setState(() {
        _isVerificationSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // Added an AppBar for the back button
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    // Conditionally show the form or the verification message
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _isVerificationSent
                          ? _buildVerificationView()
                          : _buildSignUpForm(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // The original sign-up form is now its own widget
  Widget _buildSignUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Create Account', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildTextFormField(controller: _nameController, labelText: 'Name', icon: Icons.person_outline),
          const SizedBox(height: 20),
          _buildTextFormField(controller: _usernameController, labelText: 'Username', icon: Icons.person_pin_outlined),
          const SizedBox(height: 20),
          _buildTextFormField(controller: _emailController, labelText: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          _buildTextFormField(controller: _passwordController, labelText: 'Password', icon: Icons.lock_outline, obscureText: !_isPasswordVisible, suffixIcon: _buildPasswordVisibilityToggle(), validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null),
          const SizedBox(height: 20),
          _buildTextFormField(controller: _confirmPasswordController, labelText: 'Confirm Password', icon: Icons.lock_outline, obscureText: true, validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: _handleSignUp, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF2C94C), foregroundColor: const Color(0xFF2C3E50), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // The new view to show after the form is submitted
  Widget _buildVerificationView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 80),
        const SizedBox(height: 20),
        const Text('Verify Your Email', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Text('A verification link has been sent to:\n${_emailController.text}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF2C94C), foregroundColor: const Color(0xFF2C3E50), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
          child: const Text('Back to Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPasswordVisibilityToggle() {
    return IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white70), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible));
  }

  Widget _buildTextFormField({required TextEditingController controller, required String labelText, required IconData icon, TextInputType keyboardType = TextInputType.text, bool obscureText = false, Widget? suffixIcon, String? Function(String?)? validator}) {
    return TextFormField(controller: controller, keyboardType: keyboardType, obscureText: obscureText, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: labelText, labelStyle: const TextStyle(color: Colors.white70), prefixIcon: Icon(icon, color: Colors.white70), suffixIcon: suffixIcon, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white38)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF2C94C))), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)), focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2))), validator: validator ?? (v) => v == null || v.isEmpty ? 'Please enter your $labelText' : null);
  }
}
