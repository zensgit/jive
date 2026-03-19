# Phase432 Validation

## Changed Files
- `/Users/huazhou/Downloads/Github/Jive/app/pubspec.yaml`
- `/Users/huazhou/Downloads/Github/Jive/app/android/app/build.gradle.kts`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_release_candidate.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/release_candidate_build_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/release_candidate_checklist_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-17-parallel-dev-phase432-design.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-17-parallel-dev-phase432-validation.md`

## Commands
### Script syntax
`bash -n scripts/build_release_candidate.sh`

Result: passed

### Workflow YAML parse
`ruby -e 'require "yaml"; YAML.load_file(".github/workflows/flutter_ci.yml")'`

Result: passed

### Android release candidate build
`bash scripts/build_release_candidate.sh`

Result: passed

## Build output
- artifact: `/Users/huazhou/Downloads/Github/Jive/app/build/release-candidate/20260317-163850-dev/app-dev-release.aab`
- size: `115791795` bytes
- sha256: `161c71139b607951b3ee814dfe78148b1d1016f1079fd5125a57596c9ad55ec8`
- report: `/Users/huazhou/Downloads/Github/Jive/app/build/reports/release-candidate/release-candidate.json`
- summary: `/Users/huazhou/Downloads/Github/Jive/app/build/reports/release-candidate/release-candidate.md`

## Blocker found and fixed
### First release build failure
`bundleDevRelease` failed in R8 with missing classes from:
- `com.google.mlkit.vision.text.chinese.*`
- `com.google.mlkit.vision.text.devanagari.*`
- `com.google.mlkit.vision.text.japanese.*`
- `com.google.mlkit.vision.text.korean.*`

### Fix
Added app-level ML Kit language dependencies in `/Users/huazhou/Downloads/Github/Jive/app/android/app/build.gradle.kts`.

### Re-run
Second `bash scripts/build_release_candidate.sh` run passed and produced the AAB.
