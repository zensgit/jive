import '../../core/database/transaction_model.dart';

/// Identifies how the user arrived at the transaction editor.
enum TransactionEntrySource {
  manual,
  quickAction,
  voice,
  conversation,
  autoDraft,
  ocrScreenshot,
  shareReceive,
  deepLink,
  edit,
}

class TransactionHighlightField {
  static const amount = 'amount';
  static const category = 'category';
  static const account = 'account';
  static const transferAccount = 'transferAccount';
  static const time = 'time';
  static const note = 'note';
  static const tags = 'tags';

  const TransactionHighlightField._();
}

/// Unified parameter object passed to AddTransactionScreen from any entry
/// point (manual tap, quick-action, voice input, deep link, etc.).
///
/// The screen adapts its title, button labels, and banner based on [source].
class TransactionEntryParams {
  final TransactionEntrySource source;

  /// Human-readable label for the source, e.g. `来自快速动作「午餐」`.
  final String? sourceLabel;

  /// When `true`, the editor may submit the transaction without further user
  /// interaction (used by confirm-mode quick actions).
  final bool canDirectSubmit;

  /// If originated from a quick action, stores its id.
  final String? quickActionId;

  // -- Prefill fields ---------------------------------------------------------

  final double? prefillAmount;

  /// `expense`, `income`, or `transfer`.
  final String? prefillType;

  final String? prefillCategoryKey;
  final String? prefillSubCategoryKey;
  final int? prefillAccountId;
  final int? prefillToAccountId;
  final int? prefillBookId;
  final String? prefillNote;
  final DateTime? prefillDate;
  final List<String>? prefillTagKeys;
  final String? prefillRawText;

  /// Fields that should be visually called out because the external source
  /// did not provide enough information to save safely.
  final List<String> highlightFields;

  // -- Edit mode --------------------------------------------------------------

  /// When editing an existing transaction, pass the full object here.
  final JiveTransaction? editingTransaction;

  const TransactionEntryParams({
    this.source = TransactionEntrySource.manual,
    this.sourceLabel,
    this.canDirectSubmit = false,
    this.quickActionId,
    this.prefillAmount,
    this.prefillType,
    this.prefillCategoryKey,
    this.prefillSubCategoryKey,
    this.prefillAccountId,
    this.prefillToAccountId,
    this.prefillBookId,
    this.prefillNote,
    this.prefillDate,
    this.prefillTagKeys,
    this.prefillRawText,
    this.highlightFields = const [],
    this.editingTransaction,
  });

  // -- Helpers ----------------------------------------------------------------

  /// Returns the page title that the editor should display.
  String get pageTitle {
    switch (source) {
      case TransactionEntrySource.manual:
        return '记一笔';
      case TransactionEntrySource.quickAction:
        return '快速记录';
      case TransactionEntrySource.voice:
        return '确认交易';
      case TransactionEntrySource.conversation:
        return '确认交易';
      case TransactionEntrySource.autoDraft:
        return '确认交易';
      case TransactionEntrySource.ocrScreenshot:
        return '确认交易';
      case TransactionEntrySource.shareReceive:
        return '确认交易';
      case TransactionEntrySource.deepLink:
        return '快速记录';
      case TransactionEntrySource.edit:
        return '编辑交易';
    }
  }

  /// Returns the primary submit button label.
  String get submitButtonLabel {
    switch (source) {
      case TransactionEntrySource.manual:
        return '保存';
      case TransactionEntrySource.quickAction:
        return '立即记录';
      case TransactionEntrySource.voice:
      case TransactionEntrySource.conversation:
      case TransactionEntrySource.autoDraft:
      case TransactionEntrySource.ocrScreenshot:
      case TransactionEntrySource.shareReceive:
      case TransactionEntrySource.deepLink:
        return '确认入账';
      case TransactionEntrySource.edit:
        return '保存修改';
    }
  }

  /// Returns a short banner description for the source, or `null` when no
  /// banner should be shown (manual / edit).
  String? get sourceBannerText {
    switch (source) {
      case TransactionEntrySource.manual:
      case TransactionEntrySource.edit:
        return null;
      case TransactionEntrySource.quickAction:
        return sourceLabel ?? '来自快速动作';
      case TransactionEntrySource.voice:
        return '来自语音输入';
      case TransactionEntrySource.conversation:
        return '来自对话记账';
      case TransactionEntrySource.autoDraft:
        return '来自自动识别';
      case TransactionEntrySource.ocrScreenshot:
        return '来自截图识别';
      case TransactionEntrySource.shareReceive:
        return '来自分享接收';
      case TransactionEntrySource.deepLink:
        return '来自外部链接';
    }
  }

  bool shouldHighlight(String field) => highlightFields.contains(field);

  TransactionEntryParams copyWith({
    TransactionEntrySource? source,
    String? sourceLabel,
    bool? canDirectSubmit,
    String? quickActionId,
    double? prefillAmount,
    String? prefillType,
    String? prefillCategoryKey,
    String? prefillSubCategoryKey,
    int? prefillAccountId,
    int? prefillToAccountId,
    int? prefillBookId,
    String? prefillNote,
    DateTime? prefillDate,
    List<String>? prefillTagKeys,
    String? prefillRawText,
    List<String>? highlightFields,
    JiveTransaction? editingTransaction,
  }) {
    return TransactionEntryParams(
      source: source ?? this.source,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      canDirectSubmit: canDirectSubmit ?? this.canDirectSubmit,
      quickActionId: quickActionId ?? this.quickActionId,
      prefillAmount: prefillAmount ?? this.prefillAmount,
      prefillType: prefillType ?? this.prefillType,
      prefillCategoryKey: prefillCategoryKey ?? this.prefillCategoryKey,
      prefillSubCategoryKey:
          prefillSubCategoryKey ?? this.prefillSubCategoryKey,
      prefillAccountId: prefillAccountId ?? this.prefillAccountId,
      prefillToAccountId: prefillToAccountId ?? this.prefillToAccountId,
      prefillBookId: prefillBookId ?? this.prefillBookId,
      prefillNote: prefillNote ?? this.prefillNote,
      prefillDate: prefillDate ?? this.prefillDate,
      prefillTagKeys: prefillTagKeys ?? this.prefillTagKeys,
      prefillRawText: prefillRawText ?? this.prefillRawText,
      highlightFields: highlightFields ?? this.highlightFields,
      editingTransaction: editingTransaction ?? this.editingTransaction,
    );
  }
}
