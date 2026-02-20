# Jive Integration Runner 加固与 CI 跟进（Follow-up）

日期：2026-02-20  
分支：`codex/next-batch-stability-core`

## PR 检查现状

使用 `gh` 检查后确认：

1. `https://github.com/zensgit/jive/pull/43` 已是 `MERGED` 状态。
2. 历史检查无失败项（`analyze_and_test` 通过，`android_integration_test` 因条件被跳过）。
3. 因 #43 已合并，后续提交需要在新的 follow-up PR 中继续跟踪 CI。

## 本轮实现

1. 扩展 `scripts/run_integration_tests.sh`
   - 新增 `--test <path>`（可重复）只跑指定用例。
   - 新增 `--retry <count>` 失败重试。
   - 新增 `--artifact-dir <path>` 指定产物目录。
   - 新增 `--no-collect-on-fail` 关闭失败时 adb 采集。
   - 新增 `--list` 列出默认 integration 用例。
   - 失败时自动采集：
     - `logcat`
     - 屏幕截图
     - UI dump
   - 每次执行输出 `.test.log` 到产物目录。

2. CI 对齐
   - `.github/workflows/flutter_ci.yml` 中 Android integration 步骤改为：
     - 调用统一脚本
     - 启用 `--retry 1` 以缓解瞬时波动

## 验证记录

```bash
bash -n scripts/run_integration_tests.sh
bash scripts/run_integration_tests.sh --list
bash scripts/run_integration_tests.sh \
  --test integration_test/transaction_search_flow_test.dart \
  --retry 1 \
  EP0110MZ0BC110087W
```

结果：

1. 脚本语法检查通过。  
2. `--list` 输出默认两条 integration 用例。  
3. 指定单用例 + 重试模式在真机通过（attempt 1 即通过）。  
4. 产物目录：`/tmp/jive-integration-20260220-215119`

## 结论

本轮 `1+2` 的“CI 跟进 + runner 能力增强”已完成，可进入新的 PR 检查闭环。

## CI 失败跟进（同日追加）

在 follow-up PR 的一次手动 CI（run `22226844318`）中，`android_integration_test` 失败，日志关键点：

- `Run Android integration_test (emulator)` 持续轮询 `adb shell getprop sys.boot_completed`
- 最终报错：`Timeout waiting for emulator to boot.`

对应修复：

1. `.github/workflows/flutter_ci.yml` 调整 emulator 配置：
   - `api-level: 33`（由 34 调整）
   - `profile: pixel_5`
   - `emulator-boot-timeout: 900`
   - `emulator-options: -no-window -no-snapshot -noaudio -no-boot-anim -gpu swiftshader_indirect`
2. 保留统一 runner 调用与 `--retry 1`。

目的：降低 emulator 启动超时概率，提升 `android_integration_test` 稳定性。

二次验证（run `22227481696`）后继续定位到更深层根因：

- emulator 启动日志出现：
  - `FATAL | Not enough space to create userdata partition`
  - `Available: 7318.05 MB ... need 7372.80 MB`

追加修复：

1. `.github/workflows/flutter_ci.yml` 增加 `disk-size: 6000M`，降低 AVD userdata 空间需求。
2. 其余加固参数（`api-level/profile/emulator-options/boot-timeout`）保持不变。

## CI 失败跟进（第三轮到第六轮）

### 关键结论

1. 磁盘空间问题已被解决，后续失败不再是 `userdata partition` 创建失败。  
2. 真实瓶颈转为 emulator 运行期稳定性与 `flutter test`/Gradle 长耗时（而非纯 boot）。  
3. 曾出现“日志失败但 job 成功”的假阳性，根因是 workflow 使用了 `continue-on-error`，已移除并恢复严格失败语义。

### 主要 run 记录

1. run `22234075643`（commit `a516dbc`）  
   - 现象：`android_integration_test` 最终失败，日志中多次 `🎉 0 tests passed.`  
   - 关键信息：boot 能进入测试阶段，但单用例执行接近阈值，出现被杀与 emulator 挂线程日志。

2. run `22235194890`（commit `e248109`）  
   - 现象：`calendar_date_picker_flow_test.dart` 出现 `TimeoutException ... Test timed out after 12 minutes.`  
   - 推断：`flutter test --timeout` 不覆盖 suite loading timeout，导致构建阶段即可触发 12 分钟超时。

3. run `22235933591`（commit `4969c44`）  
   - 调整：加入 `--test-case-timeout 20m` 与 `--ignore-test-timeouts`。  
   - 结果：run 显示 success，但日志仍有 `[integration] failed test files` 与 `The process '/usr/bin/sh' failed with exit code 1`。  
   - 结论：workflow 的 `continue-on-error` 造成假阳性，必须移除。

4. run `22237606637`（commit `e908704`）  
   - 调整：移除吞错路径，恢复单步严格失败。  
   - 结果：`Run Android integration_test (emulator)` 正确标记 failure。  
   - 关键信息：`QEMU2 ... hanging thread` + `line 197 ... Killed`，说明执行期仍有 hang/kill 风险。

### 本轮新增提交（第三轮到第六轮）

- `a516dbc` `ci(e2e): enable kvm and add emulator fallback retry`
- `e248109` `ci(e2e): relax per-test timeout and tune fallback trigger`
- `4969c44` `ci(e2e): raise flutter test-case timeout for emulator runs`
- `3323059` `ci(e2e): support flutter --ignore-timeouts in integration runner`
- `e908704` `ci(e2e): remove masked retry path and enforce strict failure`
- `8a04fb7` `ci(integration): handle non-zero test exits without early script abort`

### 进行中验证

- run `22238407218`（commit `8a04fb7`）已触发，用于验证：
  1. 非零退出后脚本不会提前中断；
  2. 失败清单与产物路径能稳定输出；
  3. job 结果与日志结果一致（无假阳性）。
