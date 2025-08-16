// lib/features/chatbot/presentation/cubit/chatbot_state.dart
import 'package:equatable/equatable.dart';
import 'package:devoverflow/common/models/chat_message_model.dart';

abstract class ChatbotState extends Equatable {
  const ChatbotState();

  @override
  List<Object> get props => [];
}

class ChatbotInitial extends ChatbotState {}

// FIX: The loading state now also contains the list of messages
// so the UI can display them while waiting for a new response.
class ChatbotLoading extends ChatbotState {
  final List<ChatMessage> messages;

  const ChatbotLoading(this.messages);

  @override
  List<Object> get props => [messages];
}

class ChatbotLoaded extends ChatbotState {
  final List<ChatMessage> messages;

  const ChatbotLoaded(this.messages);

  @override
  List<Object> get props => [messages];
}

class ChatbotError extends ChatbotState {
  final String message;

  const ChatbotError(this.message);

  @override
  List<Object> get props => [message];
}
