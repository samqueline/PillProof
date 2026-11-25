import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  final ApiClient _client;

  ChatRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<ChatMessageModel> sendQuery(String message, List<ChatMessageModel> history) async {
    try {
      final formattedHistory = history
          .map((m) => {
                'role': m.isUser ? 'user' : 'model',
                'content': m.text,
              })
          .toList();

      final response = await _client.post(
        ApiConstants.aiChat,
        data: {
          'message': message,
          'history': formattedHistory,
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        final reply = data['reply'] as String? ?? 'No response received.';
        final matched = (data['matchedMedicines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final disclaimer = data['disclaimer'] as String?;

        return ChatMessageModel.ai(
          text: reply,
          matchedMedicines: matched,
          disclaimer: disclaimer,
        );
      } else {
        throw Exception(data?['message'] ?? 'Failed to receive AI response.');
      }
    } catch (e) {
      // In-app fallback for offline or network issues
      return ChatMessageModel.ai(
        text: _getOfflineFallback(message),
        disclaimer: '⚠️ Medical Disclaimer: Educational reference only. Consult your physician or pharmacist.',
      );
    }
  }

  String _getOfflineFallback(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('amox')) {
      return '### 💊 Amoxicillin\n\n'
          '**What it is used for:**\nBroad-spectrum antibiotic prescribed for bacterial infections including respiratory, ear, throat, and urinary tract infections.\n\n'
          '**Recommended Dosage:**\nAdults: 250 mg to 500 mg every 8 hours, or 500 mg to 875 mg every 12 hours. Complete the entire course as prescribed.\n\n'
          '**Precautions:**\nDo not use if allergic to penicillin. Does not treat viral colds or flu.';
    } else if (lower.contains('para') || lower.contains('dolo')) {
      return '### 💊 Paracetamol (Acetaminophen / Dolo)\n\n'
          '**What it is used for:**\nRelief of mild-to-moderate pain, headaches, body aches, and reducing fever.\n\n'
          '**Recommended Dosage:**\nAdults: 500 mg to 650 mg every 4-6 hours. Strictly do not exceed 4,000 mg in 24 hours to prevent acute liver damage.';
    } else if (lower.contains('ibu')) {
      return '### 💊 Ibuprofen\n\n'
          '**What it is used for:**\nAnti-inflammatory pain reliever for muscle pain, toothache, arthritis, and fever.\n\n'
          '**Recommended Dosage:**\nAdults: 200 mg to 400 mg every 4-6 hours after meals. Maximum OTC daily limit: 1,200 mg.';
    }

    return '### 🩺 Medicine Information\n\n'
        'Dosage and usage depend on the active chemical, patient age, and clinical indication. '
        'Always check the packaging or ask your pharmacist for exact instructions.';
  }
}

