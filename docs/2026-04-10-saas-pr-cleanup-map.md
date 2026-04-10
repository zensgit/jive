# Jive SaaS PR Cleanup Map

> 日期: 2026-04-10
> 主线 PR: [#144](https://github.com/zensgit/jive/pull/144)
> 当前 head: `f753c50`
> 用途: `#144` merge 后，统一给旧 SaaS PR 做收尾标注

## 原则

`#144` merge 后，旧 PR 不再继续作为推荐合并路径，只保留为审计材料。

推荐标注分两类：

- `merged via #144`
  - 用于当前 clean SaaS 主链上的 PR
  - 含义是：这条 PR 的内容已通过 `#144` 集成进入主线

- `superseded by #144`
  - 用于旧污染栈、旧 replacement、或已被 clean 链替代的 PR
  - 含义是：不要再走这条 PR 作为 merge 路径

## 建议标注为 `merged via #144`

| PR | 标题 | 当前状态 |
|---|---|---|
| `#139` | `docs(saas): restack sync safety wording onto main` | open draft |
| `#142` | `chore(saas): add Wave 0 smoke lane` | open draft |
| `#136` | `feat(saas): restack B1.1 book/workspace boundaries onto main` | open draft |
| `#140` | `feat(saas): restack B1.2 sync-key architecture onto clean B1.1` | open draft |
| `#141` | `feat(saas): restack B1.3 tombstone sync onto clean B1.2` | open draft |
| `#122` | `feat(saas): extract B2.2 subscription webhook branch` | open draft |
| `#131` | `feat(saas): add Apple App Store webhook handling` | open draft |
| `#124` | `feat(saas): wire subscription truth to auth and lifecycle` | open draft |
| `#133` | `feat(saas): add App Store payment service` | open draft |
| `#138` | `feat(saas): verify Apple purchases against server truth` | open draft |
| `#134` | `feat(saas): restack phone and Apple auth entrypoints onto main` | open draft |
| `#135` | `feat(saas): restack email auth reset flow onto main auth stack` | open draft |
| `#127` | `feat(saas): add analytics event pipeline` | open draft |
| `#128` | `feat(saas): B5.2 notification queue backend` | open draft |
| `#129` | `feat(saas): add admin user management api` | open draft |
| `#130` | `feat(saas): add ops overview summary` | open draft |

## 建议标注为 `superseded by #144`

| PR | 标题 | 当前状态 | 说明 |
|---|---|---|---|
| `#117` | `feat(B1.1): scope sync data by book key` | open | 已被 `#136` / `#144` 取代 |
| `#118` | `feat(B1.2): reduce sync dependence on local account ids` | open | 已被 `#140` / `#144` 取代 |
| `#119` | `feat(B1.3): sync tombstones for delete conflicts` | open | 已被 `#141` / `#144` 取代 |
| `#121` | `feat(saas): forward-port B1.3 sync tombstones` | open draft | 已被 `#141` / `#144` 取代 |
| `#123` | `docs(saas): audit sync safety wording` | open draft | 已被 `#139` / `#144` 取代 |
| `#125` | `feat(saas): scope shared ledgers to default workspace key` | open draft | 已并入 `#136` / `#144` |
| `#126` | `feat(saas): add phone and Apple auth entrypoints` | open draft | 已被 `#134` / `#144` 取代 |
| `#132` | `feat(saas): harden email auth reset flow` | open | 已被 `#135` / `#144` 取代 |
| `#137` | `feat(saas): restack B1.2 stable account sync keys` | open draft | 已被 `#140` / `#144` 取代 |

## 推荐评论模板

### `merged via #144`

```text
This work is now merged via #144, which served as the single SaaS Beta mainline integration path into `main`.

Keeping this PR for audit context, but it is no longer the recommended merge path.
```

### `superseded by #144`

```text
This PR is now superseded by #144.

The SaaS Beta stack was integrated and advanced through `#144` as the single mainline merge path, so this branch should be kept only for historical audit context and not merged independently.
```

## 配套脚本

可用这个脚本直接打印所有建议评论：

- [print_saas_pr_cleanup_comments.sh](/Users/chauhua/Documents/GitHub/Jive/worktrees/codex-saas-mainline-next/scripts/print_saas_pr_cleanup_comments.sh)
