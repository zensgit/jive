# Phase434 Validation

## Changed Files
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_release_candidate.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/build_ios_release_candidate.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/scripts/render_release_report_summary.sh`
- `/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml`
- `/Users/huazhou/Downloads/Github/Jive/app/android/key.properties.example`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/android_prod_release_signing_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/ios_release_candidate_fastfail_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/release_candidate_build_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/release_candidate_checklist_mvp.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-17-parallel-dev-phase434-design.md`
- `/Users/huazhou/Downloads/Github/Jive/app/docs/2026-03-17-parallel-dev-phase434-validation.md`

## Commands
### Script syntax
- `bash -n /Users/huazhou/Downloads/Github/Jive/app/scripts/build_release_candidate.sh`
- `bash -n /Users/huazhou/Downloads/Github/Jive/app/scripts/build_ios_release_candidate.sh`
- `bash -n /Users/huazhou/Downloads/Github/Jive/app/scripts/render_release_report_summary.sh`

Result: passed

### Workflow YAML parse
- `ruby -e 'require "yaml"; YAML.load_file("/Users/huazhou/Downloads/Github/Jive/app/.github/workflows/flutter_ci.yml")'`

Result: passed

### Android strict signing preflight
- `JIVE_RELEASE_CANDIDATE_STRICT_SIGNING=true bash /Users/huazhou/Downloads/Github/Jive/app/scripts/build_release_candidate.sh`

Result: expected fast-fail, and report created

Android report:
- `/Users/huazhou/Downloads/Github/Jive/app/build/reports/release-candidate/release-candidate.json`
- status: `block`
- message: `Strict signing is enabled for prod flavor but release signing is not configured.`

### iOS release candidate preflight
- `bash /Users/huazhou/Downloads/Github/Jive/app/scripts/build_ios_release_candidate.sh`

Result: expected fast-fail, and preflight report created

iOS report:
- `/Users/huazhou/Downloads/Github/Jive/app/build/reports/ios-release-candidate/ios-release-candidate-preflight.json`
- status: `missingPlatform`
- message: `iOS device platform is not available in the current Xcode installation`
- raw output retained in JSON/MD

### Summary rendering
- `bash /Users/huazhou/Downloads/Github/Jive/app/scripts/render_release_report_summary.sh android-candidate`
- `bash /Users/huazhou/Downloads/Github/Jive/app/scripts/render_release_report_summary.sh ios-candidate`

Result: passed; Android/iOS candidate blocking state now appears in summary

## Conclusion
- Android 正式签名缺失现在会被严格模式直接阻断，并保留结构化报告。
- iOS Xcode 平台缺失现在会在 preflight 阶段直接阻断，并保留完整原始输出。
- 当前离真正发版的剩余硬项已经明确收口为：
  1. Android 正式 keystore / secrets
  2. Xcode 安装可用 iOS device platform
  3. iOS codesign/archive
