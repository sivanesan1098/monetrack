import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetrack/core/services/ai_service.dart';
import 'package:monetrack/presentation/providers/repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_chat_controller.g.dart';

@riverpod
AiService aiService(AiServiceRef ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return AiService(repository);
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

@riverpod
class AiChatController extends _$AiChatController {
  @override
  List<ChatMessage> build() {
    return [
      ChatMessage(
        text: "Hi! I am Monetrack AI. Ask me anything about your recent expenses.", 
        isUser: false, 
        timestamp: DateTime.now()
      ),
    ];
  }

  Future<void> initializeWithKey(String apiKey) async {
    ref.read(aiServiceProvider).initialize(apiKey);
  }

  bool get isReady => ref.read(aiServiceProvider).isInitialized;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    state = [
      ...state,
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    ];

    final service = ref.read(aiServiceProvider);
    
    // Check if initialized
    if (!service.isInitialized) {
       state = [
        ...state,
        ChatMessage(
          text: "I need a Google Gemini API key to help you. Please set it in Settings first.", 
          isUser: false, 
          timestamp: DateTime.now()
        ),
      ];
      return;
    }

    // Call API
    final response = await service.askQuestion(text);

    // Add response
    state = [
      ...state,
      ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
    ];
  }
}
