class RouteGuardContext {
  final bool isLoggedIn;
  final bool hasCompletedOnboarding;
  final bool isPublicAuthPath;
  final bool isOnboardingPath;
  final String homePath;
  final String onboardingPath;
  final String loginPath;

  const RouteGuardContext({
    required this.isLoggedIn,
    required this.hasCompletedOnboarding,
    required this.isPublicAuthPath,
    required this.isOnboardingPath,
    required this.homePath,
    required this.onboardingPath,
    required this.loginPath,
  });
}

String? resolveRouteRedirect(RouteGuardContext context) {
  if (!context.isLoggedIn &&
      !context.isPublicAuthPath &&
      !context.isOnboardingPath) {
    return context.loginPath;
  }
  if (!context.isLoggedIn && context.isOnboardingPath) {
    return context.loginPath;
  }
  if (context.isLoggedIn &&
      !context.hasCompletedOnboarding &&
      !context.isOnboardingPath) {
    return context.onboardingPath;
  }
  if (context.isLoggedIn && context.isPublicAuthPath) {
    return context.hasCompletedOnboarding
        ? context.homePath
        : context.onboardingPath;
  }
  return null;
}
