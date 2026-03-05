# Phase 2 Scope Lock (v1)

Date: March 5, 2026
Owner: Product + Engineering

## Decision
Phase 2 development is approved to start in parallel with pending manual Phase 1 E2E validation.

## In Scope (Phase 2.0)
- Credits Wallet
  - pending -> available lifecycle
  - 7-day cooling period
  - withdrawal threshold + KYC Lite gating
- Risk Governance
  - no-show penalties
  - quality-protection thresholds and teaching freeze logic
- Group Learning
  - group lesson create/manage
  - discovery and enrollment
  - group session room + attendance tracking
- Service Learning
  - volunteer mode
  - non-withdrawable volunteer credits
  - service-hour tracking + PDF certification pipeline
- Notifications
  - push notifications for reminders and key lesson events

## Out of Scope (Phase 2.5 / Later)
- AI Teaching Assistant full rollout
  - large-scale personalized recommendations
  - advanced automated coaching workflows
- Teacher Pro commercialization hard launch
  - pricing experiments and advanced upsell funnels
- Deep institutional B2B workflows beyond core certification output

## Feature Flag Policy
New Phase 2 modules must be guarded by compile-time flags in:
- `lib/core/config/feature_flags.dart`

Flags:
- `FLAG_WALLET`
- `FLAG_GROUP_LESSONS`
- `FLAG_SERVICE_LEARNING`
- `FLAG_AI_ASSISTANT`
- `FLAG_PUSH_NOTIFICATIONS`
- `FLAG_TEACHER_ANALYTICS_V1`

## Exit Criteria for Scope Lock
- `docs/phase2_task_board.md` reflects this scope.
- Teams agree on in/out boundaries before implementation expands.
