# CLAUDE.md — Tempo

> A dead-simple, personal fitness-progress tracker for iPhone.
> This file is the source of truth for the project. Read it fully before writing code.

---

## 1. What we're building

**Tempo** is a minimal iOS app for tracking personal fitness progress. It does three things and nothing more:

1. **Log daily weight.**
2. **Log progress photos** — up to three per day (front, side, back), all optional.
3. **Log body measurements** — waist is the priority/default; the user may add up to two more (e.g. arm, chest, hips, thigh).

On top of the raw logs, Tempo surfaces the signal that actually matters: **weekly average weight**, because day-to-day weight fluctuates and the weekly average is a truer picture of the trend.

This is a **personal-use app**. It is **not** going to be commercialized or published to the App Store. Build accordingly — favor simplicity and the shortest correct path over scalability, abstraction, or "production hardening."

---

## 2. Design philosophy (read this twice)

Most fitness trackers fail by being bloated. Tempo's entire reason to exist is the opposite. Every decision should be filtered through:

- **Ruthless simplicity.** If a feature isn't in this spec, don't build it. Ask first.
- **One-tap logging.** Logging today's weight should take seconds.
- **Calm, uncluttered UI.** Lots of whitespace, large legible numbers, few controls per screen.
- **Local-first.** The app must be fully functional with no network. Sync is additive.
- **Shallow navigation.** No deep menu trees. A small tab bar is the whole app.

### Non-goals (do NOT build these)
- No accounts, usernames, or passwords (sync uses the Apple ID implicitly — see §7).
- No social features, sharing, feeds, or friends.
- No calorie/macro/workout/step tracking.
- No ads, analytics, telemetry, or third-party SDKs.
- No onboarding tutorials, tooltips, or gamification.
- No Android, iPad-specific, or web version (iPhone only; it can run on iPad as-is).

---

## 3. Tech stack

| Concern | Choice |
|---|---|
| Language / UI | **Swift + SwiftUI** |
| Min target | **iOS 17.0** |
| Persistence | **SwiftData** |
| Sync | **CloudKit** (private database) via SwiftData's CloudKit integration |
| Charts | **Swift Charts** (Apple, built-in) |
| Photos | **PhotosUI** (`PhotosPicker`) + camera capture |
| Biometric lock (optional) | **LocalAuthentication** (Face ID / passcode) |

**Dependencies:** prefer zero. Use only Apple frameworks. Do not add Swift packages without asking.

> **Fallback (only if no Mac/Xcode is available):** React Native via **Expo**, with **Supabase** (Postgres + Storage) for the account/sync/photo layer. Do not build this unless explicitly told to — native is the chosen path.

---

## 4. Units

Units are **switchable in Settings**:
- Weight: **kg ↔ lb**
- Length: **cm ↔ in**

**Storage rule:** always persist canonical **metric** values — weight in **kilograms (Double)**, lengths in **centimeters (Double)**. Convert only at the display/input boundary. Never store the user-facing unit on the record itself.

Conversion constants:
- `1 kg = 2.2046226218 lb`
- `1 in = 2.54 cm`

Provide a single `UnitFormatter` / conversion helper used everywhere. Round display values sensibly (weight to 0.1, lengths to 0.1).

---

## 5. Data model

Use SwiftData `@Model` classes. Photos use external storage so CloudKit handles them efficiently.

### `DailyEntry`
One record per calendar day. The day is the unique key (normalize `date` to start-of-day).

```
@Model DailyEntry
  id: UUID
  date: Date              // normalized to startOfDay; unique
  weightKg: Double?       // optional — a day may have only a photo or measurement
  frontPhoto: Data?       @Attribute(.externalStorage)
  sidePhoto:  Data?       @Attribute(.externalStorage)
  backPhoto:  Data?       @Attribute(.externalStorage)
  measurements: [MeasurementValue]   // relationship, cascade delete
  createdAt: Date
  updatedAt: Date
```

Logging is an **upsert per day**: if an entry for that date exists, edit it; otherwise create it. The user can backfill past dates.

### `MeasurementType` (configuration)
```
@Model MeasurementType
  id: UUID
  name: String           // e.g. "Waist", "Left Arm"
  isEnabled: Bool
  isDefault: Bool        // true for Waist; cannot be removed
  sortOrder: Int
```
- Seed **"Waist"** as `isDefault = true`, always enabled, not removable.
- User may enable **up to 2 additional** measurement types (max 3 total tracked).

### `MeasurementValue`
```
@Model MeasurementValue
  id: UUID
  type: MeasurementType  // relationship
  valueCm: Double        // canonical cm
  entry: DailyEntry      // inverse relationship
```

### Photo handling
- Capture from camera or pick from library (`PhotosPicker`).
- Downscale to max ~1080px on the long edge and JPEG-compress (~0.7 quality) before saving. We don't need full-res; keep storage and sync light.
- Each of the three slots (front/side/back) is independently optional.

---

## 6. Screens & navigation

Tab bar with **three tabs**, plus Settings reachable from the Home toolbar.

### Tab 1 — Home (Dashboard)
The at-a-glance progress view. Top to bottom:
- **Current weight** (latest logged), with delta vs. starting weight and delta vs. last week's average.
- **This week's average weight**, with the change from last week's average (this is the headline trend metric — make it prominent).
- **Weight chart** (Swift Charts): daily points as one series, the **weekly-average line** overlaid as a second series. Range selector: `1W · 1M · 3M · All`.
- **Waist** current value + small trend indicator.
- A prominent **"Log today"** button.
- Thumbnail of the most recent photo set → taps into Photo Compare.

### Tab 2 — Log
The entry editor. Defaults to **today** but has a date picker to backfill.
- Weight input (in the user's chosen unit; converts to kg on save).
- Photos: three slots — Front / Side / Back. Each: tap to capture or pick; long-press/clear to remove. All optional.
- Measurements: Waist field always shown; any enabled extra measurements shown below.
- **Save** upserts the day's entry.

### Tab 3 — Progress (History)
- Scrollable list of all entries, newest first (date, weight, which photos exist, waist).
- Tap an entry to view/edit it.
- Charts section: weight (daily + weekly average overlay) and a chart per enabled measurement.

### Photo Compare (pushed from Home/Progress)
- Pick two dates; show Front/Side/Back side-by-side for each.
- Simple date scrubber is a nice touch but not required for v1.

### Settings
- Units: weight (kg/lb), length (cm/in).
- Manage measurements: Waist (locked on); add/remove up to 2 extras.
- Starting weight (set during onboarding; editable here).
- iCloud sync status (read-only indicator).
- **Optional:** Face ID / passcode app lock (toggle).
- **Optional:** Export data (CSV of logs + photos to a zip via share sheet).

### First launch (Onboarding) — keep it to one or two screens
- Choose units.
- Enter **starting weight**.
- Optionally take/pick the first photo set.
- Optionally enter starting waist (+ choose up to 2 extra measurements).
- No login screen — sync is implicit via Apple ID (see §7).

---

## 7. Accounts & sync

- **There is no custom auth.** "Account" = the user's **Apple ID**. SwiftData + CloudKit syncs the private database across the user's own devices automatically. Do not build login/signup/password UI.
- Configure the SwiftData `ModelContainer` with CloudKit (private database). Ensure the schema is CloudKit-compatible (all non-optional relationships need defaults/optionality per CloudKit rules — verify the model passes CloudKit's constraints).
- **Critical build note:** enabling the CloudKit capability requires enrollment in the **Apple Developer Program ($99/yr)**. Free provisioning **cannot** enable iCloud/CloudKit.
  - Therefore: **build and ship everything local-first.** The app must run, log, and chart with **zero** cloud config.
  - Structure the persistence layer so CloudKit is a single switch to flip (local `ModelConfiguration` vs. CloudKit-backed `ModelConfiguration`) once enrolled. Don't let sync block local development.
- **Privacy:** photos are sensitive. Keep them in the app's private container only. The optional Face ID lock adds a layer for the on-device case.

---

## 8. Key logic — weekly average weight

This is the feature that justifies the app, so get it exactly right.

- **Week definition:** Monday–Sunday. (Use `Calendar` with `firstWeekday = 2`. If you'd rather respect the device locale's first weekday, make it a constant in one place and document it — but default to Monday.)
- **Weekly average** = arithmetic mean of all **logged daily weights** within that week. **Skip days with no weight** (don't treat missing as zero).
- A week with at least **one** logged weight has an average; weeks with none are gaps.
- **Trend** = (this week's average) − (last week's average). Show as a signed delta with direction (down is "good" for most goals, but stay neutral — just show the number and arrow, don't editorialize).
- On the chart, plot daily weights as points/light line and the weekly average as a bolder line so the smoothed trend is visually obvious.
- All averaging happens in canonical kg; convert for display only.

Implement this as a pure, **unit-tested** function: given `[DailyEntry]`, return `[(weekStart: Date, average: Double, count: Int)]`. Keep it independent of the view layer.

---

## 9. Coding conventions & guardrails

- **Architecture:** plain SwiftUI + SwiftData. Use `@Query` in views where it's clean; pull non-trivial logic (weekly average, conversions, stats) into small testable helper types. Don't import a heavyweight architecture pattern — no Redux-style frameworks, no over-abstraction.
- **One feature at a time.** Follow the build order in §10. Don't scaffold features from §2's non-goals.
- **No new dependencies** without asking.
- **Tests:** write unit tests for the weekly-average function and the unit conversions at minimum.
- **Comments:** explain *why*, not *what*. Keep it lean.
- **When unsure, ask** rather than inventing scope. This app's whole value is restraint.

---

## 10. Suggested build order (milestones)

**M1 — Skeleton & weight logging (local only)**
Project setup (iOS 17, SwiftUI, SwiftData local), data models, units setting, onboarding (units + starting weight), Log tab (weight only, upsert-per-day), Home showing latest weight + a basic Swift Chart.

**M2 — Measurements & photos**
Waist + up to 2 configurable measurements; three optional photo slots with capture/pick, downscaling, storage, and display.

**M3 — Weekly average (the headline feature)**
Pure weekly-average function + tests, dashboard cards (current, weekly average, deltas), weekly-average overlay on the weight chart, range selector.

**M4 — History & compare**
Progress tab (entry list, edit), measurement charts, Photo Compare screen.

**M5 — Sync & polish (after Developer Program enrollment)**
Flip SwiftData to CloudKit; optional Face ID lock; optional CSV/zip export. Final UI polish.

---

## 11. Running it on a real iPhone (notes for later)

- Open in **Xcode** on a Mac. Set a unique bundle identifier, enable "Automatically manage signing," sign in with your Apple ID, plug in your iPhone, and Run.
- With a **free** Apple ID, the installed build expires after ~7 days and needs re-running from Xcode. With the **$99/yr Apple Developer Program**, builds last a year **and** you can enable iCloud/CloudKit sync.
- Until enrolled, keep CloudKit off and use the local store — everything except cross-device sync works.

---

*End of spec. Build the smallest thing that satisfies §1, in the order of §10, honoring the restraint in §2.*
