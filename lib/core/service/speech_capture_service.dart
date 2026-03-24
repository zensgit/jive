import 'package:isar/isar.dart';

import '../service/account_service.dart';
import '../service/auto_draft_service.dart';
import 'speech_intent_parser.dart';

class SpeechCaptureService {
  SpeechCaptureService(this.isar, {SpeechIntentParser? parser})
      : _parser = parser ?? SpeechIntentParser();

  final Isar isar;
  final SpeechIntentParser _parser;

  Future<AutoCaptureResult> ingestText(
    String text, {
    bool directCommit = false,
    DateTime? now,
    String source = 'Voice',
  }) async {
    final accounts = await AccountService(isar).getActiveAccounts();
    final intent = _parser.parse(
      text,
      now: now,
      accountNames: accounts.map((account) => account.name).toList(),
    );
    if (intent == null || !intent.isValid) {
      return AutoCaptureResult.ignored;
    }

    final capture = AutoCapture(
      amount: intent.amount!,
      source: source,
      rawText: intent.rawText,
      timestamp: intent.timestamp,
      type: intent.type,
      accountName: intent.accountHint,
      toAccountName: intent.toAccountHint,
    );

    return AutoDraftService(isar).ingestCapture(
      capture,
      directCommit: directCommit,
    );
  }
}
