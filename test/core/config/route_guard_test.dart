import 'package:flutter_test/flutter_test.dart';
import 'package:globingo/core/config/route_guard.dart';

void main() {
  group('resolveRouteRedirect', () {
    RouteGuardContext context({
      required bool isLoggedIn,
      required bool hasCompletedOnboarding,
      required bool isPublicAuthPath,
      required bool isOnboardingPath,
    }) {
      return RouteGuardContext(
        isLoggedIn: isLoggedIn,
        hasCompletedOnboarding: hasCompletedOnboarding,
        isPublicAuthPath: isPublicAuthPath,
        isOnboardingPath: isOnboardingPath,
        homePath: '/',
        onboardingPath: '/onboarding',
        loginPath: '/login',
      );
    }

    test('redirects unauthenticated protected route to login', () {
      final redirect = resolveRouteRedirect(
        context(
          isLoggedIn: false,
          hasCompletedOnboarding: false,
          isPublicAuthPath: false,
          isOnboardingPath: false,
        ),
      );

      expect(redirect, '/login');
    });

    test('redirects unauthenticated onboarding to login', () {
      final redirect = resolveRouteRedirect(
        context(
          isLoggedIn: false,
          hasCompletedOnboarding: false,
          isPublicAuthPath: false,
          isOnboardingPath: true,
        ),
      );

      expect(redirect, '/login');
    });

    test('redirects authenticated incomplete user to onboarding', () {
      final redirect = resolveRouteRedirect(
        context(
          isLoggedIn: true,
          hasCompletedOnboarding: false,
          isPublicAuthPath: false,
          isOnboardingPath: false,
        ),
      );

      expect(redirect, '/onboarding');
    });

    test('redirects authenticated completed user away from auth pages', () {
      final redirect = resolveRouteRedirect(
        context(
          isLoggedIn: true,
          hasCompletedOnboarding: true,
          isPublicAuthPath: true,
          isOnboardingPath: false,
        ),
      );

      expect(redirect, '/');
    });

    test('does not redirect authenticated completed user on app pages', () {
      final redirect = resolveRouteRedirect(
        context(
          isLoggedIn: true,
          hasCompletedOnboarding: true,
          isPublicAuthPath: false,
          isOnboardingPath: false,
        ),
      );

      expect(redirect, isNull);
    });
  });
}
