# Android E2E Diagnostics MVP

## 目标

把 Android emulator 集成测试从“失败就结束”升级成“失败时能带回诊断”。

## 本轮落地

- 更新脚本：`/Users/huazhou/Downloads/Github/Jive/app/scripts/run_android_e2e_smoke.sh`

## 新增能力

1. `retry`
   - 通过 `JIVE_ANDROID_E2E_RETRIES` 控制重试次数
2. `artifact directory`
   - 每轮执行生成独立输出目录
3. `log capture`
   - 失败时自动抓取 `logcat`
4. `activity snapshot`
   - 失败时自动抓取 `dumpsys activity activities`
5. `screenshot`
   - 失败时自动抓取当前屏幕
6. `force-stop recovery`
   - 失败后自动 `am force-stop`，再尝试下一轮

## 环境变量

- `JIVE_ANDROID_E2E_DEVICE`
- `JIVE_ANDROID_E2E_FLAVOR`
- `JIVE_ANDROID_E2E_RETRIES`
- `JIVE_ANDROID_E2E_APP_ID`
- `JIVE_ANDROID_E2E_ARTIFACT_DIR`

## 价值

这层不是功能增强，而是把 CI 失败从“只知道红了”提升为“知道为什么红、红在哪一条用例、当时前台页面是什么状态”。
