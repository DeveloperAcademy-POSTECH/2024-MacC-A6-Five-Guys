# Local Build Config Setup

This project intentionally ignores local secret files:

- `FiveGuyes/Config.xcconfig`
- `FiveGuyes/FiveGuyes/GoogleService-Info.plist`

When these files are missing in a fresh checkout/worktree, build or test can fail.

## 1. Create local config files from examples

Run from repository root:

```sh
cp FiveGuyes/Config.xcconfig.example FiveGuyes/Config.xcconfig
cp FiveGuyes/GoogleService-Info.plist.example FiveGuyes/FiveGuyes/GoogleService-Info.plist
```

Then update the copied files with real local values.

## 2. Build behavior for Crashlytics script

The Crashlytics run script now behaves as follows:

- `Debug` / `Test` configurations: script exits early (skip upload).
- `Release` configuration: script runs normally, and still requires a valid `GoogleService-Info.plist`.

This keeps local development/testing resilient while preserving release-time validation.
