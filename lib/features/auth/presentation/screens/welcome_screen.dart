// lib/features/auth/presentation/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:devoverflow/common/widgets/primary_button.dart';
import 'package:devoverflow/features/auth/presentation/cubit/auth_status_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  final String _fullWelcomeMessage = 'Welcome to DevOverflow';
  String _currentMessage = '';
  Timer? _typingTimer;
  Timer? _cursorTimer;
  bool _showCursor = true;

  late AnimationController _buttonAnimationController;
  late AnimationController _logoAnimationController;
  late Animation<double> _buttonFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;

  @override
  void initState() {
    super.initState();

    _startTypingAnimation();

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _showCursor = !_showCursor);
    });

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _buttonFadeAnimation = CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeIn,
    );

    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeOut,
    ));

    // trigger logo slide in immediately
    _logoAnimationController.forward();
  }

  void _startTypingAnimation() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (_currentMessage.length < _fullWelcomeMessage.length) {
        setState(() {
          _currentMessage =
              _fullWelcomeMessage.substring(0, _currentMessage.length + 1);
        });
      } else {
        timer.cancel();
        _cursorTimer?.cancel();
        setState(() => _showCursor = false);
        _buttonAnimationController.forward();
      }
    });
  }

  void _browseAsGuest(BuildContext context) {
    context.read<AuthStatusCubit>().setGuest();
    context.go('/home');
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _buttonAnimationController.dispose();
    _logoAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Section (animated logo + title)
                SlideTransition(
                  position: _logoSlideAnimation,
                  child: Column(
                    children: [
                      // Lottie Developer Logo
                      Lottie.asset(
                        'assets/dev.json',
                        width: 160,
                        repeat: true,
                      ),
                      const SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: _currentMessage),
                            TextSpan(
                              text: _showCursor ? '▋' : '',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontFamily: 'Fira Code',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your community for coding solutions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Bottom Section (buttons)
                FadeTransition(
                  opacity: _buttonFadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Create account button
                      PrimaryButton(
                        text: 'Create an Account',
                        onPressed: () => context.push('/signup'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () => context.push('/login'),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => _browseAsGuest(context),
                        child: const Text(
                          'Browse as a guest',
                          style: TextStyle(
                            color: Colors.white54,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
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
