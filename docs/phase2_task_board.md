# Phase 2 Task Board (Scaling + Credits + Group Learning)

This board translates Phase 2 proposal scope into executable tickets with dependencies, file targets, and acceptance criteria.

## Status Legend
- `TODO`: Not started
- `IN_PROGRESS`: Actively being developed
- `BLOCKED`: Waiting on dependency/decision
- `DONE`: Meets acceptance criteria

## Phase 2 Start Policy
- Phase 2 work is allowed in parallel while Phase 1 manual live E2E validation remains pending.
- Phase 1 is not formally closed until the Phase 1 E2E checklist is signed off.

## Execution Plan (8 Weeks)

### Week 1: Scope + Foundation
- Tickets: `P2-001`, `P2-002` (start), `P2-003` (start)
- Goals:
  - Finalize Phase 2.0 scope boundary.
  - Draft schema/index plan for wallet, group lessons, service learning.
  - Draft rule model for new collections.
- Exit criteria:
  - Scope lock approved.
  - Schema/rules v1 documented.

### Week 2: Backend Skeleton
- Tickets: `P2-002` (finish), `P2-003` (continue), `P2-004` (start), `P2-018` (start)
- Goals:
  - Create function scaffolding for policy automation.
  - Establish baseline rules/policy test harness.
- Exit criteria:
  - Backend skeleton runnable locally.
  - Initial emulator policy tests passing.

### Week 3: Wallet Core
- Tickets: `P2-005` (start), `P2-006` (start), `P2-009` (start)
- Goals:
  - Implement pending -> available credit lifecycle.
  - Add withdrawal/KYC gating logic.
  - Build wallet UI shell.
- Exit criteria:
  - Ledger lifecycle works in dev.
  - Wallet UI reads real wallet state.

### Week 4: Risk Automation
- Tickets: `P2-005` (finish), `P2-006` (finish), `P2-007` (start), `P2-008` (start), `P2-009` (finish)
- Goals:
  - Finalize wallet UX and policy engine integration.
  - Implement no-show penalties and quality protection triggers.
- Exit criteria:
  - Wallet flow is end-to-end functional.
  - Risk governance pipeline emits expected outcomes.

### Week 5: Group Lessons v1
- Tickets: `P2-010`, `P2-011`
- Goals:
  - Teacher group session create/manage.
  - Learner discovery + enrollment flow.
- Exit criteria:
  - Group lesson create/join flows functional with capacity checks.

### Week 6: Group Session + Notifications
- Tickets: `P2-012`, `P2-013`
- Goals:
  - Group lesson room + attendance tracking.
  - Push notifications for reminders and booking/review events.
- Exit criteria:
  - Attendance persists correctly.
  - Core push events delivered in supported environments.

### Week 7: Service Learning + Certification
- Tickets: `P2-014`, `P2-015`
- Goals:
  - Service-learning mode and volunteer credit constraints.
  - Automated PDF certificate generation.
- Exit criteria:
  - Volunteer credits are non-withdrawable.
  - Certificate pipeline produces valid output.

### Week 8: Hardening + Release Gate
- Tickets: `P2-016` (optional), `P2-017` (optional), `P2-018`, `P2-019`, `P2-020`
- Goals:
  - Complete security/quality/regression checks.
  - Validate mobile readiness and release criteria.
- Exit criteria:
  - Release checklist passes.
  - Phase 2 demo-ready candidate produced.

## Sprint 1: Foundation, Schema, and Governance

### P2-001 Phase 2 scope lock and feature flags
- Status: `DONE`
- Priority: `P0`
- Depends on: Product decision
- Scope:
  - Freeze Phase 2.0 vs Phase 2.5 boundaries.
  - Add feature flags for wallet, group lessons, service learning, AI assist.
- File targets:
  - `README.md`
  - `docs/phase2_task_board.md`
  - `docs/phase2_scope_lock.md`
  - `lib/core/config/`
- Acceptance criteria:
  - Scope document approved and no ambiguous in/out items.
  - Feature flags can disable unfinished Phase 2 modules safely.
- Notes:
  - Added scope lock document: `docs/phase2_scope_lock.md`.
  - Added compile-time feature flags scaffold in `lib/core/config/feature_flags.dart`.
  - Default behavior keeps Phase 2 modules disabled until each feature is release-ready.

### P2-002 Firestore schema v2 for scaling features
- Status: `IN_PROGRESS`
- Priority: `P0`
- Depends on: `P2-001`
- Scope:
  - Define new collections/doc layouts for:
    - `wallets`, `wallet_transactions`
    - `group_lessons`, `group_enrollments`
    - `service_learning_hours`, `certificates`
    - `teacher_quality_events`, `no_show_events`
- File targets:
  - `docs/`
  - `lib/features/*/data/`
- Acceptance criteria:
  - Schema docs include required fields, indexes, and migration notes.
  - Repository contracts cover create/read/update flows.
- Notes:
  - Added schema draft with collections, fields, index plan, migration notes, and open decisions:
    - `docs/phase2_firestore_schema_v2.md`
  - Added initial repository contracts/scaffolds:
    - `lib/features/wallet/data/models/wallet_models.dart`
    - `lib/features/wallet/data/repositories/wallet_repository.dart`
    - `lib/features/group_lessons/data/models/group_lesson_models.dart`
    - `lib/features/group_lessons/data/repositories/group_lesson_repository.dart`

### P2-003 Firestore rules v2 (wallet, group, service)
- Status: `DONE`
- Priority: `P0`
- Depends on: `P2-002`
- Scope:
  - Extend rules for wallet mutation restrictions, group lesson access, service credit constraints.
  - Enforce non-withdrawable volunteer credits and role-based write access.
- File targets:
  - `firestore.rules`
  - `tests/firestore.rules.test.js`
- Acceptance criteria:
  - Unauthorized writes denied in emulator tests.
  - Valid role-based flows pass rules tests.
- Notes:
  - Added v2 rules for:
    - `wallets`, `wallet_transactions`
    - `group_lessons`, `group_enrollments`
    - `service_learning_hours`, `certificates`
    - `no_show_events`, `teacher_quality_events`
  - Added emulator tests in `tests/firestore.rules.test.js` for:
    - wallet owner read vs non-admin write denial
    - admin-only wallet transaction mutation
    - teacher-only group lesson creation
    - learner enrollment flow and teacher-only attendance marking
    - admin-only service-learning/certificate writes
  - `npm run rules:test` passes with expected emulator permission-denied logs for negative test cases.

### P2-004 Cloud Functions scaffolding for policy engines
- Status: `DONE`
- Priority: `P0`
- Depends on: `P2-002`
- Scope:
  - Introduce backend trigger/scheduled-function layer for wallet lifecycle and policy automation.
- File targets:
  - `functions/` (or chosen backend service path)
  - `docs/`
- Acceptance criteria:
  - Functions project boots locally.
  - Core stubs for wallet transition + penalties are in place.
- Notes:
  - Added initial functions scaffold:
    - `functions/package.json`
    - `functions/tsconfig.json`
    - `functions/src/index.ts`
    - `functions/README.md`
  - Added v2 trigger/scheduler stubs:
    - `walletPendingReleaseCron`
    - `bookingStatusPolicyHook`
    - `reviewQualityPolicyHook`
  - Linked Firebase config to functions source in `firebase.json`.
  - Local verification:
    - `npm --prefix functions run build` passes.

## Sprint 2: Credits Wallet and Risk Controls

### P2-005 Wallet ledger lifecycle (pending -> available)
- Status: `IN_PROGRESS`
- Priority: `P0`
- Depends on: `P2-004`
- Scope:
  - Implement immutable transaction ledger.
  - Apply 7-day cooling period before credits become available.
- File targets:
  - `lib/features/wallet/`
  - `functions/`
- Acceptance criteria:
  - Completed lesson credits enter `pending` then transition after 7 days.
  - Ledger entries are auditable and immutable.
- Notes:
  - Implemented first release engine in `functions/src/index.ts`:
    - scheduled `walletPendingReleaseCron` scans `wallet_transactions` where:
      - `status == pending`
      - `bucket == pending`
      - `availableAt <= now`
    - applies release in Firestore transactions:
      - decrements wallet `pendingBalance`
      - increments `availableBalance` or `volunteerBalance` based on `withdrawable`
      - marks transaction as `applied` and updates bucket
  - Implemented booking completion earning pipeline in `functions/src/index.ts`:
    - `bookingStatusPolicyHook` now detects booking status change to `completed`
    - creates immutable `wallet_transactions/{earning_<bookingId>}` via `transaction.create` (idempotent)
    - initializes `availableAt = completionTime + 7 days`
    - increments teacher wallet `pendingBalance`
    - sets `withdrawable=false` when payment method is `service_learning` or `volunteer`
  - Implemented accepted-stage settlement hold in `functions/src/index.ts`:
    - on `bookings` transition to `accepted`, learner payment is debited (`wallet_transactions/payment_out_<bookingId>`)
    - funds are held before teacher release based on booking `paymentRoute`:
      - `teacher_direct` -> `teacher_escrow/{teacherId}`
      - `organization_escrow` -> `organization_funds/main`
    - booking-level settlement state persisted in `booking_settlements/{bookingId}`
  - Implemented completion-stage settlement release in `functions/src/index.ts`:
    - on `bookings` transition to `completed`, held settlement is released
    - teacher receives pending earning (`wallet_transactions/earning_<bookingId>`)
    - escrow balance is reduced accordingly
  - Build verification:
    - `npm --prefix functions run build` passes.

### P2-006 Withdrawal threshold and KYC Lite gating
- Status: `DONE`
- Priority: `P1`
- Depends on: `P2-005`
- Scope:
  - Enforce minimum withdrawal threshold (500/1000 credits as finalized).
  - Block withdrawal unless KYC Lite fields are completed.
- File targets:
  - `lib/features/wallet/`
  - `functions/`
  - `firestore.rules`
- Acceptance criteria:
  - Withdrawals fail below threshold.
  - Withdrawals fail when KYC status is incomplete.
- Notes:
  - Added withdrawal request policy rules in `firestore.rules`:
    - new collection: `wallet_withdrawal_requests`
    - create allowed only when:
      - requester owns `uid`
      - wallet `kycStatus == verified`
      - `amount >= withdrawalThreshold`
      - `amount <= availableBalance`
      - request starts as `pending`
  - Added emulator tests in `tests/firestore.rules.test.js` covering:
    - reject unverified KYC withdrawal
    - reject below-threshold withdrawal
    - allow verified/eligible withdrawal request
  - Verification:
    - `npm run rules:test` passes.
  - Added functions-side request processor in `functions/src/index.ts`:
    - `walletWithdrawalRequestHook` trigger on `wallet_withdrawal_requests/{requestId}`
    - re-validates KYC, threshold, and available-balance constraints inside Firestore transaction
    - creates immutable `wallet_transactions/withdrawal_<requestId>`
    - deducts wallet `availableBalance`
    - updates request status to `processed` or `rejected` with reason
  - Build verification:
    - `npm --prefix functions run build` passes.

### P2-007 No-show automation and penalty pipeline
- Status: `IN_PROGRESS`
- Priority: `P0`
- Depends on: `P2-004`
- Scope:
  - Encode no-show policies:
    - student no-show: no refund
    - teacher no-show: full refund + penalty event
  - Persist events and apply escalation thresholds.
- File targets:
  - `functions/`
  - `lib/features/lessons/`
  - `lib/features/dashboard/`
- Acceptance criteria:
  - Policy outcomes match proposed rules.
  - Escalation triggers are persisted and visible to admin diagnostics.
- Notes:
  - Implemented no-show policy automation in `functions/src/index.ts`:
    - `bookingNoShowPolicyHook` listens on `bookings/{bookingId}` status updates
    - teacher no-show (`noShowActor=teacher`):
      - creates idempotent `no_show_events/{eventId}`
      - credits learner wallet (refund path)
      - debits teacher wallet (penalty path)
      - writes immutable `wallet_transactions` for refund and penalty
      - writes `teacher_quality_events/no_show_warning_<bookingId>` for diagnostics/escalation pipeline input
    - learner no-show (`noShowActor=learner`):
      - records no-show event without refund flow
  - Added booking rules support for no-show transition:
    - teacher can transition `in_progress -> no_show` with `noShowActor in [learner, teacher]`
  - Added emulator rules tests in `tests/firestore.rules.test.js`:
    - learner cannot set `no_show`
    - teacher can set `no_show` with actor
  - Build verification:
    - `npm --prefix functions run build` passes.
  - Rules verification:
    - `npm run rules:test` passes.

### P2-008 Quality protection and teaching access safeguards
- Status: `IN_PROGRESS`
- Priority: `P1`
- Depends on: `P2-007`
- Scope:
  - Track rolling averages and trigger warning/freeze thresholds.
  - Freeze teaching permissions below quality threshold conditions.
- File targets:
  - `functions/`
  - `lib/features/dashboard/teaching/`
  - `lib/features/settings/`
- Acceptance criteria:
  - Warning at configured threshold.
  - Auto-freeze at configured threshold with clear user messaging.
- Notes:
  - Implemented review-driven quality automation in `functions/src/index.ts`:
    - `reviewQualityPolicyHook` now computes rolling average from recent teacher reviews
    - writes `teacher_quality_events/quality_<reviewId>` with action + reason
    - actions:
      - `warning` when quality dips below warning threshold
      - `freeze` when quality drops below freeze threshold (sets `users/{teacherId}.teachingModeEnabled=false`)
      - `unfreeze` when quality recovers above unfreeze threshold (re-enables teaching)
  - Added guard metadata write to user profile:
    - `users/{teacherId}.qualityGuard` with latest status/rollingAverage/update timestamp
  - Build verification:
    - `npm --prefix functions run build` passes.

### P2-009 Wallet UI v1 (balance + history + withdraw)
- Status: `IN_PROGRESS`
- Priority: `P1`
- Depends on: `P2-005`, `P2-006`
- Scope:
  - Build wallet balance, pending/available sections, transaction timeline, withdraw action UI.
- File targets:
  - `lib/features/wallet/presentation/`
- Acceptance criteria:
  - Users can view wallet state and request valid withdrawals.
  - Error/loading states are consistent with app standards.
- Notes:
  - Added Wallet screen UI:
    - `lib/features/wallet/presentation/screens/wallet_screen.dart`
    - wallet summary cards (available/pending/volunteer)
    - withdrawal request form with client-side checks
    - transaction history list from `wallet_transactions`
    - mode-aware behavior:
      - learning mode: learner-focused labels and payout info-only panel
      - teaching mode: earnings/payout labels and active withdrawal request flow
  - Added route and navigation wiring:
    - `lib/core/config/routes.dart` (`/wallet`)
    - `lib/core/widgets/main_layout.dart` (mobile drawer + desktop nav links)
  - Updated wallet repository flow:
    - withdrawal requests now write to `wallet_withdrawal_requests` (not directly to ledger)
    - added mapping helper for transaction records
  - Booking payment route is now captured at booking creation:
    - `paymentRoute=organization_escrow` (default methods)
    - `paymentRoute=teacher_direct` (direct escrow option)
  - Verification:
    - `flutter analyze` passes
    - `flutter test` passes

## Sprint 3: Group Learning and Engagement

### P2-010 Group lesson creation and management
- Status: `IN_PROGRESS`
- Priority: `P0`
- Depends on: `P2-002`, `P2-003`
- Scope:
  - Teacher can create/edit/cancel group sessions with capacity, schedule, and pricing model.
- File targets:
  - `lib/features/group_lessons/`
  - `lib/features/dashboard/teaching/`
- Acceptance criteria:
  - Group sessions persist correctly with seat limits.
  - Teacher can manage session lifecycle.
- Notes:
  - Added teacher group lesson management screen:
    - `lib/features/group_lessons/presentation/screens/group_lessons_manage_screen.dart`
    - create/edit/cancel scheduled group sessions
    - schedule, capacity, and price inputs with validation
  - Added route wiring:
    - `lib/core/config/routes.dart` -> `/group-lessons/manage`
    - Teaching dashboard quick action now links to group lesson management.
  - Updated repository behavior for rules compliance:
    - `lib/features/group_lessons/data/repositories/group_lesson_repository.dart`
    - create now writes deterministic `lessonId` field matching document ID
    - added update and cancel helpers for teacher lifecycle actions
  - Added enrollment seat sync automation:
    - `functions/src/index.ts`
    - `groupEnrollmentCreatedHook` increments `group_lessons.enrolledCount` when a seat is successfully taken
    - `groupEnrollmentCancelledHook` decrements `enrolledCount` on learner cancellation
  - Added capacity guard at rules layer:
    - `firestore.rules` now blocks enrollment create when `enrolledCount >= capacity`

### P2-011 Group lesson discovery and enrollment
- Status: `IN_PROGRESS`
- Priority: `P0`
- Depends on: `P2-010`
- Scope:
  - Learners can browse group sessions and enroll/unenroll.
  - Capacity checks and enrollment conflicts handled safely.
- File targets:
  - `lib/features/group_lessons/`
  - `lib/features/dashboard/learning/`
- Acceptance criteria:
  - Enrollment respects capacity and schedule constraints.
  - Learner sees enrolled sessions in courses/dashboard.
- Notes:
  - Added capacity guard in Firestore rules for enrollment creation:
    - blocks new enrollments when `group_lessons.enrolledCount >= capacity`
  - Added seat-count synchronization hooks in functions:
    - `groupEnrollmentCreatedHook` (increment on successful enroll)
    - `groupEnrollmentCancelledHook` (decrement on cancellation transition)
  - Added/updated rules test coverage:
    - full session enrollment is denied in `tests/firestore.rules.test.js`

### P2-012 Group session room and attendance tracking
- Status: `TODO`
- Priority: `P1`
- Depends on: `P2-011`
- Scope:
  - Add group-room entry gating and attendance state tracking.
  - Prepare integration points for multi-party video provider.
- File targets:
  - `lib/features/lessons/`
  - `lib/features/group_lessons/`
- Acceptance criteria:
  - Only enrolled learners and teacher can access session room.
  - Attendance records are persisted for reporting/certification.

### P2-013 Push notifications (FCM) and reminder workflows
- Status: `TODO`
- Priority: `P1`
- Depends on: `P2-010`, `P2-011`
- Scope:
  - Integrate FCM tokens and trigger notifications for:
    - booking decisions
    - lesson reminders
    - review prompts
- File targets:
  - `lib/features/notifications/`
  - `functions/`
  - platform config files (Android/iOS)
- Acceptance criteria:
  - Notification events are delivered in supported environments.
  - User preferences are honored.

## Sprint 4: Service Learning, AI Assist, and Monetization Enhancements

### P2-014 Service Learning mode and volunteer credit flow
- Status: `TODO`
- Priority: `P0`
- Depends on: `P2-005`, `P2-003`
- Scope:
  - Introduce volunteer teaching mode.
  - Ensure volunteer-earned credits are tagged non-withdrawable.
- File targets:
  - `lib/features/service_learning/`
  - `lib/features/wallet/`
  - `functions/`
- Acceptance criteria:
  - Volunteer sessions recorded with service-hour metadata.
  - Volunteer credits cannot be withdrawn.

### P2-015 Automated PDF certification pipeline
- Status: `TODO`
- Priority: `P1`
- Depends on: `P2-014`
- Scope:
  - Generate certificates containing service hours, language taught, and rating summary.
- File targets:
  - `functions/`
  - `lib/features/service_learning/`
- Acceptance criteria:
  - Users can generate and download/share valid certificate PDFs.
  - Certificate fields match tracked data.

### P2-016 AI Teaching Assistant v1
- Status: `TODO`
- Priority: `P2`
- Depends on: `P2-009`, `P2-011`
- Scope:
  - AI-generated lesson summaries.
  - Sentiment/keyword extraction from review text.
- File targets:
  - `lib/features/ai_assistant/`
  - `functions/` (or inference backend)
- Acceptance criteria:
  - Summaries are generated for completed sessions.
  - Sentiment insights are visible in teacher-facing analytics.

### P2-017 Teacher Pro and analytics v1
- Status: `TODO`
- Priority: `P2`
- Depends on: `P2-008`, `P2-013`
- Scope:
  - Add analytics cards (retention, conversion, no-show trends, revenue patterns).
  - Add Pro-tier feature guardrails (e.g., advanced analytics visibility).
- File targets:
  - `lib/features/dashboard/teaching/`
  - `lib/features/subscriptions/`
- Acceptance criteria:
  - Analytics are queryable and accurate for selected windows.
  - Pro-only features are correctly gated.

## Cross-Cutting: Quality, Security, and Release

### P2-018 Rules and policy test suite expansion
- Status: `TODO`
- Priority: `P0`
- Depends on: `P2-003`, `P2-007`, `P2-014`
- Scope:
  - Expand emulator tests for wallet transitions, non-withdrawable volunteer credits, group access, no-show outcomes.
- File targets:
  - `tests/firestore.rules.test.js`
  - `tests/` (additional JS/TS policy tests)
- Acceptance criteria:
  - All critical policy scenarios covered by automated tests.
  - Regression test run is stable and reproducible.

### P2-019 Mobile readiness and platform delivery
- Status: `TODO`
- Priority: `P1`
- Depends on: `P2-013`
- Scope:
  - iOS/Android readiness for push + lesson workflows.
  - Validate mobile critical paths and app-store-release constraints.
- File targets:
  - `ios/`
  - `android/`
  - mobile release docs
- Acceptance criteria:
  - Mobile smoke tests pass for auth, booking, group, wallet, notifications.

### P2-020 Definition of Done and release checklist
- Status: `TODO`
- Priority: `P0`
- Depends on: All Phase 2 tickets
- Scope:
  - Final gate checklist:
    - `flutter analyze` clean
    - `flutter test` passing
    - rules/policy test suite passing
    - live E2E script validated
    - docs/roadmap updated
- File targets:
  - `README.md`
  - `docs/phase2_task_board.md`
  - release notes/changelog
- Acceptance criteria:
  - Phase 2 can be demoed end-to-end with production-like data and policy behavior.

### P2-021 Admin Ops Console (MVP)
- Status: `IN_PROGRESS`
- Priority: `P1`
- Depends on: `P2-003`, `P2-007`, `P2-008`, `P2-009`, `P2-010`
- Scope:
  - Add admin-only internal pages for:
    - user/student/teacher management
    - teacher quality/rating operations
    - booking schedule oversight and forced cancellations
    - review moderation actions
  - Add claim-based admin route guard and navigation gating.
- File targets:
  - `lib/core/config/routes.dart`
  - `lib/core/widgets/main_layout.dart`
  - `lib/features/auth/presentation/providers/auth_providers.dart`
  - `lib/features/admin/presentation/`
- Acceptance criteria:
  - Non-admin users cannot access `/admin*` routes.
  - Admin users can reach users/teachers/reviews/bookings ops pages.
  - Admin actions write audit metadata on affected documents.
- Notes:
  - Added admin routes:
    - `/admin`
    - `/admin/users`
    - `/admin/teachers`
    - `/admin/reviews`
    - `/admin/bookings`
  - Added `isAdminUserProvider` (custom claim `admin == true`) and route-level guard in router redirect.
  - Added admin navigation visibility in main layout (desktop and mobile).
  - Added admin MVP screens with management actions:
    - `AdminDashboardScreen`
    - `AdminUsersScreen`
    - `AdminTeachersScreen`
    - `AdminReviewsScreen`
    - `AdminBookingsScreen`
