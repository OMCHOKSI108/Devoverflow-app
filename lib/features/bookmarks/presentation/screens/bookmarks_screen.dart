// lib/features/bookmarks/presentation/screens/bookmarks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/features/bookmarks/presentation/cubit/bookmark_cubit.dart';
import 'package:devoverflow/features/bookmarks/presentation/cubit/bookmark_state.dart';
import 'package:devoverflow/features/home/presentation/widgets/question_card.dart';

// Convert to a StatefulWidget to fetch data on initialization.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    // When the screen is first loaded, call the cubit to fetch the bookmarks.
    context.read<BookmarkCubit>().fetchBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookmarks'),
      ),
      body: BlocBuilder<BookmarkCubit, BookmarkState>(
        builder: (context, state) {
          if (state is BookmarksLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BookmarksLoaded) {
            if (state.bookmarkedQuestions.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'You haven\'t saved any questions yet. Tap the bookmark icon on a question to save it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<BookmarkCubit>().fetchBookmarks(),
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8.0),
                itemCount: state.bookmarkedQuestions.length,
                itemBuilder: (context, index) {
                  final question = state.bookmarkedQuestions[index];
                  return QuestionCard(question: question);
                },
              ),
            );
          }
          // In a real app, you might have a dedicated error widget.
          return const Center(child: Text('Could not load bookmarks.'));
        },
      ),
    );
  }
}
