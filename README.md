# Tempo

**A dead-simple, personal fitness-progress tracker for iPhone.**

Most fitness apps are bloated with features I'll never use. Tempo does three things, cleanly, and nothing else: track weight, track progress photos, and track body measurements — then surface the one number that actually matters, **weekly average weight**.

This is a personal project. It is not intended for the App Store or public distribution.

---

## What it does

- **Daily weight logging** — one tap to record today's weight.
- **Progress photos** — up to three per day (front, side, back), all optional.
- **Body measurements** — waist by default, plus up to two custom measurements (arm, chest, hips, etc.).
- **Weekly average weight** — the headline feature. Daily weight bounces around; the weekly average smooths the noise and shows the real trend, week over week.
- **Switchable units** — kg/lb and cm/in.
- **Private by default** — local-first, with optional iCloud sync across your own devices via your Apple ID.

## Tech stack

- **Swift + SwiftUI** (iOS 17+)
- **SwiftData** for persistence
- **CloudKit** for private cross-device sync
- **Swift Charts** for the weight & measurement graphs
- **PhotosUI** for photo capture/selection
- Zero third-party dependencies

## Status

🚧 Early development. Built in milestones (see roadmap below).

## Roadmap

- [ ] **M1** — Weight logging + dashboard chart (local only)
- [ ] **M2** — Measurements + progress photos
- [ ] **M3** — Weekly average + trend cards
- [ ] **M4** — History list + photo compare
- [ ] **M5** — iCloud sync, optional Face ID lock, CSV export

## Getting started

> Requires a Mac with the latest Xcode. iPhone running iOS 17+.

```bash
git clone https://github.com/<your-username>/tempo.git
cd tempo
open Tempo.xcodeproj   # (once the project is generated)
```

Then in Xcode: set a unique bundle identifier, enable **Automatically manage signing**, sign in with your Apple ID, connect your iPhone, and Run.

**Notes:**
- A free Apple ID lets you run on-device, but builds expire after ~7 days and need re-running.
- iCloud sync (CloudKit) requires the **Apple Developer Program** ($99/yr). The app runs fully local without it — sync just stays off until you enroll.

## Project notes

The full product spec and build guardrails live in [`CLAUDE.md`](./CLAUDE.md), which is also the working brief for AI-assisted development.

## License

Personal project — all rights reserved. Not licensed for redistribution.
