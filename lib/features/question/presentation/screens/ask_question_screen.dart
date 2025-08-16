// lib/features/question/presentation/screens/ask_question_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:devoverflow/features/question/presentation/cubit/question_cubit.dart';
import 'package:devoverflow/features/question/presentation/cubit/question_state.dart';
import 'package:devoverflow/features/home/presentation/cubit/home_cubit.dart';
import 'package:devoverflow/common/widgets/primary_button.dart';

class AskQuestionScreen extends StatelessWidget {
  const AskQuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuestionCubit(
        homeCubit: context.read<HomeCubit>(),
      ),
      child: const AskQuestionView(),
    );
  }
}

class AskQuestionView extends StatefulWidget {
  const AskQuestionView({super.key});

  @override
  State<AskQuestionView> createState() => _AskQuestionViewState();
}

class _AskQuestionViewState extends State<AskQuestionView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _submitQuestion() {
    if (_formKey.currentState!.validate()) {
      context.read<QuestionCubit>().submitQuestion(
        title: _titleController.text,
        body: _bodyController.text,
        tags: _tagsController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask a Question'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<QuestionCubit, QuestionState>(
        listener: (context, state) {
          if (state is QuestionSubmitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Question posted successfully!'), backgroundColor: Colors.green),
            );
            context.pop();
          } else if (state is QuestionSubmitError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g., How to use BLoC in Flutter?'),
                    validator: (value) => value!.isEmpty ? 'Title cannot be empty' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _bodyController,
                    decoration: const InputDecoration(labelText: 'Body', hintText: 'Include all the information...'),
                    maxLines: 8,
                    validator: (value) => value!.isEmpty ? 'Body cannot be empty' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(labelText: 'Tags', hintText: 'e.g., flutter, bloc (comma separated)'),
                    validator: (value) => value!.isEmpty ? 'Please add at least one tag' : null,
                  ),
                  const SizedBox(height: 40),
                  PrimaryButton(
                    text: 'Post Your Question',
                    isLoading: state is QuestionSubmitting,
                    onPressed: _submitQuestion,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
