# Morning Board

Apple TV morning health board + iPhone companion.

**Flow:** HealthKit (iPhone) → `MorningSnapshot` → CloudKit private DB → tvOS board.

This folder is Slice 0–2 of the build map: shared kit, companion shell, TV board shell, and a runnable web prototype (since this environment has no Xcode).

## Quick demo (web)

```bash
cd morning-board/prototype
python3 -m http.server 8765 --bind 127.0.0.1
```

Open `http://127.0.0.1:8765` — pick a scenario on the phone panel, tap **Publish to Apple TV**.

## Tests (Linux-friendly)

```bash
node morning-board/scripts/test-snapshot.mjs
```

On a Mac with Xcode:

```bash
cd morning-board
swift test
```

## Xcode project (Mac)

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
2. `cd morning-board && xcodegen generate`
3. Open `MorningBoard.xcodeproj`
4. Set your Team + App ID capability for HealthKit + iCloud (CloudKit container `iCloud.com.cozma.MorningBoard`)
5. Run **MorningBoard** on iPhone / Simulator, **MorningBoardTV** on Apple TV / Simulator

Until Health queries are finished, both apps use demo fixtures via `InMemoryBoardStore` / `DemoHealthReader`. Swap in `CloudKitBoardStore` + `HealthKitReader` when entitlements are live.

## Layout

| Path | Role |
|---|---|
| `Sources/MorningBoardKit` | Models, readiness math, snapshot builder, board store protocol |
| `Apps/iOS` | Companion: permissions, preview, publish |
| `Apps/tvOS` | 10-foot morning board |
| `prototype/` | Interactive TV + phone mock for UX iteration |
| `project.yml` | XcodeGen spec for both app targets |

## Privacy rule

Publish **derived summaries only** (`MorningSnapshot`). Do not mirror raw HealthKit samples into CloudKit.
