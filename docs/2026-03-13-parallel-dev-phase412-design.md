# 2026-03-13 Parallel Dev Phase412 Design

## 目标

本轮不再新增治理页面，转向两项更接近上线和后续演进的工程工作：

1. 把 Android emulator 集成测试车道脚本化
2. 给 SaaS 化路线补一份可执行的架构边界文档

## 设计决策

### 1. Android 车道脚本化，而不是继续把 shell loop 写在 workflow 里

workflow 内联脚本已经开始承担过多职责，后续如果要补更多 smoke 或调试失败日志，维护成本会快速升高。

因此本轮改为：

- workflow 只负责启动 emulator
- 真正的测试序列放到 `run_android_e2e_smoke.sh`
- host lane 与 Android lane 都采用独立脚本管理

### 2. host lane 与 Android lane 明确分层

上一轮已经确认：

- `import_center`、`category_icon_picker` 可以稳定跑在 host lane
- `calendar`、`transaction` 依赖平台流，更适合留在 Android emulator lane

这轮把这种边界固化到脚本与文档里，避免以后再把不稳定平台测试放回 host。

### 3. SaaS 先做边界设计，不做伪后端实现

当前仓库适合做本地优先客户端，不适合直接转成完整 SaaS。

本轮目标不是造后端，而是明确：

- 哪些本地能力可复用
- 哪些边界必须先抽象
- SaaS 应该分几阶段推进

## 产出

- `scripts/run_android_e2e_smoke.sh`
- `android_emulator_e2e_lane_mvp.md`
- `saas_evolution_architecture_mvp.md`
- `2026-03-13-parallel-dev-phase412-design.md`
- `2026-03-13-parallel-dev-phase412-validation.md`
