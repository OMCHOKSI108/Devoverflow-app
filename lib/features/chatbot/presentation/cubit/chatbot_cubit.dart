// lib/features/chatbot/presentation/cubit/chatbot_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/common/models/chat_message_model.dart';
import 'chatbot_state.dart';

class ChatbotCubit extends Cubit<ChatbotState> {
  // Start with an empty list of messages in a loaded state.
  ChatbotCubit() : super(const ChatbotLoaded([]));

  Future<void> sendMessage(String text) async {
    // Get the current list of messages, regardless of state.
    List<ChatMessage> currentMessages = [];
    if (state is ChatbotLoaded) {
      currentMessages = (state as ChatbotLoaded).messages;
    } else if (state is ChatbotLoading) {
      currentMessages = (state as ChatbotLoading).messages;
    }

    // Add user's message immediately
    final userMessage = ChatMessage(
      text: text,
      author: MessageAuthor.user,
      timestamp: DateTime.now(),
    );
    final updatedMessages = List<ChatMessage>.from(currentMessages)
      ..add(userMessage);

    // FIX: Emit the loading state with the updated message list.
    emit(ChatbotLoading(updatedMessages));

    try {
      // Simulate a network call to the chatbot API
      await Future.delayed(const Duration(milliseconds: 1500));

      // --- THIS IS WHERE YOUR FUTURE API CALL WILL GO ---
      final botResponse = ChatMessage(
        text: "This is a simulated response for: '$text'. The real API is coming soon!",
        author: MessageAuthor.bot,
        timestamp: DateTime.now(),
      );

      final finalMessages = List<ChatMessage>.from(updatedMessages)
        ..add(botResponse);

      emit(ChatbotLoaded(finalMessages));

    } catch (e) {
      emit(const ChatbotError("Failed to get response. Please try again."));
    }
  }
}
