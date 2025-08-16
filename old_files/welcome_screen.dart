import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final String _fullWelcomeMessage = 'Welcome to DevOverflow';
  String _currentMessage = '';
  Timer? _typingTimer;
  Timer? _cursorTimer;
  bool _showCursor = true;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _showCursor = !_showCursor);
    });

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeIn),
    );
  }

  void _startTypingAnimation() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_currentMessage.length < _fullWelcomeMessage.length) {
        if (mounted) {
          setState(() {
            _currentMessage =
                _fullWelcomeMessage.substring(0, _currentMessage.length + 1);
          });
        }
      } else {
        timer.cancel();
        _cursorTimer?.cancel();
        if (mounted) {
          setState(() => _showCursor = false);
          _buttonAnimationController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: _currentMessage),
                      TextSpan(
                        text: _showCursor ? '▋' : '',
                        style: const TextStyle(color: Color(0xFFF2C94C)),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontFamily: 'Fira Code',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 100),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAuthButton(context, 'Sign Up', () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const SignUpScreen()));
                      }),
                      const SizedBox(width: 20),
                      _buildAuthButton(context, 'Login', () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const LoginScreen()));
                      }),
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

  Widget _buildAuthButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        // FIX: Replaced deprecated withOpacity with fromARGB
        backgroundColor: const Color.fromARGB(25, 255, 255, 255),
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
