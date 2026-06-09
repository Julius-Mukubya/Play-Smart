# Test Context

## Test Philosophy

- Tests are a gate, not an afterthought
- No feature unit is complete until its tests pass
- Tests must be defined before or during implementation, not after
- If a test cannot be written, the requirement is not clear enough — resolve it first

---

## Test Strategy

Prioritise integration and flow tests because the product is interaction-heavy — the critical paths are multi-step (upload → discover → shortlist → message, or sign up → verify → post opportunity → receive application). Unit test pure logic functions (badge eligibility, payment tier resolution, capacity checks). Manual checklist for visual and mobile-specific testing (video playback quality, compression output, touch interactions).

---

## Test Frameworks and Tools

| Layer         | Tool / Approach                  | Notes                                               |
| ------------- | -------------------------------- | --------------------------------------------------- |
| Unit tests    | [e.g. Jest / Vitest]             | Pure logic: badge rules, payment tier logic, capacity checks |
| Integration   | [e.g. Supertest / Playwright API] | API routes: auth, profile mutations, payment webhooks |
| E2E / UI      | [e.g. Playwright / Detox]        | Critical user flows end to end                      |
| Manual checks | Checklist (this file)            | Video playback, mobile layout, payment provider UIs, notification delivery |

---

## Test Scope Per Layer

### UI / Component Tests

For each new screen or component, verify:

- [ ] Renders without errors
- [ ] Displays correct content for the default state
- [ ] Displays correct content for the empty state
- [ ] Displays correct content for the error/loading state
- [ ] Interactive elements (buttons, inputs, selects) respond correctly
- [ ] Trust badges render correct icon and color for all three levels (Self-Reported, Coach-Endorsed, Club-Verified)
- [ ] Feature-gated actions (shortlist, message, analytics) are correctly locked for free / unverified accounts
- [ ] Mobile layout is correct at 375px and 390px viewport widths

### API Route Tests

For each new API route, verify:

- [ ] Returns correct status code for valid input
- [ ] Returns 400 for missing or invalid input
- [ ] Returns 401 for unauthenticated requests
- [ ] Returns 403 for wrong account type (e.g. athlete calling recruiter-only route) or unverified account
- [ ] Returns 403 for correct account type but insufficient subscription tier
- [ ] Returns correct response shape
- [ ] Does not expose private fields (e.g. private notes to non-owners, full analytics to free tier users)

### Business Logic / Unit Tests

- [ ] Trust badge upgrade only triggers with the correct actor (verified coach, verified club)
- [ ] Subscription tier correctly determines feature access (shortlist limits, trial post limits, analytics depth)
- [ ] Opportunity capacity check closes posting at the correct threshold
- [ ] Payment grace period: downgrade to free tier after 3 days of failed payment, not immediately
- [ ] Under-18 flag is set correctly based on date of birth

### Integration Tests

For each connected flow, verify:

- [ ] Athlete signs up → completes profile → profile appears in recruiter search
- [ ] Recruiter shortlists athlete → shortlist event triggers analytics entry for premium athletes
- [ ] Message request sent → athlete sees pending request → accepts → conversation thread opens
- [ ] Message request sent → athlete declines → thread does not open
- [ ] Club confirms roster entry → Club-Verified badge appears on athlete profile
- [ ] Opportunity posted with capacity 10 → 10 applications received → posting closes automatically
- [ ] Payment webhook received → subscription tier updates → gated features unlock correctly
- [ ] Failed payment → grace period starts → 3 days later account downgrades to free tier

---

## Feature Unit Test Template

Copy this block for each feature unit being tested. Fill it in before or during implementation.

```
## Feature: [Feature name]
Branch: feature/[branch-name]

### What this unit does
[One sentence description]

### Tests

#### UI
- [ ] [Specific check]
- [ ] [Specific check]

#### API
- [ ] [Specific check]
- [ ] [Specific check]

#### Logic
- [ ] [Specific check]

#### Integration
- [ ] [Specific check]

### Definition of Done
All boxes above are checked.
`npm run build` passes.
No invariant in `architecture.md` was violated.
Commit logged in `progress-tracker.md`.
```

---

## Critical Manual Checklist (Mobile)

Run these manually before marking any core feature complete:

- [ ] Video uploads compress successfully and play back at acceptable quality on a simulated slow mobile connection
- [ ] Bottom tab navigation works correctly on Android and iOS
- [ ] Filter bottom sheet opens and closes correctly on mobile
- [ ] Payment flow completes successfully with MTN Mobile Money (test mode)
- [ ] Payment flow completes successfully with Flutterwave test card
- [ ] Push notification received on device after shortlist event (premium athlete)
- [ ] Athlete under 18: additional restrictions applied correctly

---

## Definition of Done (Global)

A feature unit is done when ALL of the following are true:

1. All test boxes for the unit are checked
2. `npm run build` (or equivalent) passes with no errors
3. No invariant defined in `architecture.md` was violated
4. `progress-tracker.md` Git Log has a new entry
5. Changes are committed to GitHub with a conventional commit message

---

## Known Failing Tests

| Test | Reason skipped | Fix planned |
| ---- | -------------- | ----------- |
| —    | —              | —           |
