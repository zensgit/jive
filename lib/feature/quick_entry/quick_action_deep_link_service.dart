import '../../core/service/speech_intent_parser.dart';
import '../transactions/speech_entry_params_builder.dart';
import '../transactions/transaction_entry_params.dart';

class QuickActionDeepLinkRequest {
  final String? quickActionId;
  final TransactionEntryParams? transactionParams;
  final int? sceneBookId;
  final String? sceneBookKey;
  final String? sceneName;
  final bool switchToAllScenes;

  const QuickActionDeepLinkRequest._({
    this.quickActionId,
    this.transactionParams,
    this.sceneBookId,
    this.sceneBookKey,
    this.sceneName,
    this.switchToAllScenes = false,
  });

  const QuickActionDeepLinkRequest.quickAction(String id)
    : this._(quickActionId: id);

  const QuickActionDeepLinkRequest.transaction(TransactionEntryParams params)
    : this._(transactionParams: params);

  const QuickActionDeepLinkRequest.sceneSwitch({
    int? bookId,
    String? bookKey,
    String? name,
    bool allScenes = false,
  }) : this._(
         sceneBookId: bookId,
         sceneBookKey: bookKey,
         sceneName: name,
         switchToAllScenes: allScenes,
       );

  bool get isQuickAction => quickActionId != null;
  bool get isTransaction => transactionParams != null;
  bool get isSceneSwitch =>
      switchToAllScenes ||
      sceneBookId != null ||
      sceneBookKey != null ||
      sceneName != null;
}

/// Parses MoneyThings-style external entry links into the same in-app protocol
/// used by quick actions, widgets, and the structured transaction editor.
class QuickActionDeepLinkService {
  const QuickActionDeepLinkService._();

  static QuickActionDeepLinkRequest? parse(Uri uri) {
    if (uri.scheme != 'jive') return null;

    if (uri.host == 'quick-action') {
      final id = _firstNonEmpty(
        uri.queryParameters['id'],
        uri.pathSegments.isEmpty
            ? null
            : Uri.decodeComponent(uri.pathSegments.join('/')),
      );
      if (id == null) return null;
      return QuickActionDeepLinkRequest.quickAction(id);
    }

    if (uri.host == 'transaction' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'new') {
      return QuickActionDeepLinkRequest.transaction(_parseTransaction(uri));
    }

    if (uri.host == 'scene' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'switch') {
      return _parseSceneSwitch(uri);
    }

    return null;
  }

  static int? legacyTemplateId(String quickActionId) {
    if (quickActionId.startsWith('template:')) {
      return int.tryParse(quickActionId.substring('template:'.length));
    }
    return int.tryParse(quickActionId);
  }

  static TransactionEntryParams _parseTransaction(Uri uri) {
    final query = uri.queryParameters;
    final type = _normalizedType(query['type']);
    final amount = double.tryParse(query['amount'] ?? '');
    final accountId = int.tryParse(query['accountId'] ?? '');
    final toAccountId = int.tryParse(
      query['toAccountId'] ?? query['transferAccountId'] ?? '',
    );
    final bookId = int.tryParse(query['bookId'] ?? '');
    final categoryKey = _firstNonEmpty(query['categoryKey'], query['category']);
    final subCategoryKey = _firstNonEmpty(
      query['subCategoryKey'],
      query['leafCategoryKey'],
    );
    final tagKeys = _splitCsv(_firstNonEmpty(query['tagKeys'], query['tags']));
    final date = _parseDate(_firstNonEmpty(query['date'], query['time']));
    final rawText = _firstNonEmpty(query['rawText'], query['raw']);
    final explicitNote = _firstNonEmpty(query['note'], query['memo']);
    final source = _entrySource(query['entrySource']);
    final sourceLabel = _firstNonEmpty(query['sourceLabel'], query['source']);
    final quickActionId = _firstNonEmpty(
      query['quickActionId'],
      _firstNonEmpty(query['quickAction'], query['id']),
    );

    if (source == TransactionEntrySource.shareReceive &&
        amount == null &&
        rawText != null) {
      final intent = SpeechIntentParser().parse(rawText);
      if (intent != null && intent.isValid) {
        return const SpeechEntryParamsBuilder()
            .build(intent, source: source, sourceLabel: sourceLabel)
            .copyWith(
              prefillBookId: bookId,
              prefillDate: date,
              prefillNote: explicitNote ?? intent.cleanedText ?? rawText,
            );
      }
    }

    return TransactionEntryParams(
      source: source,
      sourceLabel: sourceLabel,
      canDirectSubmit: _canDirectSubmit(query),
      quickActionId: quickActionId,
      prefillAmount: amount,
      prefillType: type,
      prefillCategoryKey: categoryKey,
      prefillSubCategoryKey: subCategoryKey,
      prefillAccountId: accountId,
      prefillToAccountId: toAccountId,
      prefillBookId: bookId,
      prefillNote: source == TransactionEntrySource.shareReceive
          ? explicitNote ?? rawText
          : explicitNote,
      prefillDate: date,
      prefillTagKeys: tagKeys.isEmpty ? null : tagKeys,
      prefillRawText: rawText,
      highlightFields: _missingFields(
        type: type,
        amount: amount,
        accountId: accountId,
        toAccountId: toAccountId,
        categoryKey: categoryKey,
        subCategoryKey: subCategoryKey,
      ),
    );
  }

  static TransactionEntrySource _entrySource(String? raw) {
    switch (raw?.trim()) {
      case 'quickAction':
      case 'quick_action':
        return TransactionEntrySource.quickAction;
      case 'voice':
        return TransactionEntrySource.voice;
      case 'conversation':
        return TransactionEntrySource.conversation;
      case 'autoDraft':
      case 'auto_draft':
        return TransactionEntrySource.autoDraft;
      case 'shareReceive':
      case 'share_receive':
        return TransactionEntrySource.shareReceive;
      case 'ocrScreenshot':
      case 'ocr_screenshot':
      case 'ocr':
        return TransactionEntrySource.ocrScreenshot;
      case 'manual':
        return TransactionEntrySource.manual;
      default:
        return TransactionEntrySource.deepLink;
    }
  }

  static QuickActionDeepLinkRequest? _parseSceneSwitch(Uri uri) {
    final query = uri.queryParameters;
    final rawBookId = _firstNonEmpty(query['bookId'], query['id']);
    final bookKey = _firstNonEmpty(query['bookKey'], query['key']);
    final sceneName = _firstNonEmpty(
      query['name'],
      _firstNonEmpty(query['sceneName'], query['scene']),
    );
    final allScenes = _isTruthy(query['all']) || rawBookId == 'all';
    final bookId = allScenes ? null : int.tryParse(rawBookId ?? '');

    if (!allScenes && bookId == null && bookKey == null && sceneName == null) {
      return null;
    }

    return QuickActionDeepLinkRequest.sceneSwitch(
      bookId: bookId,
      bookKey: bookKey,
      name: sceneName,
      allScenes: allScenes,
    );
  }

  static String _normalizedType(String? raw) {
    switch (raw?.trim()) {
      case 'income':
      case 'transfer':
      case 'expense':
        return raw!.trim();
      default:
        return 'expense';
    }
  }

  static List<String> _missingFields({
    required String type,
    required double? amount,
    required int? accountId,
    required int? toAccountId,
    required String? categoryKey,
    required String? subCategoryKey,
  }) {
    final missing = <String>[];
    if (amount == null || amount <= 0) {
      missing.add(TransactionHighlightField.amount);
    }
    if (accountId == null) {
      missing.add(TransactionHighlightField.account);
    }
    if (type == 'transfer') {
      if (toAccountId == null) {
        missing.add(TransactionHighlightField.transferAccount);
      }
    } else if (_firstNonEmpty(categoryKey, subCategoryKey) == null) {
      missing.add(TransactionHighlightField.category);
    }
    return missing;
  }

  static List<String> _splitCsv(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }

  static bool _canDirectSubmit(Map<String, String> query) {
    final raw = _firstNonEmpty(
      query['canDirectSubmit'],
      query['directSubmit'],
    )?.toLowerCase();
    if (raw == 'true' || raw == '1' || raw == 'yes') return true;
    return query['mode']?.trim() == 'direct';
  }

  static bool _isTruthy(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      default:
        return false;
    }
  }

  static String? _firstNonEmpty(String? first, String? second) {
    final a = first?.trim();
    if (a != null && a.isNotEmpty) return a;
    final b = second?.trim();
    if (b != null && b.isNotEmpty) return b;
    return null;
  }
}
