import 'dart:convert';

import 'package:isar/isar.dart';
import '../database/auto_draft_model.dart';
import '../database/account_model.dart';
import '../database/category_model.dart';
import '../database/transaction_model.dart';
import '../service/account_service.dart';
import '../service/auto_account_mapping.dart';
import '../service/auto_rule_engine.dart';
import '../service/auto_settings.dart';

class AutoCapture {
  final double amount;
  final String source;
  final String? rawText;
  final String? metadataJson;
  final DateTime timestamp;
  final String? type;

  static const _incomeKeywords = [
    '已收款',
    '已收到',
    '到账',
    '退款',
    '赔付',
  ];

  static const _transferKeywords = [
    '转账',
    '转入',
    '转出',
    '提现',
    '还款',
    '余额转入',
    '余额转出',
    '转到',
    '转至',
  ];

  AutoCapture({
    required this.amount,
    required this.source,
    required this.rawText,
    required this.metadataJson,
    required this.timestamp,
    required this.type,
  });

  factory AutoCapture.fromEvent(Map<String, dynamic> data) {
    final amountValue = double.tryParse(data['amount']?.toString() ?? '') ?? 0;
    final rawSource = data['source']?.toString().trim() ?? '';
    final source = _normalizeSource(rawSource);
    final rawText = data['raw_text']?.toString();
    final metadataJson = data['metadata']?.toString();
    final timestamp = _parseTimestamp(data['timestamp']);
    final normalizedType = _normalizeType(data['type']?.toString());
    final inferredType = _inferTypeFromText(rawText);
    final type = _preferType(normalizedType, inferredType);
    return AutoCapture(
      amount: amountValue.abs(),
      source: source.isEmpty ? 'Unknown' : source,
      rawText: rawText?.trim(),
      metadataJson: metadataJson?.trim(),
      timestamp: timestamp,
      type: type,
    );
  }

  bool get isValid => amount > 0;

  static DateTime _parseTimestamp(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return DateTime.fromMillisecondsSinceEpoch(parsed);
    }
    return DateTime.now();
  }

  static String _normalizeSource(String source) {
    if (source.contains('com.tencent.mm')) return 'WeChat';
    if (source.contains('com.eg.android.AlipayGphone')) return 'Alipay';
    if (source.contains('com.unionpay')) return 'UnionPay';
    return source;
  }

  static String? _normalizeType(String? rawType) {
    if (rawType == null) return null;
    final normalized = rawType.trim().toLowerCase();
    if (normalized == 'expense' || normalized == 'income' || normalized == 'transfer') {
      return normalized;
    }
    return null;
  }

  static String? _inferTypeFromText(String? rawText) {
    if (rawText == null || rawText.trim().isEmpty) return null;
    for (final keyword in _incomeKeywords) {
      if (rawText.contains(keyword)) return 'income';
    }
    for (final keyword in _transferKeywords) {
      if (rawText.contains(keyword)) return 'transfer';
    }
    return null;
  }

  static String? _preferType(String? normalizedType, String? inferredType) {
    if (inferredType == 'transfer' && normalizedType != 'transfer') {
      return 'transfer';
    }
    return normalizedType ?? inferredType;
  }
}

class AutoCaptureResult {
  final bool inserted;
  final bool committed;
  final bool duplicate;
  final bool merged;

  const AutoCaptureResult({
    required this.inserted,
    required this.committed,
    required this.duplicate,
    required this.merged,
  });

  static const ignored = AutoCaptureResult(
    inserted: false,
    committed: false,
    duplicate: false,
    merged: false,
  );
  static const duplicateHit = AutoCaptureResult(
    inserted: false,
    committed: false,
    duplicate: true,
    merged: false,
  );
  static const mergedHit = AutoCaptureResult(
    inserted: false,
    committed: false,
    duplicate: false,
    merged: true,
  );
}

class AutoDraftService {
  AutoDraftService(this.isar);

  final Isar isar;

  static const _transferKeywords = [
    '转账',
    '转入',
    '转出',
    '提现',
    '还款',
    '余额转入',
    '余额转出',
    '转到',
    '转至',
  ];

  static const _toAccountAnchorKeywords = [
    '到账',
    '收款',
    '转入',
    '还款到',
    '退款至',
  ];

  Future<AutoCaptureResult> ingestCapture(
    AutoCapture capture, {
    required bool directCommit,
    AutoSettings? settings,
  }) async {
    if (!capture.isValid) return AutoCaptureResult.ignored;
    if (_looksLikeListRecord(capture.rawText)) return AutoCaptureResult.ignored;
    final effectiveSettings = settings ?? AutoSettingsStore.defaults;
    final dedupKey = _buildDedupKey(capture);
    final duplicate = await _isDuplicate(capture, dedupKey);
    if (duplicate) return AutoCaptureResult.duplicateHit;

    final engine = await AutoRuleEngine.instance();
    final categories = await _buildCategoryIndex();
    final match = engine.match(text: capture.rawText ?? '', source: capture.source);
    final type = capture.type ?? match.type;

    final accounts = await AccountService(isar).getActiveAccounts();
    final mappings = await AutoAccountMappingStore.load();
    final metadata = _parseMetadata(capture.metadataJson);
    final accountId = _resolveAccountIdFromAccounts(
      accounts,
      capture.source,
      capture.rawText,
      metadata,
      mappings,
      allowFallback: type != 'transfer',
    );
    final toAccountId = type == 'transfer'
        ? _resolveToAccountIdFromAccounts(accounts, capture.rawText, metadata, mappings)
        : null;
    final resolved = categories.resolve(match.parent, match.sub);

    var parentName = resolved.parent?.name ?? match.parent ?? '自动记账';
    var subName = resolved.child?.name ?? match.sub ?? '未分类';

    if (type == 'transfer') {
      parentName = '转账';
      subName = '转账';
    } else if (type == 'expense') {
      final meal = _inferMealSubCategory(
        parentName: parentName,
        subName: subName,
        timestamp: capture.timestamp,
      );
      if (meal != null) {
        subName = meal;
      }
    }

    final requiresManualTransfer = type == 'transfer' && (accountId == null || toAccountId == null);
    final shouldCommitNow = directCommit && !requiresManualTransfer;

    if (!shouldCommitNow && effectiveSettings.autoTransferRecognition) {
      final merged = await _mergeTransferDraftIfNeeded(
        capture: capture,
        matchType: type,
        windowSeconds: effectiveSettings.autoTransferWindowSeconds,
        accounts: accounts,
        accountId: accountId,
        toAccountId: toAccountId,
        categories: categories,
        resolved: resolved,
        parentName: parentName,
        subName: subName,
        dedupKey: dedupKey,
      );
      if (merged) return AutoCaptureResult.mergedHit;
    }

    if (shouldCommitNow) {
      await _commitTransaction(
        capture: capture,
        type: type,
        categoryKey: type == 'transfer' ? null : resolved.parent?.key,
        subCategoryKey: type == 'transfer'
            ? null
            : _resolveSubKey(
                parentName: parentName,
                subName: subName,
                resolved: resolved,
                categories: categories,
              ),
        categoryName: parentName,
        subCategoryName: subName,
        accountId: accountId,
        toAccountId: toAccountId,
      );
      return const AutoCaptureResult(inserted: true, committed: true, duplicate: false, merged: false);
    }

    final subKey = type == 'transfer'
        ? null
        : _resolveSubKey(
            parentName: parentName,
            subName: subName,
            resolved: resolved,
            categories: categories,
          );
    final draft = JiveAutoDraft()
      ..amount = capture.amount
      ..source = capture.source
      ..timestamp = capture.timestamp
      ..rawText = capture.rawText
      ..metadataJson = capture.metadataJson
      ..type = type
      ..category = parentName
      ..subCategory = subName
      ..categoryKey = type == 'transfer' ? null : resolved.parent?.key
      ..subCategoryKey = subKey
      ..accountId = accountId
      ..toAccountId = toAccountId
      ..dedupKey = dedupKey
      ..createdAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.collection<JiveAutoDraft>().put(draft);
    });

    return const AutoCaptureResult(inserted: true, committed: false, duplicate: false, merged: false);
  }

  Future<void> confirmDraft(JiveAutoDraft draft) async {
    final explicitType = draft.type;
    final isTransfer = explicitType == 'transfer' || (explicitType == null && _looksLikeTransfer(draft));
    final type = explicitType ?? (isTransfer ? 'transfer' : 'expense');
    final categoryKey = isTransfer ? null : draft.categoryKey;
    final subCategoryKey = isTransfer ? null : draft.subCategoryKey;
    final categoryName = isTransfer ? '转账' : draft.category;
    final subCategoryName = isTransfer ? '转账' : draft.subCategory;
    await _commitTransaction(
      capture: AutoCapture(
        amount: draft.amount,
        source: draft.source,
        rawText: draft.rawText,
        metadataJson: draft.metadataJson,
        timestamp: draft.timestamp,
        type: type,
      ),
      type: type,
      categoryKey: categoryKey,
      subCategoryKey: subCategoryKey,
      categoryName: categoryName,
      subCategoryName: subCategoryName,
      accountId: draft.accountId,
      toAccountId: draft.toAccountId,
      draftId: draft.id,
    );
  }

  Future<void> discardDraft(JiveAutoDraft draft) async {
    await isar.writeTxn(() async {
      await isar.collection<JiveAutoDraft>().delete(draft.id);
    });
  }

  Future<void> _commitTransaction({
    required AutoCapture capture,
    required String type,
    required String? categoryKey,
    required String? subCategoryKey,
    required String? categoryName,
    required String? subCategoryName,
    required int? accountId,
    int? toAccountId,
    int? draftId,
  }) async {
    final account = accountId ?? (await AccountService(isar).getDefaultAccount())?.id;
    final normalizedType = type == 'transfer' ? 'transfer' : type;
    final normalizedCategory = normalizedType == 'transfer' ? '转账' : categoryName;
    final normalizedSub = normalizedType == 'transfer' ? '转账' : subCategoryName;
    final normalizedCategoryKey = normalizedType == 'transfer' ? null : categoryKey;
    final normalizedSubKey = normalizedType == 'transfer' ? null : subCategoryKey;
    final tx = JiveTransaction()
      ..amount = capture.amount
      ..source = capture.source
      ..timestamp = capture.timestamp
      ..rawText = capture.rawText
      ..type = normalizedType
      ..categoryKey = normalizedCategoryKey
      ..subCategoryKey = normalizedSubKey
      ..category = normalizedCategory
      ..subCategory = normalizedSub
      ..accountId = account
      ..toAccountId = toAccountId;

    await isar.writeTxn(() async {
      await isar.collection<JiveTransaction>().put(tx);
      if (draftId != null) {
        await isar.collection<JiveAutoDraft>().delete(draftId);
      }
    });
  }

  String? _inferMealSubCategory({
    required String parentName,
    required String subName,
    required DateTime timestamp,
  }) {
    if (parentName != '餐饮') return null;
    if (subName == '早餐' || subName == '午餐' || subName == '晚餐') {
      return subName;
    }
    final hour = timestamp.hour;
    if (hour >= 4 && hour < 10) return '早餐';
    if (hour >= 10 && hour < 16) return '午餐';
    return '晚餐';
  }

  String? _resolveSubKey({
    required String parentName,
    required String subName,
    required CategoryMatch resolved,
    required CategoryIndex categories,
  }) {
    if (resolved.child != null && resolved.child!.name == subName) {
      return resolved.child!.key;
    }
    final updated = categories.resolve(parentName, subName);
    return updated.child?.key;
  }

  Future<bool> _mergeTransferDraftIfNeeded({
    required AutoCapture capture,
    required String matchType,
    required int windowSeconds,
    required List<JiveAccount> accounts,
    required int? accountId,
    required int? toAccountId,
    required CategoryIndex categories,
    required CategoryMatch resolved,
    required String parentName,
    required String subName,
    required String dedupKey,
  }) async {
    final window = Duration(seconds: windowSeconds.clamp(10, 300));
    final start = capture.timestamp.subtract(window);
    final end = capture.timestamp.add(window);
    final candidates = await isar.collection<JiveAutoDraft>()
        .filter()
        .timestampBetween(start, end, includeUpper: true)
        .findAll();
    if (candidates.isEmpty) return false;

    final captureIsTransfer = matchType == 'transfer' || _looksLikeTransferText(capture.rawText);
    for (final draft in candidates) {
      if (draft.dedupKey == dedupKey) continue;
      if ((draft.amount - capture.amount).abs() > 0.01) continue;

      final draftType = draft.type ?? 'expense';
      final draftIsTransfer = draftType == 'transfer' || _looksLikeTransfer(draft);
      final hasIncome = draftType == 'income' || matchType == 'income';
      final hasExpense = draftType == 'expense' || matchType == 'expense';

      if (!hasIncome || !hasExpense) {
        if (!captureIsTransfer || !draftIsTransfer) {
          continue;
        }
      }

      final merged = _mergeDraftWithCapture(
        draft: draft,
        capture: capture,
        matchType: matchType,
        accountId: accountId,
        toAccountId: toAccountId,
      );
      if (!merged) continue;

      await isar.writeTxn(() async {
        await isar.collection<JiveAutoDraft>().put(draft);
      });
      return true;
    }
    return false;
  }

  bool _mergeDraftWithCapture({
    required JiveAutoDraft draft,
    required AutoCapture capture,
    required String matchType,
    required int? accountId,
    required int? toAccountId,
  }) {
    final draftType = draft.type ?? 'expense';
    final fromId = _resolveFromAccountId(
      draftType: draftType,
      draftAccountId: draft.accountId,
      captureType: matchType,
      captureAccountId: accountId,
    );
    final toId = _resolveToAccountId(
      draftType: draftType,
      draftAccountId: draft.accountId,
      draftToAccountId: draft.toAccountId,
      captureType: matchType,
      captureAccountId: accountId,
      captureToAccountId: toAccountId,
    );

    draft.type = 'transfer';
    draft.category = '转账';
    draft.subCategory = '转账';
    draft.categoryKey = null;
    draft.subCategoryKey = null;
    draft.accountId = fromId ?? draft.accountId ?? accountId;
    draft.toAccountId = toId ?? draft.toAccountId ?? toAccountId;
    draft.rawText = _mergeRawText(draft.rawText, capture.rawText);
    return true;
  }

  int? _resolveFromAccountId({
    required String draftType,
    required int? draftAccountId,
    required String captureType,
    required int? captureAccountId,
  }) {
    if (draftType == 'expense' && draftAccountId != null) return draftAccountId;
    if (captureType == 'expense' && captureAccountId != null) return captureAccountId;
    return draftAccountId ?? captureAccountId;
  }

  int? _resolveToAccountId({
    required String draftType,
    required int? draftAccountId,
    required int? draftToAccountId,
    required String captureType,
    required int? captureAccountId,
    required int? captureToAccountId,
  }) {
    if (draftType == 'income' && draftAccountId != null) return draftAccountId;
    if (captureType == 'income' && captureAccountId != null) return captureAccountId;
    return draftToAccountId ?? captureToAccountId;
  }

  String? _mergeRawText(String? existing, String? incoming) {
    final left = existing?.trim() ?? '';
    final right = incoming?.trim() ?? '';
    if (right.isEmpty) return left.isEmpty ? null : left;
    if (left.isEmpty) return right;
    if (left == right) return left;
    final merged = '$left | $right';
    return merged.length > 420 ? merged.substring(0, 420) : merged;
  }

  Future<bool> _isDuplicate(AutoCapture capture, String dedupKey) async {
    if (dedupKey.contains('|order:')) {
      final draft = await isar.collection<JiveAutoDraft>()
          .filter()
          .dedupKeyEqualTo(dedupKey)
          .findFirst();
      if (draft != null) return true;
    }
    if (dedupKey.contains('|time:')) {
      final draft = await isar.collection<JiveAutoDraft>()
          .filter()
          .dedupKeyEqualTo(dedupKey)
          .findFirst();
      if (draft != null) return true;
    }
    final start = capture.timestamp.subtract(const Duration(minutes: 5));
    final end = capture.timestamp.add(const Duration(minutes: 5));
    final draft = await isar.collection<JiveAutoDraft>()
        .filter()
        .dedupKeyEqualTo(dedupKey)
        .timestampBetween(start, end, includeUpper: true)
        .findFirst();
    if (draft != null) return true;

    final txs = await isar.collection<JiveTransaction>()
        .filter()
        .timestampBetween(start, end, includeUpper: true)
        .findAll();
    final normalizedRaw = _normalizeText(capture.rawText ?? '');
    for (final tx in txs) {
      if (tx.amount != capture.amount) continue;
      if (tx.source != capture.source) continue;
      if (_normalizeText(tx.rawText ?? '') != normalizedRaw) continue;
      return true;
    }

    if (_looksLikeBulkText(capture.rawText)) {
      final narrowStart = capture.timestamp.subtract(const Duration(seconds: 90));
      final narrowEnd = capture.timestamp.add(const Duration(seconds: 90));
      final nearDraft = await isar.collection<JiveAutoDraft>()
          .filter()
          .amountEqualTo(capture.amount)
          .sourceEqualTo(capture.source)
          .timestampBetween(narrowStart, narrowEnd, includeUpper: true)
          .findAll();
      final normalizedIncoming = _normalizeText(capture.rawText ?? '');
      for (final draft in nearDraft) {
        final other = _normalizeText(draft.rawText ?? '');
        if (other.isEmpty) continue;
        if (_longestCommonSubstring(normalizedIncoming, other) >= 80) {
          return true;
        }
      }
      final nearTx = await isar.collection<JiveTransaction>()
          .filter()
          .amountEqualTo(capture.amount)
          .sourceEqualTo(capture.source)
          .timestampBetween(narrowStart, narrowEnd, includeUpper: true)
          .findFirst();
      if (nearTx != null) return true;
    }
    return false;
  }

  String _buildDedupKey(AutoCapture capture) {
    final metadata = _parseMetadata(capture.metadataJson);
    final orderId = _metadataValue(metadata, const [
      'order_id',
      'orderId',
      'trade_no',
      'tradeNo',
      'bill_no',
      'billNo',
      'merchant_order_id',
      'merchantOrderId',
    ]);
    if (orderId != null) {
      return '${capture.source}|order:$orderId';
    }
    final detailTime = _metadataValue(metadata, const [
      'detail_time',
      'trade_time',
      'pay_time',
      'created_time',
      'time',
    ]);
    final normalizedTime = _normalizeDetailTime(detailTime) ?? _extractDetailTimeFromRawText(capture.rawText);
    if (normalizedTime != null) {
      final type = capture.type ?? '';
      return '${capture.source}|${type}|${capture.amount.toStringAsFixed(2)}|time:$normalizedTime';
    }
    final normalized = _normalizeText(capture.rawText ?? '');
    return '${capture.source}|${capture.amount.toStringAsFixed(2)}|$normalized';
  }

  String? _normalizeDetailTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final match = RegExp(r'(\\d{4})[年\\./-](\\d{1,2})[月\\./-](\\d{1,2})[^\\d]*(\\d{1,2}):(\\d{2})').firstMatch(raw);
    if (match != null) {
      final year = match.group(1);
      final month = match.group(2)?.padLeft(2, '0');
      final day = match.group(3)?.padLeft(2, '0');
      final hour = match.group(4)?.padLeft(2, '0');
      final minute = match.group(5)?.padLeft(2, '0');
      if (year != null && month != null && day != null && hour != null && minute != null) {
        return '$year$month$day$hour$minute';
      }
    }
    return null;
  }

  String? _extractDetailTimeFromRawText(String? rawText) {
    if (rawText == null || rawText.trim().isEmpty) return null;
    return _normalizeDetailTime(rawText);
  }

  int? _resolveAccountIdFromAccounts(
    List<JiveAccount> accounts,
    String source,
    String? rawText,
    Map<String, dynamic> metadata,
    List<AutoAccountMapping> mappings,
    {required bool allowFallback}
  ) {
    if (accounts.isEmpty) return null;
    final metaFrom = _metadataValue(metadata, const ['from_asset', 'asset', 'fromAsset']);
    if (metaFrom != null) {
      final mapped = _resolveMappingAccountId(accounts, mappings, metaFrom);
      if (mapped != null) return mapped;
      final hint = _hintFromMetadataValue(metaFrom);
      if (hint != null) {
        final matched = _matchAccountByHint(accounts, hint);
        if (matched != null) return matched;
        if (_hintIndicatesBank(hint)) {
          return null;
        }
      }
    }
    final fromHint = _extractFromAccountHint(rawText);
    if (fromHint != null) {
      final mapped = _resolveMappingAccountId(accounts, mappings, fromHint.name);
      if (mapped != null) return mapped;
    }
    if (fromHint != null) {
      final matched = _matchAccountByHint(accounts, fromHint);
      if (matched != null) return matched;
      if (_hintIndicatesBank(fromHint)) {
        return null;
      }
    }
    if (!allowFallback) return null;
    if (source.contains('WeChat') || source.contains('微信')) {
      return _matchAccountByName(accounts, ['微信', '零钱', '微信钱包']) ?? accounts.first.id;
    }
    if (source.contains('Alipay') || source.contains('支付宝')) {
      return _matchAccountByName(accounts, ['支付宝', '余额宝']) ?? accounts.first.id;
    }
    if (source.contains('UnionPay') || source.contains('云闪付')) {
      return _matchAccountByName(accounts, ['云闪付']) ?? accounts.first.id;
    }
    return accounts.first.id;
  }

  int? _resolveToAccountIdFromAccounts(
    List<JiveAccount> accounts,
    String? rawText,
    Map<String, dynamic> metadata,
    List<AutoAccountMapping> mappings,
  ) {
    final metaFrom = _metadataValue(metadata, const ['from_asset', 'asset', 'fromAsset']);
    var metaTo = _metadataValue(metadata, const ['to_asset', 'toAccount', 'to_asset_name']);
    if (metaFrom != null && metaTo != null) {
      final normalizedFrom = _sanitizeHintName(metaFrom) ?? metaFrom;
      final normalizedTo = _sanitizeHintName(metaTo) ?? metaTo;
      if (normalizedFrom == normalizedTo && _walletHintKeywords.contains(normalizedFrom)) {
        metaTo = null;
      }
    }
    if (metaTo != null) {
      final mapped = _resolveMappingAccountId(accounts, mappings, metaTo);
      if (mapped != null) return mapped;
      final hint = _hintFromMetadataValue(metaTo);
      if (hint != null) {
        final matched = _matchAccountByHint(accounts, hint);
        if (matched != null) return matched;
      }
    }
    final hint = _hasToAccountAnchors(rawText) ? _extractToAccountHint(rawText) : null;
    if (hint == null) return null;
    final mapped = _resolveMappingAccountId(accounts, mappings, hint.name);
    if (mapped != null) return mapped;
    return _matchAccountByHint(accounts, hint);
  }

  Map<String, dynamic> _parseMetadata(String? jsonText) {
    if (jsonText == null || jsonText.trim().isEmpty) return const {};
    try {
      final decoded = json.decode(jsonText);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }

  String? _metadataValue(Map<String, dynamic> metadata, List<String> keys) {
    for (final key in keys) {
      final raw = metadata[key];
      if (raw == null) continue;
      final value = raw.toString().trim();
      if (value.isEmpty) continue;
      return value;
    }
    return null;
  }

  _AccountHint? _hintFromMetadataValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final tail = RegExp(r'(?:尾号|末四位|末尾)\s*(\d{3,4})').firstMatch(value)?.group(1) ??
        RegExp(r'[（(]\s*(\d{3,4})\s*[）)]').firstMatch(value)?.group(1);
    var cleaned = value.replaceAll(RegExp(r'[（(]\s*\d{3,4}\s*[）)]'), '').trim();
    final normalized = _sanitizeHintName(cleaned) ?? _sanitizeHintName(value);
    if (normalized == null || normalized.isEmpty) return null;
    return _AccountHint(name: normalized, tail: tail);
  }

  bool _hintIndicatesBank(_AccountHint hint) {
    if (hint.tail != null) return true;
    if (hint.name.contains('银行卡') || hint.name.contains('储蓄卡') || hint.name.contains('信用卡')) {
      return true;
    }
    return _extractBankName(hint.name) != null;
  }

  int? _resolveMappingAccountId(
    List<JiveAccount> accounts,
    List<AutoAccountMapping> mappings,
    String? matchText,
  ) {
    final matched = AutoAccountMappingStore.matchMapping(matchText, mappings);
    if (matched == null) return null;
    for (final account in accounts) {
      if (account.id == matched.accountId) return account.id;
    }
    return null;
  }

  int? _matchAccountByName(List<JiveAccount> accounts, List<String> keywords) {
    for (final keyword in keywords) {
      for (final account in accounts) {
        if (account.name.contains(keyword)) return account.id;
      }
    }
    return null;
  }

  bool _looksLikeTransfer(JiveAutoDraft draft) {
    final text = draft.rawText ?? '';
    if (text.isEmpty) return false;
    for (final keyword in _transferKeywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  bool _looksLikeTransferText(String? rawText) {
    if (rawText == null || rawText.trim().isEmpty) return false;
    for (final keyword in _transferKeywords) {
      if (rawText.contains(keyword)) return true;
    }
    return false;
  }

  _AccountHint? _extractToAccountHint(String? rawText) {
    if (rawText == null) return null;
    final text = rawText.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return null;
    final patterns = [
      RegExp(r'(?:到账银行卡|到账卡|收款银行卡|收款卡|收款账号|收款账户|转入卡|转出卡|转入账户|到账账户|还款到|退款至)[:：]?\s*([^\s，,。;；]{2,30})'),
      RegExp(r'(?:转账到|转到|转至|转入至|到账至)[:：]?\s*([^\s，,。;；]{2,30})'),
    ];

    String? name;
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        name = match.group(1);
        break;
      }
    }

    if (name == null || name.trim().isEmpty) {
      return _inferAccountHintFromContext(text, preferWallet: false);
    }

    var cleaned = name.replaceAll(RegExp(r'[，,。\s]+$'), '').trim();
    String? tailFromName;
    final parenMatch = RegExp(r'[（(]\s*(\d{3,4})\s*[）)]').firstMatch(cleaned);
    if (parenMatch != null) {
      tailFromName = parenMatch.group(1);
      cleaned = cleaned.replaceAll(parenMatch.group(0)!, '').trim();
    }
    if (RegExp(r'^\d{3,4}$').hasMatch(cleaned)) {
      tailFromName ??= cleaned;
      cleaned = '';
    } else {
      final tailMatch = RegExp(r'^(.*?)(?:尾号|末四位|末尾)\s*(\d{3,4})$').firstMatch(cleaned);
      if (tailMatch != null) {
        cleaned = tailMatch.group(1)!.trim();
        tailFromName ??= tailMatch.group(2);
      }
    }
    final normalized = _sanitizeHintName(cleaned);
    if (normalized == null || normalized.isEmpty) {
      return _inferAccountHintFromContext(text, preferWallet: false);
    }
    final tailNearName = tailFromName == null ? _extractTailNearName(text, name) : null;
    final resolvedTail =
        tailFromName ?? tailNearName ?? (RegExp(r'^\d{3,4}$').hasMatch(normalized) ? normalized : null);
    return _AccountHint(name: normalized, tail: resolvedTail);
  }

  _AccountHint? _extractFromAccountHint(String? rawText) {
    if (rawText == null) return null;
    final text = rawText.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return null;

    final patterns = [
      RegExp(r'(?:付款方式|付款信息|交易方式|退款方式|付款卡|付款方|扣款卡|支付方式|支付账户|付款账户)[:：]?\s*([^\s，,。;；]{2,30})'),
    ];

    String? name;
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        name = match.group(1);
        break;
      }
    }

    if (name == null || name.trim().isEmpty) {
      return _inferAccountHintFromContext(text, preferWallet: true);
    }

    var cleaned = name.replaceAll(RegExp(r'[，,。\s]+$'), '').trim();
    String? tailFromName;
    final parenMatch = RegExp(r'[（(]\s*(\d{3,4})\s*[）)]').firstMatch(cleaned);
    if (parenMatch != null) {
      tailFromName = parenMatch.group(1);
      cleaned = cleaned.replaceAll(parenMatch.group(0)!, '').trim();
    }
    if (RegExp(r'^\d{3,4}$').hasMatch(cleaned)) {
      tailFromName ??= cleaned;
      cleaned = '';
    } else {
      final tailMatch = RegExp(r'^(.*?)(?:尾号|末四位|末尾)\s*(\d{3,4})$').firstMatch(cleaned);
      if (tailMatch != null) {
        cleaned = tailMatch.group(1)!.trim();
        tailFromName ??= tailMatch.group(2);
      }
    }
    final normalized = _sanitizeHintName(cleaned);
    if (normalized == null || normalized.isEmpty) {
      return _inferAccountHintFromContext(text, preferWallet: true);
    }
    final tailNearName = tailFromName == null ? _extractTailNearName(text, name) : null;
    final resolvedTail =
        tailFromName ?? tailNearName ?? (RegExp(r'^\d{3,4}$').hasMatch(normalized) ? normalized : null);
    return _AccountHint(name: normalized, tail: resolvedTail);
  }

  String? _extractTailNearName(String text, String name) {
    if (text.isEmpty || name.isEmpty) return null;
    final index = text.indexOf(name);
    if (index < 0) return null;
    var end = index + name.length + 12;
    if (end > text.length) end = text.length;
    final slice = text.substring(index, end);
    return RegExp(r'(?:尾号|末四位|末尾)\s*(\d{3,4})').firstMatch(slice)?.group(1) ??
        RegExp(r'[（(]\s*(\d{3,4})\s*[）)]').firstMatch(slice)?.group(1);
  }

  _AccountHint? _inferAccountHintFromContext(String text, {required bool preferWallet}) {
    final bank = _extractBankName(text);
    final bankTail = bank == null ? null : _extractTailNearName(text, bank);
    final hasCardMarker = text.contains('银行卡') || text.contains('储蓄卡') || text.contains('信用卡');
    String? wallet;
    for (final keyword in _walletHintKeywords) {
      if (text.contains(keyword)) {
        wallet = keyword;
        break;
      }
    }
    final preferBank = bank != null && (bankTail != null || hasCardMarker);
    final primary = preferBank ? bank : (preferWallet ? (wallet ?? bank) : (bank ?? wallet));
    if (primary == null) return null;
    final tail = _extractTailNearName(text, primary);
    return _AccountHint(name: primary, tail: tail);
  }

  bool _hasToAccountAnchors(String? rawText) {
    if (rawText == null || rawText.trim().isEmpty) return false;
    for (final keyword in _toAccountAnchorKeywords) {
      if (rawText.contains(keyword)) return true;
    }
    return false;
  }

  String? _sanitizeHintName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final bank = _extractBankName(trimmed);
    if (bank != null) {
      if (trimmed.contains('信用卡')) return '$bank信用卡';
      if (trimmed.contains('储蓄卡')) return '$bank储蓄卡';
      return bank;
    }
    for (final keyword in _walletHintKeywords) {
      if (trimmed.contains(keyword)) return keyword;
    }
    if (RegExp(r'^\d{3,4}$').hasMatch(trimmed)) return trimmed;
    if (RegExp(r'(?:元|今日|今天|昨天|交易|支付|消费|退款|收款|转入|转出|支出|收入|成功|失败|单次|定时|投资|理财|帮助|更多|查看|详情|疑问|问题|账单管理|往来流水|AA收款|联系商家|申请电子回单)')
        .hasMatch(trimmed)) {
      return null;
    }
    if (trimmed.length > 12) return null;
    return trimmed;
  }

  static const _walletHintKeywords = [
    '支付宝',
    '微信',
    '余额宝',
    '零钱',
    '云闪付',
    '京东',
    '美团',
    '抖音',
    '拼多多',
    '淘宝',
    'QQ钱包',
    '钱包',
  ];

  int? _matchAccountByHint(List<JiveAccount> accounts, _AccountHint hint) {
    if (accounts.isEmpty) return null;
    final normalizedHint = _cleanAccountName(hint.name);
    final bank = _extractBankName(hint.name);
    final hintHasTail = hint.tail != null || RegExp(r'\d{3,4}').hasMatch(hint.name);

    if (hint.tail != null) {
      for (final account in accounts) {
        if (account.name.contains(hint.tail!)) return account.id;
      }
    }

    int? bestId;
    var bestScore = 0;
    var bestDiff = 999;
    for (final account in accounts) {
      if (!hintHasTail && RegExp(r'\d{3,4}').hasMatch(account.name)) {
        continue;
      }
      if (bank != null && account.name.contains('信用卡') && !account.name.contains(bank)) {
        continue;
      }
      final normalizedAccount = _cleanAccountName(account.name);
      final score = _longestCommonSubstring(normalizedAccount, normalizedHint);
      if (score == 0) continue;
      final diff = (normalizedAccount.length - score).abs();
      if (score > bestScore || (score == bestScore && diff < bestDiff)) {
        if (!(score == 2 && normalizedHint.startsWith('中国'))) {
          bestScore = score;
          bestDiff = diff;
          bestId = account.id;
        }
      }
    }

    if (bestScore >= 2) return bestId;
    return null;
  }

  String? _extractBankName(String text) {
    final match = RegExp(r'([\u4e00-\u9fa5]{2,10}银行)').firstMatch(text);
    return match?.group(1);
  }

  String _cleanAccountName(String name) {
    return name
        .replaceAll(RegExp(r'\d+'), '')
        .replaceAll(RegExp(r'\([^(（【】）)]*\)'), '')
        .replaceAll(RegExp(r'[卡银行储蓄借记信用账户余额]'), '')
        .replaceAll('支付', '')
        .replaceAll('方式', '')
        .replaceAll('账户', '')
        .trim();
  }

  int _longestCommonSubstring(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final m = a.length;
    final n = b.length;
    final prev = List<int>.filled(n + 1, 0);
    final curr = List<int>.filled(n + 1, 0);
    var best = 0;
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          curr[j] = prev[j - 1] + 1;
          if (curr[j] > best) best = curr[j];
        } else {
          curr[j] = 0;
        }
      }
      for (var j = 0; j <= n; j++) {
        prev[j] = curr[j];
        curr[j] = 0;
      }
    }
    return best;
  }

  Future<CategoryIndex> _buildCategoryIndex() async {
    final categories = await isar.collection<JiveCategory>().where().findAll();
    return CategoryIndex(categories);
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[\s`~!@#$%^&*()+=|{}\[\]:;,.<>/?，。！？、【】（）《》“”‘’￥…—-]"), '');
  }

  bool _looksLikeBulkText(String? rawText) {
    if (rawText == null || rawText.trim().isEmpty) return false;
    final text = rawText.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length >= 220) return true;
    const keywords = [
      '交易记录',
      '账单记录',
      '账单列表',
      '账单管理',
      '账单详情',
      '筛选',
      '搜索交易记录',
      '全部账单',
    ];
    var hits = 0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        hits++;
        if (hits >= 2) return true;
      }
    }
    final currencyHits = RegExp(r'[¥￥]').allMatches(text).length;
    return currencyHits >= 3;
  }

  bool _looksLikeListRecord(String? rawText) {
    if (rawText == null || rawText.trim().isEmpty) return false;
    final text = rawText.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.contains('搜索交易记录')) return true;
    if (text.contains('筛选') && text.contains('全部') && text.contains('支出') && text.contains('转账')) {
      return true;
    }
    if ((text.contains('账单列表') || text.contains('账单记录') || text.contains('交易记录')) &&
        (text.contains('筛选') || text.contains('搜索'))) {
      return true;
    }
    return false;
  }
}

class _AccountHint {
  final String name;
  final String? tail;

  const _AccountHint({required this.name, this.tail});
}

class CategoryIndex {
  final Map<String, JiveCategory> _parentByName = {};
  final Map<String, JiveCategory> _childByName = {};
  final Map<String, JiveCategory> _childByParentAndName = {};
  final Map<String, JiveCategory> _parentByKey = {};

  CategoryIndex(List<JiveCategory> categories) {
    for (final cat in categories) {
      if (cat.parentKey == null) {
        _parentByKey[cat.key] = cat;
        final existing = _parentByName[cat.name];
        if (existing == null || (cat.isSystem && !existing.isSystem)) {
          _parentByName[cat.name] = cat;
        }
      }
    }
    for (final cat in categories) {
      if (cat.parentKey == null) continue;
      final parent = _parentByKey[cat.parentKey!];
      if (parent == null) continue;
      final key = '${parent.name}|${cat.name}';
      final existing = _childByParentAndName[key];
      if (existing == null || (cat.isSystem && !existing.isSystem)) {
        _childByParentAndName[key] = cat;
      }
      final childExisting = _childByName[cat.name];
      if (childExisting == null || (cat.isSystem && !childExisting.isSystem)) {
        _childByName[cat.name] = cat;
      }
    }
  }

  CategoryMatch resolve(String? parentName, String? subName) {
    JiveCategory? parent = parentName == null ? null : _parentByName[parentName];
    JiveCategory? child;

    if (parent != null && subName != null) {
      child = _childByParentAndName['${parent.name}|$subName'];
    }
    child ??= subName == null ? null : _childByName[subName];
    if (child != null && parent == null && child.parentKey != null) {
      parent = _parentByKey[child.parentKey!];
    }
    return CategoryMatch(parent: parent, child: child);
  }
}

class CategoryMatch {
  final JiveCategory? parent;
  final JiveCategory? child;

  const CategoryMatch({
    required this.parent,
    required this.child,
  });
}
