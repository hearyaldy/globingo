# Phase 1 E2E Demo Checklist (Live Firebase)

Use this checklist to validate the remaining runtime tickets:
- `P1-003` auth screens
- `P1-004` route guards/session redirects
- `P1-005` first-login profile bootstrap
- `P1-007` booking persistence visibility
- `P1-008` teacher accept/reject reflection
- `P1-009` review submission and teacher metrics refresh

## Preconditions
- Firebase project configured and reachable.
- At least 2 test accounts:
  - `learner` account
  - `teacher` account (with `teachingModeEnabled=true`)
- Teacher has at least one active lesson offer.

## 1) Auth + Route Guards (`P1-003`, `P1-004`)
1. Open app in signed-out state.
2. Try to open a protected route (`/dashboard`, `/my-courses`).
3. Verify redirect to `/login`.
4. Sign in with learner account.
5. Verify post-login redirect:
  - to `/onboarding` if onboarding incomplete
  - to `/` if onboarding complete.

Expected:
- Protected pages are blocked for anonymous users.
- Auth pages redirect away for authenticated users with completed onboarding.

## 2) First Login Bootstrap (`P1-005`)
1. Register a brand-new user.
2. Complete minimal onboarding flow.
3. Check Firestore `users/{uid}` for the new account.

Expected:
- `users/{uid}` exists and includes:
  - `uid`, `activeMode`, `learningModeEnabled`
  - `teachingModeEnabled`
  - `hasCompletedOnboarding`
  - `updatedAt`.

## 3) Booking Create Persistence (`P1-007`)
1. As learner, open teacher profile and create a booking from booking screen.
2. Confirm success toast/dialog.
3. Check Firestore `bookings/{slotId}`.
4. Open learner `/my-courses`.

Expected:
- Booking document created with:
  - doc id == `slotId`
  - `slotId`, `learnerId`, `teacherId`, `teacherDocId`
  - `scheduledAt`, `durationMinutes`
  - `status = pending`
  - `createdAt`, `updatedAt`.
- Booking appears in learner upcoming lessons.

## 4) Teacher Accept/Reject Reflection (`P1-008`)
1. Sign in as teacher for that booking.
2. Open teaching dashboard pending list.
3. Accept booking.
4. Switch back to learner and refresh `my-courses`.
5. Repeat with another booking and reject it.

Expected:
- Accept updates status `pending -> accepted`.
- Reject updates status `pending -> rejected`.
- Learner views reflect both state changes.

## 5) Lesson Progress + Review + Metrics (`P1-009`)
1. For accepted booking, open lesson room in allowed time window.
2. Transition status:
  - `accepted -> in_progress -> completed`.
3. As learner, open review screen and submit review.
4. Refresh teacher profile and teaching dashboard.

Expected:
- Review doc exists in `reviews` with:
  - `bookingId`, `reviewerId`, `teacherId`
  - 5-dimension ratings + `overall`
  - `createdAt`, `updatedAt`.
- Duplicate review for same booking is blocked.
- Teacher average rating and skill radar update after refresh.

## 6) Security Sanity (`P1-015` spot check)
Run:
```bash
npm run rules:test
```

Expected:
- Script exits `0`.
- Emulator rules tests pass.

## Sign-off Record
Record run date and tester:
- Date:
- Tester:
- Environment (web/android/ios):
- Pass/Fail by section:
  - Auth + Guards:
  - Profile Bootstrap:
  - Booking Persistence:
  - Teacher Decisions:
  - Review + Metrics:
  - Rules Test:
