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
