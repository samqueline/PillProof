import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pill_proof/features/chat/presentation/screens/ai_chat_screen.dart';

void main() {
  testWidgets('AiChatScreen renders header, disclaimer, welcome message, and prompt chips',
      (WidgetTester tester) async {
    // Set a wide viewport so prompt chips are laid out
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AiChatScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('AI Medicine Advisor'), findsOneWidget);
    expect(find.text('Uses, Recommended Dosages & Safety'), findsOneWidget);

    // Verify Mandatory Disclaimer
    expect(
      find.text('Educational reference only. Always confirm dosages with your doctor or pharmacist.'),
      findsOneWidget,
    );

    // Verify Welcome message
    expect(find.textContaining('Pill Proof AI Medicine Advisor'), findsOneWidget);

    // Verify Quick Prompts
    expect(find.text('What is Amoxicillin used for and typical dosage?'), findsOneWidget);
    expect(find.text('Paracetamol 650mg daily limit and precautions?'), findsOneWidget);

    // Verify Input Field and Send Button
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });
}
