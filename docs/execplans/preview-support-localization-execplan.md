# Localize Preview Helpers Near Feature Screens

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

`PLANS.md` exists at repository root. This plan must be maintained in accordance with `PLANS.md`.

## Purpose / Big Picture

After this change, developers can find preview sample data and preview ViewModel builders in the feature folder that owns each screen, instead of searching one large central preview file. User-visible behavior does not change: each SwiftUI `#Preview` should still render with the same mock data and dependencies.

The result is observable when each feature folder contains its own preview helper extension file and the app still builds in Debug with previews enabled.

## Progress

- [x] (2026-02-13 05:02Z) Audited current preview helper usage and identified shared vs feature-specific APIs.
- [x] (2026-02-13 05:18Z) Split `Presentation/Preview/PreviewSupport.swift` into core-only infrastructure + shared test doubles.
- [x] (2026-02-13 05:20Z) Moved feature preview fixtures/builders into feature-adjacent files (`BookSetting`, `Main`, shared view fixtures).
- [x] (2026-02-13 05:24Z) Completed build validation and preview-coverage search; updated outcomes and artifacts.

## Surprises & Discoveries

- Observation: Most preview call sites already reference `PreviewSupport` static APIs, so moving implementations into `extension PreviewSupport` files can improve locality without changing call sites.
  Evidence: `rg -n "PreviewSupport\\." FiveGuyes/FiveGuyes/Sources/Presentation/View`.

- Observation: A naive preview coverage script that scans all `Presentation/View/**/*.swift` files now flags helper files as missing previews.
  Evidence: `MISSING_PREVIEW_VIEW_FILES=3` for non-screen helper files (`MainPreviewSupport.swift`, `BookSettingPreviewSupport.swift`, `PreviewBookFixtures.swift`), while `*View.swift` filter reports `MISSING_PREVIEW_UI_VIEW_FILES=0`.

## Decision Log

- Decision: Keep the `PreviewSupport` type name stable and split behavior using multiple feature-local `extension PreviewSupport` files.
  Rationale: It avoids broad call-site churn while still relocating code physically near relevant screens.
  Date/Author: 2026-02-13 / Codex

- Decision: Move `PreviewBookSearchStore` from central preview file into `BookSettingPreviewSupport.swift`.
  Rationale: It is only used by book-search previews, so colocating the store with book-setting preview builders improves feature-local discoverability.
  Date/Author: 2026-02-13 / Codex

## Outcomes & Retrospective

Implementation completed as planned. `PreviewSupport` now acts as shared preview infrastructure (in-memory dependencies/coordinator + shared preview mocks), while feature preview fixtures/builders were relocated close to related screens.

Resulting layout:

- `FiveGuyes/FiveGuyes/Sources/Presentation/Preview/PreviewSupport.swift` (core infra + cross-feature mocks)
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSettingPreviewSupport.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/Main/MainPreviewSupport.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/Shared/Preview/PreviewBookFixtures.swift`

The user-visible outcome was preserved: preview call sites did not require renaming, Debug build succeeded, and all actual UI view files under `Presentation/View` still have `#Preview`.

## Context and Orientation

Preview helpers currently live in one file: `FiveGuyes/FiveGuyes/Sources/Presentation/Preview/PreviewSupport.swift`. That file now mixes:

- preview infrastructure (`makeDependencies`, `makeCoordinator`)
- feature sample data (book setting sample API response, main home sample books)
- preview mocks (`PreviewBookManagementService`, `PreviewNotificationManager`, `PreviewNotificationSettingsStore`, `PreviewBookSearchStore`)

Feature preview call sites are spread across:

- `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/...`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/Main/...`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookCompletion/...`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookProgress/...`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/NotiSetting/...`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/ReadingCalendar/...`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/TotalCalendar/...`

## Plan of Work

First, trim `PreviewSupport.swift` so it only owns reusable preview infrastructure and cross-feature mock services/stores that are not specific to one view folder.

Next, add feature-adjacent extension files:

- Book-setting-specific preview fixtures/builders in `.../View/BookSetting/BookSettingPreviewSupport.swift`
- Main-view-specific preview ViewModel builder in `.../View/Main/MainPreviewSupport.swift`
- Shared reading/completion sample book fixtures near shared UI area in `.../View/Shared/Preview/PreviewBookFixtures.swift`

These files will define `extension PreviewSupport` members so existing previews continue using `PreviewSupport.<member>` without call-site edits.

Finally, run a full Debug build and a preview-coverage search for `#Preview` usage completeness.

## Concrete Steps

Run all commands from repository root `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`.

1. Confirm preview helper usage map:

    rg -n "PreviewSupport|PreviewBookManagementService|PreviewNotificationSettingsStore|PreviewBookSearchStore|PreviewNotificationManager" FiveGuyes/FiveGuyes/Sources/Presentation -g '*.swift'

2. Apply refactor edits to split preview support files.

3. Build Debug target:

    xcodebuild -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -configuration Debug -destination 'generic/platform=iOS Simulator' build

4. Confirm no presentation View file lost preview coverage:

    missing=0; while IFS= read -r file; do if ! rg -q "#Preview" "$file"; then echo "$file"; missing=$((missing+1)); fi; done < <(rg --files FiveGuyes/FiveGuyes/Sources/Presentation/View -g '*View.swift'); echo "MISSING_PREVIEW_UI_VIEW_FILES=$missing"

## Validation and Acceptance

Acceptance is complete when all conditions below hold.

1. Preview helper implementations are physically closer to related feature folders (`BookSetting`, `Main`, shared view fixtures).
2. Existing preview call sites compile without broad renaming.
3. `xcodebuild ... build` succeeds in Debug for iOS Simulator.
4. `MISSING_PREVIEW_UI_VIEW_FILES=0` is maintained.

## Idempotence and Recovery

This refactor is non-destructive and can be repeated. If a split introduces build failures, move only the failing member back into `PreviewSupport.swift`, rebuild, and then retry relocation with smaller file moves. No database/schema migration is involved.

## Artifacts and Notes

Validation snippets:

    $ rg -n "error:" /tmp/fiveguyes_build.log | head -n 200
    (no output)

    $ rg -n "\\*\\* BUILD SUCCEEDED \\*\\*" /tmp/fiveguyes_build.log
    1979:** BUILD SUCCEEDED **

    $ missing=0; while IFS= read -r file; do if ! rg -q "#Preview" "$file"; then echo "$file"; missing=$((missing+1)); fi; done < <(rg --files FiveGuyes/FiveGuyes/Sources/Presentation/View -g '*View.swift'); echo "MISSING_PREVIEW_UI_VIEW_FILES=$missing"
    MISSING_PREVIEW_UI_VIEW_FILES=0

## Interfaces and Dependencies

The following interfaces must remain available after refactor:

- `PreviewSupport.makeDependencies() -> AppDependencies`
- `PreviewSupport.makeCoordinator() -> NavigationCoordinator`
- `PreviewSupport.makeMainHomeViewModel(...) -> MainHomeViewModel`
- `PreviewSupport.makeBookSearchViewModel(...) -> BookSearchViewModel`
- `PreviewSupport.makeBookSettingInputModel() -> BookSettingInputModel`
- `PreviewSupport.sampleReadingBook`, `sampleCompletedBook`, `sampleBooksForCarousel`, `sampleAPIBook`, `sampleSearchBooks`
- `PreviewBookManagementService`, `PreviewNotificationManager`, `PreviewNotificationSettingsStore`

Revision Note (2026-02-13 / Codex): Initial ExecPlan created to guide preview-helper localization requested by user.
Revision Note (2026-02-13 / Codex): Updated progress, discoveries, validation commands, and outcomes after completing the refactor/build verification.
