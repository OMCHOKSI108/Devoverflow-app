// lib/features/auth/presentation/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_form_field.dart';
import '../../../../common/widgets/primary_button.dart';

// The screen is now a simple StatelessWidget that displays the SignUpView.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // It no longer needs to provide its own BlocProvider.
    return const SignUpView();
  }
}

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;

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
      context.read<AuthCubit>().signUp(
            name: _nameController.text,
            username: _usernameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This BlocListener handles navigation to the verification screen upon success.
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthVerificationSent) {
          context.go('/verification', extra: {
            'email': state.email,
            'message': state.message,
          });
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
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
                        // const constructor to satisfy prefer_const_constructors lint
                        color: const Color.fromRGBO(255, 255, 255, 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            // 0.2 * 255 = 51
                            Border.all(
                                color: Colors.white.withValues(alpha: 51)),
                      ),
                      child: _buildSignUpForm(),
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

  Widget _buildSignUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Create Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          AuthFormField(
              controller: _nameController,
              labelText: 'Name',
              icon: Icons.person_outline),
          const SizedBox(height: 20),
          AuthFormField(
              controller: _usernameController,
              labelText: 'Username',
              icon: Icons.person_pin_outlined),
          const SizedBox(height: 20),
          AuthFormField(
              controller: _emailController,
              labelText: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          AuthFormField(
              controller: _passwordController,
              labelText: 'Password',
              icon: Icons.lock_outline,
              obscureText: !_isPasswordVisible,
              suffixIcon: _buildPasswordVisibilityToggle(),
              validator: (v) => v == null || v.length < 6
                  ? 'Password must be at least 6 characters'
                  : null),
          const SizedBox(height: 20),
          AuthFormField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (v) => v != _passwordController.text
                  ? 'Passwords do not match'
                  : null),
          const SizedBox(height: 40),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return PrimaryButton(
                text: 'Sign Up',
                isLoading: state is AuthLoading,
                onPressed: _handleSignUp,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordVisibilityToggle() {
    return IconButton(
      icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          color: Colors.white70),
      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
    );
  }
}
