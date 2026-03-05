# Phase 1 Task Board (Firebase Auth)

This board translates Phase 1 into executable tickets with dependencies, file targets, and acceptance criteria.

## Status Legend
- `TODO`: Not started
- `IN_PROGRESS`: Actively being developed
- `BLOCKED`: Waiting on dependency/decision
- `DONE`: Meets acceptance criteria

## Sprint 1: Platform + Authentication

### P1-001 Firebase project and SDK bootstrap
- Status: `IN_PROGRESS`
- Priority: `P0`
- Depends on: None
- Scope:
  - Add Firebase core/auth/firestore packages.
  - Initialize Firebase before app startup.
  - Configure Android Firebase Gradle integration and app plugin.
  - Ensure iOS/macOS/web Firebase config files are in place as needed.
- File targets:
  - `pubspec.yaml`
  - `lib/main.dart`
  - `android/build.gradle.kts`
  - `android/app/build.gradle.kts`
- Acceptance criteria:
  - App launches without Firebase initialization errors.
  - `FirebaseAuth.instance` and `FirebaseFirestore.instance` can be referenced at runtime.
- Notes:
  - Flutter + Android Gradle wiring is complete in code.
  - `android/app/google-services.json` is now added.
  - iOS config file (`ios/Runner/GoogleService-Info.plist`) is still pending if iOS support is required in Phase 1.

### P1-002 Auth domain models and repository contracts
- Status: `DONE`
- Priority: `P0`
- Depends on: `P1-001`
- Scope:
  - Create auth user model and repository interface.
  - Implement FirebaseAuth repository methods:
    - register, login, logout, password reset
    - auth state stream
- File targets:
  - `lib/features/auth/data/`
  - `lib/features/auth/domain/`
  - `lib/features/auth/presentation/providers/`
- Acceptance criteria:
  - Repository unit tests cover success + error paths.
  - App can observe logged-in/logged-out state via provider.
- Notes:
  - Model + repository interface + FirebaseAuth implementation + Riverpod providers are added.
  - Added automated unit tests in `test/features/auth/data/repositories/firebase_auth_repository_test.dart` covering:
    - auth state mapping (`User` -> `AuthUser`, `null` -> `null`)
    - sign-in success path and null-user error path
    - create-user profile bootstrap path
    - password reset and sign-out delegation

### P1-003 Auth screens and form validation
- Status: `IN_PROGRESS`
- Priority: `P0`
- Depends on: `P1-002`
- Scope:
  - Build `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`.
  - Add input validation and loading/error UI.
- File targets:
  - `lib/features/auth/presentation/screens/`
  - `lib/core/utils/validators.dart` (if needed)
- Acceptance criteria:
  - User can register/login/logout/reset password.
  - Validation errors are shown before API call.
- Notes:
  - Login, Register, and Forgot Password screens are implemented and routed.
  - New user onboarding is now implemented after registration (`Student` vs `Teacher` start path).
  - Logout action is now wired in settings.
  - Remaining work: runtime validation against configured Firebase project.
  - Pending decision: manual live Firebase validation deferred while Phase 2 starts in parallel.

### P1-004 Route guards and session-aware navigation
- Status: `IN_PROGRESS`
- Priority: `P0`
- Depends on: `P1-003`
- Scope:
  - Protect app routes requiring auth.
  - Redirect anonymous users to login and authenticated users away from auth pages.
- File targets:
  - `lib/core/config/routes.dart`
- Acceptance criteria:
  - Unauthenticated user cannot access protected pages.
  - Post-login redirects to home/dashboard correctly.
- Notes:
  - Redirect rules are implemented in `GoRouter` for auth vs protected routes.
  - Needs runtime verification once Firebase project config is fully connected.
  - Pending decision: manual live Firebase validation deferred while Phase 2 starts in parallel.

### P1-005 User profile bootstrap on first login
- Status: `IN_PROGRESS`
- Priority: `P1`
- Depends on: `P1-002`
- Scope:
  - Create `users/{uid}` document on first sign-in with default profile fields.
- File targets:
  - `lib/features/auth/data/`
  - `lib/features/settings/data/` (if shared)
- Acceptance criteria:
  - New user always has a profile document.
- Notes:
  - Bootstrap logic is implemented in auth repository for sign-up/sign-in paths.
  - Runtime verification against Firestore is pending.
  - Pending decision: manual live Firebase validation deferred while Phase 2 starts in parallel.

## Sprint 2: Firestore data layer + core flows

### P1-006 Firestore schema and typed repositories
- Status: `DONE`
- Priority: `P0`
- Depends on: `P1-001`
- Scope:
  - Define and implement repositories for:
    - `teachers`
    - `bookings`
    - `reviews`
    - `users`
  - Replace critical mock reads in screens.
- File targets:
  - `lib/features/*/data/`
  - `lib/features/*/presentation/providers/`
- Acceptance criteria:
  - Teacher list/profile, bookings, and reviews can load from Firestore.
- Notes:
  - Added typed repository layer for core collections:
    - `lib/features/booking/data/repositories/booking_repository.dart`
    - `lib/features/teachers/data/repositories/teacher_repository.dart`
    - `lib/features/reviews/data/repositories/review_repository.dart`
    - `lib/features/users/data/repositories/user_repository.dart`
  - `BookingScreen` now reads/writes through repository methods instead of direct Firestore transaction/query code.
  - `MyCoursesScreen` and `LeaveReviewScreen` are now migrated to repository-backed streams/actions for bookings/reviews/teachers.
  - `TeachingDashboardScreen`, `FindTeachersScreen`, and `TeacherProfileScreen` are now migrated to repository-backed streams/actions.
  - `SettingsScreen` and `ModeToggle` writes/reads are now routed through `UserRepository`/`TeacherRepository`.
  - `LoginScreen`, `OnboardingScreen`, and `LearningDashboardScreen` are now migrated to repository-backed collection access.
  - `TeacherOffersScreen` and `LessonRoomScreen` are now migrated to repository-backed streams/actions.
  - Screen-level direct `FirebaseFirestore.instance` usage is now removed from feature presentation code (remaining usage is in repository/provider layers).

### P1-007 Booking creation persistence
- Status: `IN_PROGRESS`
- Priority: `P0`
- Depends on: `P1-006`
- Scope:
  - Persist booking requests from booking screen to `bookings`.
  - Include learner ID, teacher ID, date/time, duration, price snapshot, status.
- File targets:
  - `lib/features/booking/presentation/screens/booking_screen.dart`
  - `lib/features/booking/data/`
- Acceptance criteria:
  - Confirm booking creates a Firestore document.
  - My Courses reflects created booking.
- Notes:
  - Booking creation path is centralized in `BookingRepository.createPendingBooking`.
  - Canonical booking identity is now generated via `BookingRepository.buildSlotId` and stored as both document ID and `slotId`.
  - Teacher references are normalized for writes (`teacherId` as UID, `teacherDocId` as teacher document ID) while reads preserve compatibility with legacy ID shapes.
  - `MyCoursesScreen` now resolves teacher linkage with `teacherDocId` fallback to `teacherId` for legacy compatibility.
  - Remaining work: runtime E2E verification for booking creation visibility across learner/teacher views.
  - Pending decision: manual live Firebase validation deferred while Phase 2 starts in parallel.

### P1-008 Teacher accept/reject booking actions
- Status: `IN_PROGRESS`
- Priority: `P0`
- Depends on: `P1-007`
- Scope:
  - Replace no-op button handlers with repository actions.
  - Update booking status (`pending` -> `accepted`/`rejected`).
- File targets:
  - `lib/features/dashboard/teaching/presentation/screens/teaching_dashboard_screen.dart`
  - `lib/features/booking/data/`
- Acceptance criteria:
  - Accept/reject updates are persisted and reflected in learner course view.
- Notes:
  - Teaching dashboard now loads pending bookings from Firestore and writes status updates (`accepted` / `rejected`).
  - Pending list + pending count are now data-driven for signed-in teacher.
  - `TeachingDashboardScreen` booking/user/review streams and booking status updates are now wired through repositories (`BookingRepository`, `UserRepository`, `ReviewRepository`).
  - Remaining work: runtime E2E verification that learner-side course views reflect teacher decisions under both legacy and normalized booking shapes.
  - Pending decision: manual live Firebase validation deferred while Phase 2 starts in parallel.

### P1-009 Review submission + teacher metric updates
- Status: `IN_PROGRESS`
- Priority: `P0`
- Depends on: `P1-007`
- Scope:
  - Save 5-dimension reviews in `reviews`.
  - Update teacher aggregate rating fields for dashboard/profile.
- File targets:
  - `lib/features/reviews/presentation/screens/leave_review_screen.dart`
  - `lib/features/reviews/data/`
  - `lib/features/teachers/data/`
- Acceptance criteria:
  - Review submit creates Firestore review doc.
  - Teacher profile/dashboard numbers update after refresh.
- Notes:
  - Leave Review now submits real `reviews` documents tied to booking + reviewer.
  - Review submit duplicate-check and create operations are now centralized in `ReviewRepository`.
  - My Courses now resolves review status from `reviews` (no mock `hasReview` dependency).
  - Teacher profile and teaching dashboard now aggregate average rating + skill radar from Firestore reviews.
  - Teacher profile review + lesson-offer loading now uses repository-backed reference resolution (UID + doc ID compatibility).
  - Remaining work: optional denormalized aggregates in `teachers` docs for query efficiency.
  - Pending decision: manual live Firebase validation deferred while Phase 2 starts in parallel.

## Sprint 3: Complete remaining Phase 1 checklist

### P1-010 Search keyword support in teacher discovery
- Status: `DONE`
- Priority: `P1`
- Depends on: `P1-006`
- Scope:
  - Apply keyword search to teacher name/bio/languages alongside existing filters.
- File targets:
  - `lib/features/teachers/presentation/screens/find_teachers_screen.dart`
- Acceptance criteria:
  - Typing search text changes result set predictably.
- Notes:
  - Find Teachers now applies search keyword against name, bio, teaching languages, and speaking languages.
  - Search input is now actively wired to state updates.

### P1-011 Settings persistence (profile/language/teacher settings)
- Status: `DONE`
- Priority: `P1`
- Depends on: `P1-006`
- Scope:
  - Persist settings data to user profile and teacher profile documents.
- File targets:
  - `lib/features/settings/presentation/screens/settings_screen.dart`
  - `lib/features/settings/data/`
- Acceptance criteria:
  - Saved changes survive app restart and re-login.
- Notes:
  - `SettingsScreen` now loads/saves profile, language preferences, and teacher settings to Firestore (`users/{uid}` and `teachers/{uid}`).
  - Save actions are wired with loading/error feedback.

### P1-012 Notification preference persistence
- Status: `DONE`
- Priority: `P1`
- Depends on: `P1-011`
- Scope:
  - Store notification toggles in profile settings.
- File targets:
  - `lib/features/settings/presentation/screens/settings_screen.dart`
- Acceptance criteria:
  - Notification toggle values remain consistent after refresh/restart.
- Notes:
  - Notification toggles are now persisted in `users/{uid}.notifications`.

### P1-013 Localization baseline
- Status: `DONE`
- Priority: `P2`
- Depends on: `P1-001`
- Scope:
  - Add `app_en.arb` and wire Flutter localization delegates/supported locales.
  - Migrate key strings to localization.
- File targets:
  - `lib/l10n/`
  - `lib/app.dart`
  - `pubspec.yaml`
- Acceptance criteria:
  - At least one ARB locale is wired and rendered.
- Notes:
  - Added `lib/l10n/app_en.arb` and localization generation config.
  - `MaterialApp` now uses generated localization delegates/supported locales.
  - App title is now localized through `AppLocalizations`.

### P1-014 Payment scope decision for Phase 1
- Status: `DONE`
- Priority: `P0`
- Depends on: Product decision
- Scope:
  - Decide one:
    - A) Implement Stripe payment intent flow in-app (higher effort)
    - B) Mark Stripe as Phase 1.5 and update README accordingly
- File targets:
  - `README.md`
  - Payment feature files (if option A)
- Acceptance criteria:
  - README and roadmap match actual delivery scope.
- Decision:
  - Option **B** selected: Stripe is moved to **Phase 1.5** (post-MVP stabilization) to keep Phase 1 focused on Firebase-backed core learning/teaching flows.

## Cross-Cutting: Security, Quality, and Release

### P1-015 Firestore security rules
- Status: `DONE`
- Priority: `P0`
- Depends on: `P1-006`
- Scope:
  - Enforce access controls for users/bookings/reviews/teachers.
- File targets:
  - `firestore.rules`
  - `tests/firestore.rules.test.js`
  - `firebase.json`
  - `package.json`
- Acceptance criteria:
  - Unauthorized reads/writes are denied.
  - Valid user operations pass.
- Notes:
  - Added Firestore Emulator rules test harness with explicit allow/deny coverage for:
    - owner-only user profile writes
    - teacher-only lesson offer creation
    - booking-participant-only booking reads
    - review creation allowed only for completed bookings
    - admin claim override behavior
  - Local run command: `npm run rules:test`
  - Validation result (March 5, 2026): `npm run rules:test` executed successfully in Firestore Emulator and exited with code `0`.

### P1-016 Error handling and loading states
- Status: `DONE`
- Priority: `P1`
- Depends on: `P1-003`, `P1-006`
- Scope:
  - Standardize async loading/error widgets across feature screens.
- File targets:
  - `lib/core/widgets/`
  - Affected feature screens/providers
- Acceptance criteria:
  - No silent failures on auth/booking/review/settings operations.
- Notes:
  - Added reusable async state widgets in `lib/core/widgets/async_state_widgets.dart`.
  - Applied standardized loading/error/empty UI across major Firestore-backed screens (teacher profile, find teachers, booking, teacher offers, my courses, review, teaching dashboard).

### P1-017 Test suite for critical journeys
- Status: `DONE`
- Priority: `P1`
- Depends on: `P1-008`, `P1-009`, `P1-011`
- Scope:
  - Add tests for:
    - auth state and route guarding
    - booking create + teacher accept/reject
    - review submission
- File targets:
  - `test/`
- Acceptance criteria:
  - Core journey tests pass in CI/local.
- Notes:
  - Added unit tests for route-guard redirect logic, teacher booking-decision status rules, and review eligibility status gating.
  - Updated smoke widget test to a Firebase-independent shell render check for stable local/CI runs.

### P1-018 Definition of Done and release checklist
- Status: `IN_PROGRESS`
- Priority: `P0`
- Depends on: All Phase 1 tickets
- Scope:
  - Final validation checklist:
    - `flutter analyze` clean
    - tests passing
    - E2E demo script validated
    - README Phase 1 status updated
- File targets:
  - `README.md`
  - `docs/phase1_firebase_task_board.md`
  - `docs/phase1_e2e_demo_checklist.md`
- Acceptance criteria:
  - Phase 1 can be demoed end-to-end with live Firebase-backed flows.
- Notes:
  - Automated quality checks passing on March 5, 2026:
    - `flutter analyze`
    - `flutter test`
    - `npm run rules:test`
  - Added live Firebase E2E checklist: `docs/phase1_e2e_demo_checklist.md`
  - Remaining work:
    - Runtime E2E demo validation for booking create/decision/review flows on live Firebase data.
    - Final ticket closure pass for remaining `IN_PROGRESS` items.
  - Phase 2 decision: **GO (conditional)**.
    - Condition: keep the tickets above open as pending live validation; do not mark Phase 1 `DONE` until E2E checklist is executed.
