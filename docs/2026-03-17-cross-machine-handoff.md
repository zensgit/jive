# Cross-Machine Handoff

## Synced Baseline
- Repository: `https://github.com/zensgit/jive.git`
- Branch: `codex/post-merge-verify`
- Latest pushed commit: `6244babf126be85486e1e3cbcdffde03cd3a438d`
- Commit message: `chore(release): add candidate gating and verification`

## What is already on GitHub
- import pipeline repair / preview / transfer guard
- sync runtime foundation
- Android release lane / host regression / Android emulator smoke lane
- release candidate gating and verification
- Android strict signing preflight
- iOS candidate preflight reporting
- phase431-435 design / validation docs

## Current Release State
### Android
- Code path is ready for strict signing builds.
- Remaining blocker is **missing production keystore / secrets**.
- `debug.keystore` exists locally but is not suitable for store release.
- Key example file exists at `/Users/huazhou/Downloads/Github/Jive/app/android/key.properties.example`.

### iOS
- iOS platform download was started on this machine.
- Before the download, the blocker was `Any iOS Device` unavailable and `iOS 26.0 is not installed`.
- The local disk became tight again during/after platform work, so this machine is not a clean baseline for continued iOS release work.

## Important local-only state not fully synced
These are still local and were intentionally not mixed into the pushed release slice:
- `/Users/huazhou/Downloads/Github/Jive/app/lib/feature/settings/settings_screen.dart`
- `/Users/huazhou/Downloads/Github/Jive/app/macos/Podfile.lock`

There are also many local untracked `docs/` and `test/` files in the current workspace.

## Recommended workflow on another machine
1. Clone `https://github.com/zensgit/jive.git`
2. Checkout branch `codex/post-merge-verify`
3. Read this file first: `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-17-cross-machine-handoff.md`
4. Continue from the pushed baseline, not from this machine's dirty worktree

## First commands on the other machine
```bash
git clone https://github.com/zensgit/jive.git
cd jive/app
git switch codex/post-merge-verify
flutter pub get
bash scripts/run_release_regression_suite.sh
```

## Next practical steps
1. Provide Android production signing materials and run strict signing release candidate.
2. Verify Xcode device platform availability on the new machine before retrying `scripts/build_ios_release_candidate.sh`.
3. Only migrate local dirty files from this machine if you explicitly decide they still matter.
