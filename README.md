# StorageSense

**A plain-language answer to "why is my storage full" — not another swipe-to-delete app.**
StorageSense scans your Photos library on-device and shows you exactly what's taking up the space — screenshots, duplicate bursts, Live Photos, oversized videos — in plain English, ranked by the biggest win first. No swiping through 40,000 photos one at a time.

---

## Why this exists

This came out of the wider iOS market-research pass on 10 breakout indie apps (see `iOS_App_Market_Research_Report.docx` in the Output folder), specifically the This Day (photo-declutter) research. The category's ideal customer — someone with tens of thousands of photos, a paid iCloud tier, and two failed weekend decluttering attempts behind them — doesn't actually need another fast-swiping tool. Every existing photo-cleanup app (Gemini Photos, Swipe, Cleanup) optimizes for *speed of deleting*, not *understanding what's there*. Nobody clearly answers the question people actually ask when their phone nags them about storage: "why, specifically, is it full?"

That's the gap StorageSense is built to close, and it's also why it's the recommended pick over the category's headline idea ("This Day" itself, a daily-ritual re-surfacing app) — the diagnostic angle is a much smaller, more finishable build with a cleaner monetisation story, and it doesn't compete head-on with the swipe-cleaner apps at all.

### The wedge

- **Diagnosis before action.** A clear breakdown of the Photos library by category and size, in plain language, before asking the user to delete anything.
- **Biggest win first.** Instead of an undifferentiated pile to swipe through, StorageSense ranks categories by how much space freeing them would actually recover.
- **The diagnostic is never paywalled.** The category's #1 churn driver, per the research, is an aggressive paywall hitting right after someone has emotionally engaged with old photos. StorageSense's core insight — the breakdown itself — stays free forever; only bulk multi-select deletion and deeper duplicate detection are Pro.
- **Deletion is never a leap of faith.** Every delete goes through Apple's own Photos deletion API, which moves items to Recently Deleted (a 30-day, OS-level undo) — StorageSense states this plainly rather than inventing its own "trust us" safety net.

### Positioning

- **Headline:** *"See exactly what's filling up your phone — before you delete anything."*
- **Moat:** the whole product is built around explaining, not just acting — it's a diagnostic tool wearing a cleanup app's clothes, not the reverse.
- **Target buyer:** Dana, 34 — a marketing manager with ~45,000 photos since 2013, paying for a 200GB+ iCloud tier, who's tried and abandoned a decluttering weekend twice. Responds to small, understandable steps, not one big overwhelming project.

### Known platform constraint (be upfront about this)

iOS does not give any third-party app access to total device storage broken down by category — the "Apps / Messages / System / Photos" view in Settings → General → iPhone Storage is a system-only surface with no public API. **PhotoKit only exposes the Photos & Videos library**, nothing else on the device. StorageSense's honest scope is therefore *"why is your Photos library so big,"* never *"why is my whole iPhone full"* — copy, marketing, and the App Store listing must never imply whole-device insight the app can't actually provide. This is a real constraint, not a v1 cut corner — there's no future API that unlocks system-wide storage for a third-party app.

The same applies to iCloud storage: PhotoKit can tell you what's in the local/synced Photos library, but it cannot read the user's actual iCloud storage tier or usage total (that's a private API). Any iCloud-tier guidance in this app must be built on the user's own manual entry of what Settings shows them, clearly labelled as such — never presented as something the app detected automatically.

---

## Features (v1)

- **Storage breakdown** — the Photos library categorised into Screenshots, Videos, Live Photos, Bursts/near-duplicates, Selfies, Large files (>50MB), grouped by year, each with a real byte-size total (Swift Charts bar/donut view).
- **Plain-language explanations** — every category gets a short, human sentence, e.g. *"Live Photos take 2–3x the space of a normal photo because each one includes a short video clip,"* not just a number.
- **Biggest win first** — categories ranked by recoverable space, with the top one surfaced on the home screen as a single clear recommendation.
- **Review-before-delete** — tapping into a category shows the actual assets (thumbnail grid); nothing is ever auto-deleted. Deletion goes through `PHPhotoLibrary`'s standard delete API, which moves items to **Recently Deleted** (Apple's own 30-day undo) — the app states this plainly so deleting never feels like a leap of faith.
- **Duplicate/burst detection (v1, basic)** — groups near-identical shots from the same burst using capture-time + perceptual similarity; no cloud ML, no third-party service. Explicitly scoped as "obvious duplicates," not exhaustive AI similarity matching (that ceiling is intentional — see Roadmap).
- **iCloud tier calculator (manual entry)** — the user types in what Settings currently shows for their iCloud plan and usage; the app does the arithmetic to show what freeing X space would mean for their tier. Clearly labelled as manual, never framed as auto-detected.
- **No account, no cloud, no subscription requirement to see the diagnostic.**

## Screens

| Screen | Purpose |
|---|---|
| **Permission** | A plain-language pre-permission screen explaining exactly what StorageSense reads and that nothing leaves the device, before the system Photos prompt appears. |
| **Home** | The breakdown chart, the single biggest-win recommendation, last-scanned time, re-scan button. |
| **Category Detail** | Thumbnail grid for one category, its plain-language explanation, a running "selected to delete" total. |
| **Review & Delete** | Final confirmation before deletion, reminding the user items go to Recently Deleted, not gone forever. |
| **Storage Calculator** | Manual iCloud-tier input → plain-language "freeing this much could drop you a tier" arithmetic. |
| **Settings** | Re-scan library, Photos permission status, privacy statement, restore purchase. |

## Tech stack (and why)

- **SwiftUI + SwiftData**, iOS 17+ — matches the established portfolio convention (Ballast, Taxed & Tested, QuietCheck); SwiftData caches the last scan result so the app doesn't have to re-enumerate tens of thousands of assets on every launch.
- **PhotoKit** (`PHAsset`, `PHAssetResource`, `PHImageManager`, `PHPhotoLibrary`) — the entire scanning, categorisation and deletion engine. This is also the app's hard ceiling (see Known platform constraint above).
- **Swift Charts** — the storage breakdown visualisation.
- **StoreKit 2**, dormant in v1 behind `ProStatus` (same pattern as Ballast/QuietCheck) — a possible one-time unlock for bulk actions and deeper duplicate detection.
- No third-party packages, no backend, no analytics, no AI/ML service calls.

## Offline behaviour

Zero network requests. Every feature — scanning, breakdown, review, delete, the tier calculator — works permanently in airplane mode. The whole point of the app is that it never has to leave the device to answer "why is this full."

## Data model

- `ScanResult` — cached summary of the last library scan: per-category byte totals and asset counts, last-scanned date. Lets Home render instantly without re-scanning on every launch.
- `PhotoCategory` — the fixed set of categories (screenshot, video, livePhoto, burstDuplicate, selfie, largeFile, standard) with their plain-language explanation copy.
- No per-asset persistence beyond the cached summary — individual asset data always comes fresh from PhotoKit when a category is opened, so the app never holds a stale copy of the user's actual photo library.

## Monetisation

A single one-time purchase (price TBD) unlocking bulk multi-select deletion across categories and deeper duplicate/burst detection. **The diagnostic — the breakdown, the explanations, the biggest-win ranking — is never paywalled**, in any version, at any price point. This is the one non-negotiable product decision this app is built around (see golden rules in `CLAUDE.md`).

## Roadmap (not v1)

- Deeper duplicate detection (on-device Vision/Core ML similarity scoring) — kept out of v1 deliberately so it doesn't overlap with HighlightKeeper's job (a separate idea in the same research category).
- Home Screen widget showing current Photos-library size at a glance.
- Shared/family library decluttering (a distinct idea — FamilyReel — in the same category; out of scope here).
- Apple Watch companion (unlikely to be useful — parked indefinitely).

## Compliance / privacy

- No analytics, no ad SDKs, no tracking of any kind.
- Photos library access only — no cloud upload, no server, no account.
- App Store privacy label target: **Data Not Collected.**
- Photos permission request is preceded by a plain-language explanation screen, and the app respects a Limited Library selection if the user grants partial access rather than full library access.

## Research basis

StorageSense is This Day Idea #8 ("StorageSense") from the accompanying research report — chosen as the recommended pick in its category over the category's own headline idea, because it answers the specific, repeated "why is my storage full" confusion gap with a smaller, faster, more honestly-scoped build, and because its free-diagnostic/paid-bulk-action split directly defuses the category's #1 identified churn driver (an aggressive paywall after emotional engagement).

## Build notes

This project is being built directly in Claude Code, in `Claude Code projects/StorageSense`, following the same convention as Ballast. `CLAUDE.md` in this folder carries the full operating instructions (golden rules, architecture, build order, commands) — read that first, every session.
