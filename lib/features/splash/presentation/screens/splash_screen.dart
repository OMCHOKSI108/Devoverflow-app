// lib/features/splash/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/splash_cubit.dart';
import '../cubit/splash_state.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashCubit()..checkAuthentication(),
      child: const SplashView(),
    );
  }
}

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Your excellent animation setup remains the same!
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    // REMOVED: The hardcoded Timer is gone! The BlocListener below now handles navigation.
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // KEY CHANGE: We wrap the Scaffold with a BlocListener.
    // This will listen for state changes from the SplashCubit and navigate accordingly.
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is SplashAuthenticated) {
          // If logged in, go to the home screen.
          // `context.go` replaces the entire navigation stack.
          context.go('/home');
        } else if (state is SplashUnauthenticated) {
          // If not logged in, go to the welcome screen.
          context.go('/welcome');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2C3E50),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Your beautiful, animated UI remains untouched.
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(fontSize: 50.0, fontFamily: 'Poppins'),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'dev',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF2C94C),
                          ),
                        ),
                        TextSpan(
                          text: 'overflow',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 30.0,
              left: 0,
              right: 0,
              child: Text(
                '© 2025 Om and Dev. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color.fromARGB(153, 255, 255, 255),
                  fontSize: 12.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}