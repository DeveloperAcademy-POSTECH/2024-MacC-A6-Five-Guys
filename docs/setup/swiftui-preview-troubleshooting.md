# Xcode Preview & Simulator Troubleshooting

When issues happen only in SwiftUI Preview or iOS Simulator (while source code looks fine), first suspect stale/corrupted CoreSimulator or preview cache.

In this project, these symptoms are often recovered by runtime/cache reset before code changes.

## Typical Symptoms

### Preview symptoms

- Preview canvas is broken (missing text, black blocks, distorted rendering).
- Even simple `Text("Hello")` preview renders incorrectly.
- The same issue appears across multiple preview files.

### Simulator build/run symptoms

- `xcodebuild` or Xcode run fails with simulator/runtime errors.
- Errors like:
  - `CoreSimulatorService connection became invalid`
  - `Unable to lookup in current state: Shutdown`
  - `simdiskimaged ... crashed or is not responding`

## Recovery Steps (Recommended Order)

### 1) Restart simulator services

```sh
killall Simulator || true
killall -9 com.apple.CoreSimulator.CoreSimulatorService || true
killall simdiskimaged || true
```

### 2) Reset Preview runtime cache

```sh
rm -rf ~/Library/Developer/Xcode/UserData/Previews/Simulator\ Devices/*
rm -rf ~/Library/Developer/Xcode/UserData/Previews/Simulator%20Devices/*
```

### 3) If simulator still unstable, reset simulator cache

```sh
rm -rf ~/Library/Developer/CoreSimulator/Caches/*
```

### 4) Reopen and re-run

1. Reopen Xcode (or workspace).
2. For Preview: open target file and press `Resume`.
3. For Simulator run/test: check destination again, then boot/run.

## Optional Advanced Reset

Use only when needed (data loss in simulator app data can occur):

```sh
xcrun simctl shutdown all
xcrun simctl erase all
```

## Notes

- These steps reset runtime/cache state, not project source code.
- If issue persists after cache/runtime reset, then investigate code-level causes:
  - preview-only initialization side effects
  - external SDK initialization timing
  - custom font/text modifier behavior in preview runtime
