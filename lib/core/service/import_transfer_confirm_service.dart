import 'import_service.dart';

enum ImportTransferConfirmIssueSeverity { review, block }

class ImportTransferKnownAccount {
  const ImportTransferKnownAccount({required this.name, this.id});

  final int? id;
  final String name;
}

class ImportTransferConfirmIssue {
  const ImportTransferConfirmIssue({
    required this.lineNumber,
    required this.severity,
    required this.code,
    required this.message,
  });

  final int lineNumber;
  final ImportTransferConfirmIssueSeverity severity;
  final String code;
  final String message;
}

class ImportTransferConfirmResult {
  const ImportTransferConfirmResult({
    required this.selectedCount,
    required this.transferCount,
    required this.readyCount,
    required this.reviewCount,
    required this.blockCount,
    required this.issues,
  });

  final int selectedCount;
  final int transferCount;
  final int readyCount;
  final int reviewCount;
  final int blockCount;
  final List<ImportTransferConfirmIssue> issues;

  bool get hasReview => reviewCount > 0;
  bool get hasBlock => blockCount > 0;
  bool get canProceed => !hasBlock;

  List<String> summaryLines({int maxItems = 5}) {
    final lines = <String>[];
    for (final issue in issues.take(maxItems)) {
      final prefix = issue.severity == ImportTransferConfirmIssueSeverity.block
          ? '阻断'
          : '确认';
      lines.add('第 ${issue.lineNumber} 行: [$prefix] ${issue.message}');
    }
    if (issues.length > maxItems) {
      lines.add('其余 ${issues.length - maxItems} 项未展开');
    }
    return lines;
  }
}

class ImportTransferConfirmService {
  const ImportTransferConfirmService();

  ImportTransferConfirmResult evaluate({
    required List<ImportParsedRecord> records,
    Iterable<ImportTransferKnownAccount> knownAccounts =
        const <ImportTransferKnownAccount>[],
    Iterable<String> knownAccountNames = const <String>[],
  }) {
    final resolvedAccounts =
        [
              ...knownAccounts,
              if (knownAccounts.isEmpty)
                ...knownAccountNames.map(
                  (name) => ImportTransferKnownAccount(name: name),
                ),
            ]
            .where((account) => account.name.trim().isNotEmpty)
            .toList(growable: false);
    final issues = <ImportTransferConfirmIssue>[];
    var transferCount = 0;
    var readyCount = 0;
    var reviewCount = 0;
    var blockCount = 0;

    for (final record in records) {
      if ((record.type ?? '').trim() != 'transfer') {
        continue;
      }
      transferCount += 1;
      final lineIssues = <ImportTransferConfirmIssue>[];
      final sourceName = (record.accountName ?? '').trim();
      final targetName = (record.toAccountName ?? '').trim();
      final normalizedSource = _normalizeName(sourceName);
      final normalizedTarget = _normalizeName(targetName);
      final resolvedSource = _resolveAccount(resolvedAccounts, sourceName);
      final resolvedTarget = _resolveAccount(resolvedAccounts, targetName);

      if (!record.isValid) {
        lineIssues.add(
          ImportTransferConfirmIssue(
            lineNumber: record.lineNumber,
            severity: ImportTransferConfirmIssueSeverity.block,
            code: 'invalid_amount',
            message: '金额无效，不能作为转账导入',
          ),
        );
      }
      if (targetName.isEmpty) {
        lineIssues.add(
          ImportTransferConfirmIssue(
            lineNumber: record.lineNumber,
            severity: ImportTransferConfirmIssueSeverity.block,
            code: 'missing_target_account',
            message: '缺少转入账户',
          ),
        );
      }
      if (normalizedSource.isNotEmpty &&
          normalizedSource == normalizedTarget &&
          normalizedTarget.isNotEmpty) {
        lineIssues.add(
          ImportTransferConfirmIssue(
            lineNumber: record.lineNumber,
            severity: ImportTransferConfirmIssueSeverity.block,
            code: 'same_account',
            message: '转出账户与转入账户重复',
          ),
        );
      } else if (resolvedSource?.id != null &&
          resolvedSource!.id == resolvedTarget?.id) {
        lineIssues.add(
          ImportTransferConfirmIssue(
            lineNumber: record.lineNumber,
            severity: ImportTransferConfirmIssueSeverity.block,
            code: 'same_account',
            message: '转出账户与转入账户重复',
          ),
        );
      }
      if (sourceName.isEmpty) {
        lineIssues.add(
          ImportTransferConfirmIssue(
            lineNumber: record.lineNumber,
            severity: ImportTransferConfirmIssueSeverity.review,
            code: 'missing_source_account',
            message: '未显式提供转出账户，将依赖自动识别',
          ),
        );
      } else if (resolvedAccounts.isNotEmpty && resolvedSource == null) {
        lineIssues.add(
          ImportTransferConfirmIssue(
            lineNumber: record.lineNumber,
            severity: ImportTransferConfirmIssueSeverity.review,
            code: 'unknown_source_account',
            message: '转出账户未在当前账户列表中命中: $sourceName',
          ),
        );
      }
      if (targetName.isNotEmpty &&
          resolvedAccounts.isNotEmpty &&
          resolvedTarget == null) {
        lineIssues.add(
          ImportTransferConfirmIssue(
            lineNumber: record.lineNumber,
            severity: ImportTransferConfirmIssueSeverity.block,
            code: 'unknown_target_account',
            message: '转入账户未在当前账户列表中命中: $targetName',
          ),
        );
      }
      if (record.serviceCharge != null &&
          record.serviceCharge! >= record.amount &&
          record.amount > 0) {
        lineIssues.add(
          ImportTransferConfirmIssue(
            lineNumber: record.lineNumber,
            severity: ImportTransferConfirmIssueSeverity.review,
            code: 'high_service_charge',
            message: '手续费不应大于或等于转账金额',
          ),
        );
      }

      final hasBlock = lineIssues.any(
        (issue) => issue.severity == ImportTransferConfirmIssueSeverity.block,
      );
      if (hasBlock) {
        blockCount += 1;
      } else if (lineIssues.isNotEmpty) {
        reviewCount += 1;
      } else {
        readyCount += 1;
      }
      issues.addAll(lineIssues);
    }

    return ImportTransferConfirmResult(
      selectedCount: records.length,
      transferCount: transferCount,
      readyCount: readyCount,
      reviewCount: reviewCount,
      blockCount: blockCount,
      issues: issues,
    );
  }

  static String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  static ImportTransferKnownAccount? _resolveAccount(
    List<ImportTransferKnownAccount> accounts,
    String rawName,
  ) {
    final normalized = rawName.trim();
    if (normalized.isEmpty) return null;
    for (final account in accounts) {
      if (account.name.trim() == normalized) return account;
    }
    for (final account in accounts) {
      if (account.name.contains(normalized) ||
          normalized.contains(account.name)) {
        return account;
      }
    }
    return null;
  }
}
