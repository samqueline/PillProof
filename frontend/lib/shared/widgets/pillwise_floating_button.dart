import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Floating pill button in bottom-right corner reading "PILLWISE"
/// with chat bubble icon, connecting directly to the AI Medicine Advisor.
class PillwiseFloatingButton extends StatelessWidget {
  const PillwiseFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 18,
      bottom: 22,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/chat'),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF29B6F6), // Vibrant Light Blue
                  Color(0xFF0288D1), // Cerulean Blue
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0288D1).withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chat bubble icon with dots
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF01579B), // Dark Navy Blue
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PILLWISE',
                  style: TextStyle(
                    color: Color(0xFF01579B), // Dark Navy Blue
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

