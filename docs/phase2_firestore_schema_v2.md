# Phase 2 Firestore Schema v2 (Draft)

Date: March 5, 2026
Status: Draft for `P2-002`

## Goals
- Support Credits Wallet with regulated payout lifecycle.
- Support Group Lessons and enrollments.
- Support Service Learning and certification.
- Support policy/governance events (no-show and quality guardrails).

## Collections

### 1) `wallets/{uid}`
Purpose: current wallet summary for a user.

Fields:
- `uid` (string)
- `pendingBalance` (number)
- `availableBalance` (number)
- `volunteerBalance` (number) // non-withdrawable
- `currency` (string, default `USD`)
- `kycStatus` (string: `none|pending|verified|rejected`)
- `withdrawalThreshold` (number)
- `updatedAt` (timestamp)

### 2) `wallet_transactions/{txId}`
Purpose: immutable ledger for all credit mutations.

Fields:
- `txId` (string)
- `uid` (string)
- `type` (string: `lesson_earning|refund|withdrawal|penalty|volunteer_earning|tip_in|tip_out|adjustment`)
- `sourceBookingId` (string?)
- `sourceLessonId` (string?)
- `amount` (number)
- `currency` (string)
- `bucket` (string: `pending|available|volunteer`)
- `withdrawable` (bool)
- `status` (string: `pending|applied|reversed|failed`)
- `availableAt` (timestamp?) // cooling release target
- `metadata` (map)
- `createdAt` (timestamp)

### 2b) `wallet_withdrawal_requests/{requestId}`
Purpose: learner/teacher initiated withdrawal requests gated by policy checks.

Fields:
- `uid` (string)
- `amount` (number)
- `status` (string: `pending|approved|rejected|processed`)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

### 2c) `booking_settlements/{bookingId}`
Purpose: immutable-ish settlement state for booking-level fund holding and release.

Fields:
- `bookingId` (string)
- `learnerId` (string)
- `teacherId` (string)
- `amount` (number)
- `currency` (string)
- `route` (string: `teacher_direct|organization_escrow`)
- `status` (string: `held|released|failed`)
- `heldAt` (timestamp?)
- `releasedAt` (timestamp?)
- `reason` (string?)
- `updatedAt` (timestamp)

### 2d) `organization_funds/{fundId}`
Purpose: central fund escrow balances.

Fields:
- `ownerId` (string, e.g. `organization`)
- `escrowBalance` (number)
- `updatedAt` (timestamp)

### 2e) `teacher_escrow/{teacherId}`
Purpose: teacher-direct escrow balances before release to wallet pending.

Fields:
- `ownerId` (string teacher uid)
- `escrowBalance` (number)
- `updatedAt` (timestamp)

### 3) `group_lessons/{lessonId}`
Purpose: teacher-defined group lesson sessions.

Fields:
- `lessonId` (string)
- `teacherId` (string uid)
- `teacherDocId` (string)
- `title` (string)
- `description` (string)
- `language` (string)
- `level` (string)
- `capacity` (number)
- `pricePerSeat` (number)
- `status` (string: `scheduled|in_progress|completed|cancelled`)
- `scheduledAt` (timestamp)
- `durationMinutes` (number)
- `enrolledCount` (number)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

### 4) `group_enrollments/{enrollmentId}`
Purpose: learner-seat membership records.

Fields:
- `enrollmentId` (string)
- `lessonId` (string)
- `learnerId` (string)
- `status` (string: `enrolled|cancelled|attended|no_show`)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

Recommended deterministic id:
- `{lessonId}_{learnerId}`

### 5) `service_learning_hours/{recordId}`
Purpose: verifiable volunteer teaching hour entries.

Fields:
- `recordId` (string)
- `teacherId` (string)
- `lessonId` (string)
- `hours` (number)
- `language` (string)
- `ratingSnapshot` (number)
- `createdAt` (timestamp)

### 6) `certificates/{certificateId}`
Purpose: generated service-learning certificates.

Fields:
- `certificateId` (string)
- `uid` (string)
- `totalHours` (number)
- `languages` (array<string>)
- `averageRating` (number)
- `fileUrl` (string)
- `issuedAt` (timestamp)
- `metadata` (map)

### 7) `no_show_events/{eventId}`
Purpose: no-show policy trail.

Fields:
- `eventId` (string)
- `bookingId` (string)
- `teacherId` (string)
- `learnerId` (string)
- `actor` (string: `teacher|learner|system`)
- `penaltyApplied` (bool)
- `penaltyAmount` (number)
- `createdAt` (timestamp)

### 8) `teacher_quality_events/{eventId}`
Purpose: rating-threshold warnings/freeze actions.

Fields:
- `eventId` (string)
- `teacherId` (string)
- `windowSize` (number)
- `rollingAverage` (number)
- `action` (string: `warning|freeze|unfreeze`)
- `reason` (string)
- `createdAt` (timestamp)

## Required Composite Indexes (Proposed)

1. `wallet_transactions`
- `uid` ASC, `createdAt` DESC
- `uid` ASC, `bucket` ASC, `createdAt` DESC
- `uid` ASC, `status` ASC, `availableAt` ASC

1b. `wallet_withdrawal_requests`
- `uid` ASC, `status` ASC, `createdAt` DESC

2. `group_lessons`
- `status` ASC, `scheduledAt` ASC
- `teacherId` ASC, `scheduledAt` DESC
- `language` ASC, `status` ASC, `scheduledAt` ASC

3. `group_enrollments`
- `lessonId` ASC, `status` ASC, `createdAt` DESC
- `learnerId` ASC, `createdAt` DESC

4. `service_learning_hours`
- `teacherId` ASC, `createdAt` DESC

5. `teacher_quality_events`
- `teacherId` ASC, `createdAt` DESC

## Migration Notes
- Maintain compatibility with existing `bookings` and `reviews` phase-1 docs.
- Extend `bookings` with optional no-show fields for policy automation:
  - `status` may include `no_show` when attendance fails
  - `noShowActor` (`learner|teacher`) identifies the accountable side
- Extend `bookings` with optional settlement routing:
  - `paymentRoute` (`teacher_direct|organization_escrow`) determines where learner payment is held before teacher release.
- Use background migration for any teacher doc reference normalization.
- Do not mutate historical financial rows; append-only ledger only.

## Open Decisions
- Confirm withdrawal threshold default (`500` vs `1000`).
- Confirm single-currency vs per-user currency.
- Confirm whether group lesson pricing supports fixed total split in Phase 2.0.
