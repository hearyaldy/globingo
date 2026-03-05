# Globingo

A decentralized language learning platform that serves as a "global trust layer" for education. Globingo enables peer-to-peer language teaching where anyone can be both a learner and a teacher.

## Vision

Globingo shifts the paradigm from credential-based trust to **performance-based reputation**. Teaching quality is quantified through real-world student outcomes and verified data points rather than static diplomas.

## Core Concepts

### Dual Identity System
Every user has a single account that can toggle between:
- **Learning Mode** - Browse teachers, book lessons, leave reviews
- **Teaching Mode** - Set availability, manage bookings, track earnings

### Skill Radar
A pentagonal visualization that converts qualitative reviews into an at-a-glance metric of trust. Teachers are rated on 5 dimensions:
1. **Clear Explanation** - Pedagogical clarity
2. **Patient** - Soft skills and student support
3. **Well Prepared** - Professionalism and lesson organization
4. **Helpful** - Actual educational value delivered
5. **Fun** - Emotional connection to the learning process

### Zero Barrier to Entry
No formal credentials required. Reputation is built through transaction-validated quality.

## Features (MVP - Phase 1)

### For Learners
- [x] Browse and search teachers by language, price, and rating
- [x] View teacher profiles with Skill Radar and reviews
- [x] Book lessons with teacher lesson-offer selection
- [x] Manage upcoming/completed/cancelled lessons in My Courses
- [x] Leave 5-dimension reviews (gated to completed lessons)

### For Teachers
- [x] Toggle teaching mode and onboarding for teacher/both roles
- [x] Set hourly rate, bio, teaching languages, active status
- [x] Accept/reject booking requests
- [x] Manage lesson offers (create/edit/delete/activate)
- [x] View teaching dashboard with pending bookings and review metrics
- [x] Track Skill Radar performance from student reviews

### General
- [x] Firebase authentication (register, login, logout)
- [x] Profile management with Firestore persistence
- [x] Language preferences with save support
- [x] Localization baseline wired (English ARB + delegates)
- [x] Firestore security rules with owner checks + admin claim support
- [x] Notification settings persistence
- [ ] Payment integration (Stripe) - deferred to Phase 1.5

## Current Phase 1 Progress (Updated: March 5, 2026)

### Implemented
- Firebase Auth + Firebase Firestore integration
- Role-aware onboarding (Student / Teacher / Both)
- Learning/Teaching mode switch with routing
- Teacher profile setup and editing
- Settings persistence to Firestore (profile, language preferences, teacher profile)
- Notification settings persistence to Firestore
- Teacher lesson offers (`lesson_offers`) and student-visible offer listing
- Booking request flow with teacher approval/rejection
- Lesson room route (`/lesson/:bookingId`) with:
  - enter-window validation (15 minutes before start to 30 minutes after end)
  - status progression (`accepted -> in_progress -> completed`)
  - session info, notes area, basic local chat UI, optional call link display
- Review submission flow tied to completed bookings only
- Teacher and learner dashboards wired to Firestore data
- Localization baseline (English ARB + delegates wired)
- Standardized loading/error/empty async UI states across major screens
- Core journey unit tests (route guard, booking status decisions, review eligibility)

### In Progress / Partial
- My Courses and Home data cleanup for legacy/mock records in Firestore
- Some teacher/profile/bookings records still depend on historical data shapes (doc id vs uid)

### Not Implemented Yet
- Stripe payment flow (deferred to Phase 1.5)
- Real-time video/call provider integration (Agora/Zoom/WebRTC)
- Persistent lesson notes/chat backend
- Admin UI screens (rules support prepared, UI not complete)

## Phase 1 Closure TODO (Updated: March 5, 2026)

### Verified Today
- [x] `flutter analyze` clean (March 5, 2026)
- [x] `flutter test` passing (March 5, 2026)
- [x] Firestore rules emulator test harness added (`tests/firestore.rules.test.js`, `npm run rules:test`)
- [x] `npm run rules:test` passed in Firestore Emulator (March 5, 2026)
- [x] Typed repository scaffolding added for `users`, `teachers`, `bookings`, `reviews`; booking creation moved into repository.
- [x] `MyCourses` and `LeaveReview` flows migrated to repository-backed Firestore access.
- [x] `TeachingDashboard` booking decision path migrated to repository-backed reads/writes.
- [x] `FindTeachers` and `TeacherProfile` migrated to repository-backed teacher/review/offer reads.
- [x] `Settings` and `ModeToggle` now persist through `UserRepository`/`TeacherRepository`.
- [x] `Login`, `Onboarding`, and `LearningDashboard` migrated to repository-backed access.
- [x] `TeacherOffers` and `LessonRoom` migrated to repository-backed booking/offer actions.

### Remaining to Close Phase 1
- [ ] P1-001: Final Firebase bootstrap validation for required platforms (resolve iOS config decision for Phase 1 scope).
- [x] P1-002: Add/complete automated tests for auth repository success + error paths.
- [ ] P1-003: Complete runtime validation of auth screens against configured Firebase project.
- [ ] P1-004: Complete runtime validation of route guards/session-aware redirects.
- [ ] P1-005: Validate first-login profile bootstrap in live Firestore.
- [x] P1-006: Finish migration to typed Firestore repositories and remove critical direct/mock data dependencies.
- [ ] P1-007: Finalize booking persistence path and align legacy `docId` vs `uid` data shape.
- [ ] P1-008: Complete end-to-end verification for teacher accept/reject reflected in learner views.
- [ ] P1-009: Complete review/teacher metrics validation and optional denormalized aggregate decision.
- [x] P1-015: Execute Firestore Emulator security-rules tests and confirm pass.
- [ ] P1-018: Finish release Definition of Done checklist and mark Phase 1 tracker tickets as complete.

Live validation script: `docs/phase1_e2e_demo_checklist.md`

Phase 2 start decision: **GO (conditional)**  
Manual live Firebase E2E validation for `P1-003/004/005/007/008/009` is pending and must be completed before formally marking Phase 1 as closed.

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.x |
| State Management | Riverpod |
| Navigation | GoRouter |
| HTTP Client | Dio |
| Local Storage | SharedPreferences, Hive |
| Payments | Stripe |
| Charts | fl_chart (for Skill Radar) |
| Internationalization | Flutter Intl (ARB files) |

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App widget with providers and routing
│
├── core/                     # Shared utilities and widgets
│   ├── constants/            # Colors, strings, typography
│   ├── config/               # App config, routes, theme
│   ├── utils/                # Helpers (date, currency, validators)
│   ├── network/              # API client and interceptors
│   └── widgets/              # Reusable widgets (Skill Radar, etc.)
│
├── features/                 # Feature modules
│   ├── auth/                 # Authentication
│   ├── mode_switch/          # Learning/Teaching toggle
│   ├── dashboard/
│   │   ├── learning/         # Student dashboard
│   │   └── teaching/         # Teacher dashboard
│   ├── teachers/             # Find and view teachers
│   ├── booking/              # Lesson booking flow
│   ├── lessons/              # My courses management
│   ├── reviews/              # Review system
│   ├── payment/              # Payment processing
│   └── settings/             # User settings
│
├── l10n/                     # Localization files
│   ├── app_en.arb
│   ├── app_zh.arb
│   └── app_ja.arb
│
└── services/                 # External services
    ├── storage_service.dart
    ├── notification_service.dart
    └── stripe_service.dart
```

## Getting Started

### Prerequisites
- Flutter SDK 3.16.0 or higher
- Dart SDK 3.2.0 or higher
- iOS: Xcode 15+ (for iOS development)
- Android: Android Studio with SDK 34+

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd globingo
```

2. Install dependencies
```bash
flutter pub get
```

3. Set up environment variables
```bash
cp .env.example .env
# Edit .env with your API keys
```

4. Run the app
```bash
# Development
flutter run

# Release
flutter run --release
```

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test
```

## Pricing Model

| Duration | Price (USD) |
|----------|-------------|
| 30 minutes | $13 |
| 60 minutes | $26 |
| 90 minutes | $39 |

*Platform commission: 15% on paid transactions*

## Design Reference

UI mockups are located in `lib/assets/images/`. Key screens include:
- Teacher Dashboard with Skill Radar
- Learning Dashboard with upcoming lessons
- Find Teachers with filters
- Teacher Profile with booking sidebar
- Booking flow (calendar, time, payment)
- Review submission with live Skill Radar preview
- Settings (profile, languages, teacher info, notifications)

## Roadmap

### Phase 1 (MVP) - Current
- Core dual-identity system (implemented)
- Teacher search and profiles (implemented)
- 1-on-1 booking system (implemented)
- Mandatory Skill Radar reviews (implemented for completed lessons)
- Stripe payment integration (deferred to Phase 1.5)

### Phase 1.5 (Post-MVP Stabilization)
- Stripe payment integration

Detailed execution tracker: [Phase 1 Firebase Task Board](docs/phase1_firebase_task_board.md)

### Phase 2 (Future)
- Service Learning & PDF certificates
- Credits Wallet with 7-day cooling period
- AI Teaching Assistant (lesson summaries, sentiment analysis)
- Group lessons
- Native push notifications
- Advanced analytics for teachers

Detailed execution tracker: [Phase 2 Task Board](docs/phase2_task_board.md)
Scope lock: [Phase 2 Scope Lock](docs/phase2_scope_lock.md)
Schema draft: [Phase 2 Firestore Schema v2](docs/phase2_firestore_schema_v2.md)

## API Documentation

Backend API documentation: *[To be added]*

### Key Endpoints (Planned)
```
POST   /auth/register
POST   /auth/login
GET    /teachers
GET    /teachers/:id
POST   /bookings
GET    /bookings
PUT    /bookings/:id/status
POST   /reviews
GET    /dashboard/teacher
GET    /dashboard/learner
```

## Contributing

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Commit your changes (`git commit -m 'Add amazing feature'`)
3. Push to the branch (`git push origin feature/amazing-feature`)
4. Open a Pull Request

## Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` before committing
- Format code with `dart format .`

## License

*[License to be determined]*

## Contact

*[Contact information to be added]*

---

**Globingo** - Quantifying trust in global education.
