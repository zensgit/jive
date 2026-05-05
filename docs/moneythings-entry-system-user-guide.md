# MoneyThings Entry System User Guide

This guide describes the MoneyThings-inspired entry system that landed in `main` through PR #196.

## Core Idea

Jive now treats every fast entry as one of three outcomes:

- `direct`: enough information exists, so the app can save immediately.
- `confirm`: only a small field such as amount or note is missing, so the app asks for a light confirmation.
- `edit`: information is missing or the transaction is complex, so the app opens the full transaction editor with highlighted fields.

The goal is fast capture first, safe completion second.

## Quick Action / One Touch

Use quick actions for repeated transactions such as breakfast, subway, coffee, lunch, or credit-card repayment.

Expected behavior:

- A complete action such as `早餐 ¥15` can save directly.
- An action such as `午餐` can ask for amount and then save.
- Complex actions such as transfer or repayment should open the full editor.
- Deep links with `jive://quick-action?id=template:<id>` use the same executor as in-app quick actions.
- Existing templates are now mirrored into local quick action records, so home, quick entry, deep link, widget, shortcut, and share entry points can converge on the same stable action protocol.
- The quick action management page can hide/show actions on home, pin actions, adjust icon/color, drag actions by the right-side handle, move actions up/down, and delete template-backed actions safely.
- Quick action icon choices reuse the category icon library and add One Touch-specific icons such as transfer, credit card, and payment.

## Structured Transaction Editor

External and smart-entry sources now converge into the same editor contract.

Covered sources:

- Manual transaction entry.
- Quick action and deep link.
- Screenshot OCR.
- Conversational bookkeeping.
- AutoDraft.
- AI Assistant voice.
- AI Assistant clipboard text.
- Android system text share.
- Android Today widget `+ 记一笔`.
- iOS Shortcuts / Siri App Intent entry.
- iOS system text/URL share.

Expected behavior:

- The editor shows a source banner when the entry came from an external source.
- Missing fields such as amount, category, account, transfer account, time, note, or tags are highlighted.
- The editor owns final validation and saving.
- Native/platform code must not create transactions directly.

## Three-Level Categories

Jive supports category paths such as:

`出行 / 私家车 / 加油`

Compatibility rule:

- `categoryKey` stores the top-level category.
- `subCategoryKey` stores the selected leaf category.
- No `tertiaryCategoryKey` field is introduced.

Expected behavior:

- Old two-level categories continue to work.
- Add transaction can select a leaf category from a deeper path.
- Transaction detail and CSV export can display the full path.
- CSV import can read a category path column such as `大类/中类/小类`.

## Account Groups / Subaccounts

Jive models subaccounts as normal accounts grouped by `groupName`.

Expected behavior:

- A bank group such as `中国银行` can show child accounts such as `活期 CNY` and `定期 USD`.
- Transactions still save to a concrete account.
- Account groups only affect display and summary.
- No `parentAccountKey` migration is introduced in this wave.

## Scenes And SmartList

Scenes are still backed by `JiveBook`.

Expected behavior:

- Home book switching uses scene-oriented copy.
- SmartList can restore a default transaction-list view.
- Users can save the current search/filter as a SmartList.
- Category/subcategory transaction pages can be saved as SmartLists without losing the fixed category context.
- SmartLists can be pinned, deleted, and set as default.

## Sharing Visibility

Object sharing is currently a visibility and warning layer.

Expected behavior:

- Shared scene state can appear on scene/book/account/category/tag surfaces.
- Deleting shared categories or tags should show impact copy.
- Permissions still come from the existing shared ledger/book role model.
- No object-level sharing table or RLS is introduced in this wave.

## QA Smoke Checklist

- Run a complete quick action and confirm it saves or confirms according to mode.
- Open quick action management, hide one action, and confirm it leaves home/quick entry but remains manageable in the hidden section.
- Change one quick action icon/color, drag it by the right-side handle, and reopen the page to confirm the local presentation persists.
- Drag one hidden quick action and confirm it stays hidden after reload.
- Open `jive://transaction/new?amount=15&type=expense` and confirm the editor receives the amount.
- Parse a conversational sentence and confirm the editor opens before save.
- Open an AutoDraft with incomplete fields and confirm the editor highlights missing fields.
- Use AI Assistant voice or clipboard recognition and confirm it opens the editor.
- Share payment text into Jive on Android and confirm amount/note parsing.
- Tap Android widget card background to open the app, then tap `+ 记一笔` to open the editor.
- Run the iOS Shortcut `记一笔` and confirm Jive opens the structured editor.
- Run the iOS Shortcut action `运行 Jive 快速动作` with `template:<id>` and confirm it follows the same One Touch behavior as the app.
- Share text or a URL from iOS into `记到 Jive` and confirm the structured editor opens with the shared content as raw text.
- Create or choose `出行 / 私家车 / 加油`, save a transaction, and confirm the detail/export path.
- Create grouped accounts and confirm transactions still save to the child account.
- In a shared scene, check shared badges and delete warning copy.

## Explicitly Deferred

- Cross-device quick action sync and cloud-backed independent quick action source.
- Custom user-uploaded quick action icon packs.
- True parent-child account migration with `parentAccountKey`.
- Full object-level sharing table, RLS, offline conflict handling, and audit log.
- E2EE/key-management work.
- SaaS entitlement/payment/sync behavior changes.
