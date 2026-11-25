class ChatMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> matchedMedicines;
  final String? disclaimer;

  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.matchedMedicines = const [],
    this.disclaimer,
  });

  factory ChatMessageModel.user(String text) {
    return ChatMessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessageModel.ai({
    required String text,
    List<String> matchedMedicines = const [],
    String? disclaimer,
  }) {
    return ChatMessageModel(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      matchedMedicines: matchedMedicines,
      disclaimer: disclaimer,
    );
  }
}

