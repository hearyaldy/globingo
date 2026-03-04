import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'route_guard.dart';
import '../../features/dashboard/learning/presentation/screens/learning_dashboard_screen.dart';
import '../../features/dashboard/teaching/presentation/screens/teaching_dashboard_screen.dart';
import '../../features/teachers/presentation/screens/find_teachers_screen.dart';
import '../../features/teachers/presentation/screens/teacher_profile_screen.dart';
import '../../features/lessons/presentation/screens/my_courses_screen.dart';
import '../../features/lessons/presentation/screens/teacher_offers_screen.dart';
import '../../features/lessons/presentation/screens/lesson_room_screen.dart';
import '../../features/reviews/presentation/screens/leave_review_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/booking/presentation/screens/booking_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../widgets/main_layout.dart';

class AppRoutes {
  static const String home = '/';
  static const String findTeachers = '/find-teachers';
  static const String teacherProfile = '/teacher/:id';
  static const String dashboard = '/dashboard';
  static const String myCourses = '/my-courses';
  static const String teacherOffers = '/teacher-offers';
  static const String lessonRoom = '/lesson/:bookingId';
  static const String booking = '/booking/:teacherId';
  static const String review = '/review/:lessonId';
  static const String settings = '/settings';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';
}

GoRouter? _appRouter;

GoRouter get appRouter {
  // In debug, rebuild router on each access so hot-reload picks up route changes.
  if (kDebugMode) {
    return _buildRouter();
  }
  return _appRouter ??= _buildRouter();
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: _GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) async {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final currentUser = FirebaseAuth.instance.currentUser;
      final path = state.uri.path;
      final isPublicAuthPath =
          path == AppRoutes.login ||
          path == AppRoutes.register ||
          path == AppRoutes.forgotPassword;
      final isOnboardingPath = path == AppRoutes.onboarding;

      if (!isLoggedIn) {
        return resolveRouteRedirect(
          RouteGuardContext(
            isLoggedIn: false,
            hasCompletedOnboarding: false,
            isPublicAuthPath: isPublicAuthPath,
            isOnboardingPath: isOnboardingPath,
            homePath: AppRoutes.home,
            onboardingPath: AppRoutes.onboarding,
            loginPath: AppRoutes.login,
          ),
        );
      }

      if (isLoggedIn && currentUser != null) {
        bool hasCompletedOnboarding = false;
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          hasCompletedOnboarding =
              (snapshot.data()?['hasCompletedOnboarding'] as bool?) ?? false;
        } catch (_) {
          hasCompletedOnboarding = false;
        }

        return resolveRouteRedirect(
          RouteGuardContext(
            isLoggedIn: true,
            hasCompletedOnboarding: hasCompletedOnboarding,
            isPublicAuthPath: isPublicAuthPath,
            isOnboardingPath: isOnboardingPath,
            homePath: AppRoutes.home,
            onboardingPath: AppRoutes.onboarding,
            loginPath: AppRoutes.login,
          ),
        );
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => NoTransitionPage(
          child: OnboardingScreen(
            initialRole: state.uri.queryParameters['role'],
          ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LearningDashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.findTeachers,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FindTeachersScreen()),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TeachingDashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.myCourses,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MyCoursesScreen()),
          ),
          GoRoute(
            path: AppRoutes.lessonRoom,
            pageBuilder: (context, state) {
              final bookingId = state.pathParameters['bookingId'] ?? '';
              return NoTransitionPage(
                child: LessonRoomScreen(bookingId: bookingId),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.teacherOffers,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TeacherOffersScreen()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: AppRoutes.teacherProfile,
            pageBuilder: (context, state) {
              final teacherId = state.pathParameters['id'] ?? '';
              return NoTransitionPage(
                child: TeacherProfileScreen(teacherId: teacherId),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.booking,
            pageBuilder: (context, state) {
              final teacherId = state.pathParameters['teacherId'] ?? '';
              return NoTransitionPage(
                child: BookingScreen(teacherId: teacherId),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.review,
            pageBuilder: (context, state) {
              final lessonId = state.pathParameters['lessonId'] ?? '';
              return NoTransitionPage(
                child: LeaveReviewScreen(lessonId: lessonId),
              );
            },
          ),
        ],
      ),
    ],
  );
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
