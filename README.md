# jive

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Auto bookkeeping (iOS Shortcuts)

iOS cannot read other app notifications directly. Use a Shortcut that opens a URL:

```
jive://auto?amount=23.50&source=WeChat&raw_text=星巴克&type=expense
```

Parameters:
- `amount` (required): numeric amount
- `source` (optional): WeChat / Alipay / Shortcut / etc.
- `raw_text` or `note` (optional): merchant or memo text
- `type` (optional): `expense` | `income` | `transfer` (omitted = auto infer)

Flow:
- Default is pending review. Enable "自动入账" in settings to commit directly.
