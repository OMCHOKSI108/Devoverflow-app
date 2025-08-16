// lib/features/bookmarks/presentation/screens/bookmarks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/features/bookmarks/presentation/cubit/bookmark_cubit.dart';
import 'package:devoverflow/features/bookmarks/presentation/cubit/bookmark_state.dart';
import 'package:devoverflow/features/home/presentation/widgets/question_card.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The TabController has been removed to simplify the screen.
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookmarks'),
      ),
      body: BlocBuilder<BookmarkCubit, BookmarkState>(
        builder: (context, state) {
          if (state is BookmarksLoaded) {
            if (state.bookmarkedQuestions.isEmpty) {
              return const Center(
                child: Text(
                  'You have no saved questions.',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              );
            }
            // The body is now a simple ListView for the bookmarks.
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8.0),
              itemCount: state.bookmarkedQuestions.length,
              itemBuilder: (context, index) {
                final question = state.bookmarkedQuestions[index];
                return QuestionCard(question: question);
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
