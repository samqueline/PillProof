import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/schedule/presentation/screens/daily_schedule_screen.dart';
import '../features/verification/presentation/screens/verification_screen.dart';
import '../features/medications/presentation/screens/medications_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/scanner/presentation/screens/qr_camera_scanner_screen.dart';
import '../features/ocr/presentation/screens/tablet_cover_ocr_screen.dart';
import '../features/chat/presentation/screens/ai_chat_screen.dart';
import '../features/calendar/presentation/screens/medicine_calendar_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/schedule',
      builder: (context, state) => const DailyScheduleScreen(),
    ),
    GoRoute(
      path: '/verify',
      builder: (context, state) => const VerificationScreen(),
    ),
    GoRoute(
      path: '/medications',
      builder: (context, state) => const MedicationsScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const QrCameraScannerScreen(),
    ),
    GoRoute(
      path: '/ocr-scan',
      builder: (context, state) => const TabletCoverOcrScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const AiChatScreen(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const MedicineCalendarScreen(),
    ),
  ],
);
