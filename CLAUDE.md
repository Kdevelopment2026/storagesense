# CLAUDE.md — StorageSense

Operating instructions for Claude Code working in this repo. Read this first, every session. `README.md` is the product overview and the research rationale. This file is *how we build*.

---

## What we're building

A native iOS app that scans the user's Photos library on-device and explains, in plain language, exactly what's using the storage — screenshots, duplicate bursts, Live Photos, oversized videos, by year — ranked by biggest recoverable win. Offline-first, local-only, no account, no subscription requirement to see the diagnostic.

**Positioning (keep all copy consistent with this):** a diagnostic tool, not another swipe-to-delete cleaner. Lead on **"see what's filling your phone before you delete anything"** — never on speed-of-deleting or gamified swiping. There is no code path anywhere that paywalls the breakdown itself, because the breakdown is the entire value proposition.

---

## Golden rules (do not break these)

1. **Scope is the Photos & Videos library, never "whole device storage."** PhotoKit cannot see Messages, Apps, System, or any other storage category — no copy anywhere may say or imply "why is my iPhone full," only "why is your Photos library so big." Grep for "iPhone storage" / "device storage" before every commit — those phrases should never appear in user-facing copy.
2. **The diagnostic is never paywalled.** The breakdown, the plain-language explanations, and the biggest-win ranking are free forever, in every version, at every price point. Only bulk multi-select deletion and deeper duplicate detection sit behind `ProStatus`. This is the app's entire trust proposition — the research found that an aggressive paywall right after emotional engagement is the #1 reason people abandon photo-cleanup apps.
3. **Never auto-delete, ever.** Every deletion is user-reviewed and user-confirmed. All deletions go through `PHPhotoLibrary.performChanges` with `PHAssetChangeRequest.deleteAssets`, which moves items to Recently Deleted (Apple's own 30-day undo) — never attempt to bypass or replace this with a custom "trash" system.
4. **The iCloud tier calculator is manual-entry only.** PhotoKit and public APIs cannot read the user's actual iCloud storage tier or usage — never claim or imply the app auto-detected this. The calculator screen must state plainly that the numbers came from what the user typed in.
5. **Offline-first. Zero network calls in v1.** Scanning, breakdown, review, deletion, and the tier calculator must all work permanently in airplane mode — there is no "online" mode to fall back from.
6. **No backend, ever, in v1.** The only persistence is on-device SwiftData, and only for the cached scan summary. No server, no account, no auth, no sync.
7. **No analytics, no tracking, no ad SDKs.** The App Store privacy label must be able to say **Data Not Collected**. This matters even more than usual here, given the app's entire job is reading the user's photo library — nothing about what's in it should ever leave the device.
8. **Features check `ProStatus`, never StoreKit directly.** All gating goes through the entitlement object so the business model stays a late, reversible decision. In v1 `isUnlocked = true`.
9. **Respect Reduce Motion everywhere**, and **accessibility is not optional (WCAG AA)** — body/caption text ≥4.5:1, the Swift Charts breakdown must never rely on colour alone (pair every segment with a text label and value), VoiceOver labels on every category row and chart segment, visible focus, 44×44pt tap targets, Dynamic Type.
10. **No guilt-based copy anywhere.** This app is talking to someone who has already tried and failed to declutter twice. Explanation copy is calm and factual ("Screenshots: 340 photos, 1.2GB"), never judgmental ("You've let this get out of control").
11. **No secrets in the repo.** There is no external API in v1, so this stays true by construction — keep it that way; any future networked feature needs an explicit decision recorded here first.

---

## Stack & platform

- **Swift** + **SwiftUI**, iOS 17+ deployment target.
- **PhotoKit** (`PHAsset`, `PHAssetResource`, `PHImageManager`, `PHPhotoLibrary`) — the entire scanning, categorisation and deletion engine, and the app's hard capability ceiling.
- **SwiftData** — persistence, used only to cache the last scan summary (`@Model`, `ModelContainer`).
- **Swift Charts** — the storage breakdown visualisation.
- **StoreKit 2** — present but dormant in v1 (wired only through `ProStatus`).
- No third-party packages in v1. Nothing added without a decision recorded here.

---

## Architecture

```
StorageSense/
├── App/                          # @main entry, ModelContainer, root nav, Photos permission gate
│   └── StorageSenseApp.swift
├── Models/
│   ├── PhotoCategory.swift          # enum: screenshot, video, livePhoto, burstDuplicate, selfie, largeFile, standard — plus its plain-language explanation copy
│   ├── ScanResult.swift              # SwiftData @Model: cached per-category byte totals + asset counts + last-scanned date
│   └── AssetSummary.swift             # lightweight per-asset struct (id, category, byteSize, creationDate) used in Category Detail — never persisted, always fetched fresh
├── Services/
│   ├── PhotoLibraryScanner.swift        # permission request + PHAsset enumeration + PHAssetResource size fetch + categorisation — the core engine, pure and unit-testable where possible
│   ├── DuplicateDetector.swift            # basic burst/near-identical grouping by capture time + perceptual hash — explicitly "obvious duplicates," not exhaustive ML similarity
│   ├── RecommendationEngine.swift          # ranks categories by recoverable space, generates the "biggest win" copy
│   ├── DeletionService.swift                # wraps PHPhotoLibrary.performChanges delete requests — the only place deletion happens
│   └── ProStatus.swift                       # feature-gating entitlement (StoreKit 2 ready)
├── DesignSystem/
│   └── Theme.swift                   # StorageSenseTheme (category colour palette, spacing, corner radius), AppearanceOption
├── Views/
│   ├── Permission/                  # pre-permission explanation screen, PHAuthorizationStatus handling (including .limited)
│   ├── Home/                        # HomeView — breakdown chart, biggest-win callout, re-scan
│   ├── CategoryDetail/               # CategoryDetailView — thumbnail grid, explanation copy, selection state
│   ├── ReviewDelete/                  # ReviewDeleteView — final confirm, Recently Deleted reassurance copy
│   ├── StorageCalculator/             # manual iCloud-tier input + arithmetic
│   └── Settings/                       # re-scan, permission status, privacy statement, restore purchase
└── Resources/
    └── Assets.xcassets               # AccentColor, AppIcon
```

- **One view/component per file**, named after the type.
- **`PhotoLibraryScanner` is the one source of truth for categorisation.** Views never call PhotoKit directly or re-implement category logic inline.
- **`RecommendationEngine` is the one source of truth for the "biggest win" ranking.** Views never sort/rank categories inline.
- **`DeletionService` is the only place `PHAssetChangeRequest.deleteAssets` is called.** No view calls PhotoKit's mutation API directly.
- **`ProStatus` is the only gate.** `if proStatus.isUnlocked { … }` — never inspect transactions in a view, and never gate the diagnostic behind it (golden rule 2).

---

## Conventions

- SwiftUI-first: prefer implicit animations, gated on Reduce Motion.
- Prefer value types and `@Observable` for services. Inject via environment.
- Every view has a `#Preview` seeded with demo `ScanResult`/`AssetSummary` data at a few different library sizes so screens are inspectable without granting real Photos access during development.
- All PhotoKit calls happen off the main thread (`PHImageManager` and asset fetches are not free); UI updates hop back to `@MainActor`.
- Copy: sentence case, calm and factual, never judgmental (see Golden rule 10). British spelling ("colour", "organise").
- Accessibility: category chart segments always paired with a text label and byte value, never colour-only; VoiceOver labels on every category row and chart segment (e.g. "Screenshots, 340 items, 1.2 gigabytes"); visible focus; 44×44pt targets; Dynamic Type.

---

## Build order

1. Project scaffold (`project.yml`, XcodeGen) + `DesignSystem/Theme.swift`.
2. `Permission/` — the pre-permission explanation screen + `PHAuthorizationStatus` handling (authorized / limited / denied), before anything else touches PhotoKit.
3. Models (`PhotoCategory`, `ScanResult`, `AssetSummary`) + `ModelContainer`.
4. `PhotoLibraryScanner` — enumeration, categorisation, size calculation. Get this right before any UI depends on it; this is the app's core engine. **Note:** the scaffold's `isLikelySelfie` is a placeholder that always returns `false` — PhotoKit has no public "is this a selfie" flag, so a real implementation needs an EXIF lens-facing heuristic (via `PHAssetResource`/`CGImageSource`) validated against an actual device library before it's trusted. Until that's done, selfies fall into "Everything else," which is the safe default, not a bug.
5. `DuplicateDetector` — basic burst/near-identical grouping layered on top of the scanner's output.
6. `RecommendationEngine` + its unit tests — the ranking logic, tested against a range of synthetic category-size distributions.
7. `HomeView` — breakdown chart (Swift Charts) + biggest-win callout + re-scan.
8. `CategoryDetailView` — thumbnail grid, explanation copy, multi-select.
9. `DeletionService` + `ReviewDeleteView` — the confirm-and-delete flow, including the Recently Deleted reassurance copy.
10. `StorageCalculator` — manual iCloud-tier input + arithmetic, clearly labelled as user-entered.
11. `SettingsView` — re-scan, permission status, privacy statement, restore purchase.
12. `ProStatus` entitlement (leave `isUnlocked = true`).
13. Accessibility pass — contrast, colour-not-sole-signal on the chart, VoiceOver, focus rings, Dynamic Type, Reduce Motion.

---

## Commands

```bash
# regenerate the project after adding files or changing build settings
xcodegen generate

# open in Xcode
open StorageSense.xcodeproj

# build
xcodebuild -scheme StorageSense -destination 'platform=iOS Simulator,name=iPhone 17' build

# run tests
xcodebuild -scheme StorageSense -destination 'platform=iOS Simulator,name=iPhone 17' test
```

- `project.yml` is the source of truth for the Xcode project (XcodeGen). The `.xcodeproj` is generated and git-ignored.
- Match the Team ID / bundle ID prefix / Swift version conventions already used in Ballast, Taxed & Tested and QuietCheck's `project.yml` files (same parent folder) rather than guessing new ones.
- The Simulator's Photos library is seeded with sample content by default but won't exercise real-world scale (tens of thousands of assets) — test scanning performance against a large synthetic library before considering this done, not just the Simulator's default handful of photos.
- This repo was scaffolded and its Swift source written by Claude running in a sandboxed environment with no Xcode/Swift toolchain available, so nothing in it has been compiled or run yet. Treat the first `xcodegen generate` + build as step zero of this session — fix whatever the compiler finds before adding anything new.

---

## Definition of done (v1.0)

- Photos permission flow, home breakdown, category detail, review-and-delete, storage calculator, settings — all working offline.
- `PhotoLibraryScanner` correctly categorises screenshots, videos, Live Photos, bursts, and large files against a real device library, not just Simulator sample data. Selfie detection has a real implementation (not the v1 placeholder) or the category is removed from the UI rather than shipped silently broken.
- `RecommendationEngine` unit tests pass for a range of synthetic category-size distributions, including edge cases (empty library, one dominant category).
- Deletion confirmed to route through `PHPhotoLibrary` and land in Recently Deleted (verified on a real device, not just Simulator).
- **Accessibility:** body/caption ≥4.5:1, chart segments never colour-only, VoiceOver labels on every category row and chart segment, visible focus, Dynamic Type and Reduce Motion all pass a manual check.
- `ProStatus` in place, `isUnlocked = true`, no StoreKit calls in views, the diagnostic never gated behind it.
- No analytics, no backend, no whole-device-storage language anywhere (grep clean for "iPhone storage" / "device storage").
- Privacy policy URL ready and App Store privacy label set to Data Not Collected.

## Out of scope for v1 (do not build yet)

Deep ML-based aesthetic/similarity scoring (a separate idea — HighlightKeeper — in the same research category), shared/family library decluttering (FamilyReel's job), Home Screen widget, Apple Watch companion, a live StoreKit paywall, any attempt to read system-wide or iCloud storage automatically (not possible via public API — see golden rule 1 and 4). These are roadmap items (`README.md` → Roadmap) or permanently out of scope — leave clean seams only where they're genuinely future roadmap, not where they're structurally impossible.
