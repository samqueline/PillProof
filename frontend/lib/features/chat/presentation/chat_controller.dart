import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_repository.dart';
import '../models/chat_message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

class ChatState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() {
    return ChatState(
      messages: [
        ChatMessageModel.ai(
          text:
              'Hello! I am your **Pill Proof AI Medicine Advisor**.\n\n'
              'I can answer questions about:\n'
              '• What a medicine is prescribed or used for\n'
              '• Standard recommended dosages and frequencies\n'
              '• Food interactions, precautions, and side effects\n\n'
              'Tap a quick prompt below or type any medicine name to get started!',
          disclaimer:
              '⚠️ Medical Disclaimer: Educational reference only. Always follow prescription guidelines from your physician.',
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || state.isLoading) return;

    final userMsg = ChatMessageModel.user(query);
    final currentHistory = List<ChatMessageModel>.from(state.messages)..add(userMsg);

    state = state.copyWith(
      messages: currentHistory,
      isLoading: true,
      errorMessage: null,
    );

    try {
      final repo = ref.read(chatRepositoryProvider);
      final aiResponse = await repo.sendQuery(query, state.messages);
      state = state.copyWith(
        messages: List<ChatMessageModel>.from(state.messages)..add(aiResponse),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not send query: $e',
      );
    }
  }

  void clearChat() {
    state = ChatState(
      messages: [
        ChatMessageModel.ai(
          text: 'Chat history cleared. How can I help you with your medications today?',
          disclaimer: '⚠️ Medical Disclaimer: Educational reference only.',
        ),
      ],
    );
  }
}

final chatControllerProvider =
    NotifierProvider<ChatController, ChatState>(ChatController.new);
