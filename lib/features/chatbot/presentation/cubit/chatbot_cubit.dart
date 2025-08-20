// lib/features/chatbot/presentation/cubit/chatbot_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/core/services/api_service.dart';
import 'package:devoverflow/common/models/chat_message_model.dart';
import 'chatbot_state.dart';

class ChatbotCubit extends Cubit<ChatbotState> {
  final ApiService _apiService = ApiService();

  ChatbotCubit() : super(const ChatbotLoaded([]));

  Future<void> sendMessage(String text) async {
    // Get the current list of messages from the state
    List<ChatMessage> currentMessages = [];
    if (state is ChatbotLoaded) {
      currentMessages = (state as ChatbotLoaded).messages;
    } else if (state is ChatbotLoading) {
      currentMessages = (state as ChatbotLoading).messages;
    }

    // Immediately add the user's message to the UI for a responsive feel
    final userMessage = ChatMessage(
      text: text,
      author: MessageAuthor.user,
      timestamp: DateTime.now(),
    );
    final updatedMessages = List<ChatMessage>.from(currentMessages)..add(userMessage);

    // Emit a loading state to show the "AI is typing..." indicator
    emit(ChatbotLoading(updatedMessages));

    try {
      // Get the live response from your backend API.
      final botResponseText = await _apiService.getChatbotResponse(text);

      final botResponseMessage = ChatMessage(
        text: botResponseText,
        author: MessageAuthor.bot,
        timestamp: DateTime.now(),
      );

      // Add the AI's response to the message list
      final finalMessages = List<ChatMessage>.from(updatedMessages)..add(botResponseMessage);

      // Emit the final loaded state with the complete conversation
      emit(ChatbotLoaded(finalMessages));

    } catch (e) {
      // If the API call fails, show an error message in the chat
      final errorMessage = ChatMessage(
        text: "Sorry, I couldn't get a response. Please try again.",
        author: MessageAuthor.bot,
        timestamp: DateTime.now(),
      );
      final finalMessages = List<ChatMessage>.from(updatedMessages)..add(errorMessage);
      emit(ChatbotLoaded(finalMessages));
    }
  }
}
