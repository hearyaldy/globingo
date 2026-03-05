class FeatureFlags {
  const FeatureFlags._();

  // Phase 2 modules are off by default until each feature is release-ready.
  static const bool wallet = bool.fromEnvironment(
    'FLAG_WALLET',
    defaultValue: false,
  );
  static const bool groupLessons = bool.fromEnvironment(
    'FLAG_GROUP_LESSONS',
    defaultValue: false,
  );
  static const bool serviceLearning = bool.fromEnvironment(
    'FLAG_SERVICE_LEARNING',
    defaultValue: false,
  );
  static const bool aiAssistant = bool.fromEnvironment(
    'FLAG_AI_ASSISTANT',
    defaultValue: false,
  );
  static const bool pushNotifications = bool.fromEnvironment(
    'FLAG_PUSH_NOTIFICATIONS',
    defaultValue: false,
  );
  static const bool teacherAnalyticsV1 = bool.fromEnvironment(
    'FLAG_TEACHER_ANALYTICS_V1',
    defaultValue: false,
  );
}
