# TODOS — Tempo

Engineering review decisions and deferred items.
Last updated: 2026-06-29 by /plan-eng-review.

---

## Pre-CloudKit (before M5 — do before flipping ModelContainer to CloudKit)

### A1: Remove @Attribute(.unique) from DayLog.day

**Why deferred:** CloudKit doesn't support uniqueness constraints. Kept for local dev (extra safety
net). Must be removed before enabling the CloudKit ModelContainer configuration — the attribute
will either be silently dropped or cause a crash at CloudKit enrollment time.

**What to do:**
1. In `DayLog.swift`, confirm `var day: Date` has NO `@Attribute(.unique)` decorator.
2. The upsert fetch-first logic is the sole uniqueness guard — verify it's in place at all save call sites.
3. If you already have data with the unique constraint and need to migrate, create a lightweight
   SwiftData migration version to drop the constraint before enabling CloudKit.

**Risk if skipped:** CloudKit enrollment fails or silently misbehaves on the unique attribute.

---

## Weekend 1 — Implementation checklist

- [ ] Xcode project: iOS 17+, SwiftUI, SwiftData. Bundle ID: `com.<yourname>.tempo` or similar.
- [ ] Add `TempoTests` Swift Testing target.
- [ ] Implement 4 SwiftData models: `DayLog`, `MetricDefinition`, `MetricSample`, `ProgressPhoto`.
- [ ] Add `WeightUnit: String, CaseIterable` and `LengthUnit: String, CaseIterable` enums.
- [ ] Implement `TempoUnits` helper (NOT named `UnitConverter` — shadows Foundation type).
- [ ] Implement `weeklyAverages(from:)` — pure function, returns `[WeeklyAverage]`.
- [ ] Write all 7 mandatory Swift Testing test cases for `weeklyAverages()` (see design doc).
- [ ] Write `TempoUnits` conversion tests (kg↔lb, cm↔in, rounding).
- [ ] Implement fetch-first MetricDefinition seeding (idempotent).
- [ ] Build `TodayView` with full upsert contract (fetch-or-create, updatedAt = Date(), Save).
- [ ] Build `HomeView` — computes `weeklyAverages()` once, passes to `TrendHeaderView` + `WeightTrendChart`.
- [ ] Build `TrendHeaderView` (this week avg + delta vs last week).
- [ ] Build `WeightTrendChart` (daily dots + weekly avg overlay, range selector 1W/1M/3M/All).
- [ ] Build `MeasurementPanel` (waist always visible).
- [ ] Build `PhotoCaptureView` (3 slots, PhotosPicker, one-per-angle guard in save path).

## Weekend 2+ — checklist

- [ ] Onboarding (gate on `@AppStorage("hasCompletedOnboarding")`).
- [ ] History tab (list with photo presence icons ONLY — never load imageData in list rows).
- [ ] Settings (unit toggles, starting weight, measurement management, max 3 total).
- [ ] Photo Compare screen (two dates, front/side/back side-by-side).
- [ ] Photo alignment guidance (3×3 ZStack grid overlay on camera).

## M5 — CloudKit (after Apple Developer Program enrollment)

- [ ] **A1: Remove `@Attribute(.unique)` from `DayLog.day`** (see above).
- [ ] Flip `ModelContainer` to CloudKit-backed configuration.
- [ ] Verify all relationship optionality (`metric: MetricDefinition?`, `dayLog: DayLog?`) passes CloudKit validation.
- [ ] Test sync on two devices.
