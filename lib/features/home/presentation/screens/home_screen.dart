// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:devoverflow/features/home/presentation/cubit/home_cubit.dart';
import 'package:devoverflow/features/home/presentation/cubit/home_state.dart';
import 'package:devoverflow/features/home/presentation/widgets/question_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit()..fetchQuestions(),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      appBar: AppBar(
        title: const Text('DevOverflow',
            style: TextStyle(fontWeight: FontWeight.bold)),
        // 0.8 * 255 = 204
        backgroundColor: const Color(0xFF2C3E50).withValues(alpha: 204),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined, size: 26),
            onPressed: () => context.push('/chatbot'),
            tooltip: 'AI Assistant',
          ),
          // FIX: The notification button is now functional.
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 28),
            onPressed: () => context.push('/notifications'),
            tooltip: 'Notifications',
          ),
          InkWell(
            onTap: () {
              context.go('/profile');
            },
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.only(left: 8.0, right: 16.0),
              child: CircleAvatar(
                backgroundImage:
                    NetworkImage('https://i.pravatar.cc/150?u=current_user'),
                radius: 18,
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HomeLoaded) {
            if (state.questions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.question_answer_outlined,
                        size: 64, color: Colors.white.withValues(alpha: 153)),
                    const SizedBox(height: 16),
                    Text(
                      'No questions yet',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 230),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to ask a question!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 153),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.push('/ask'),
                      child: const Text('Ask a Question'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 10, bottom: 80),
              itemCount: state.questions.length,
              itemBuilder: (context, index) {
                return QuestionCard(question: state.questions[index]);
              },
            );
          }
          if (state is HomeError) {
            return Center(
                child: Text('Error: ${state.message}',
                    style: const TextStyle(color: Colors.white)));
          }
          return const Center(
              child: Text('Something went wrong.',
                  style: TextStyle(color: Colors.white)));
        },
      ),
    );
  }
}
