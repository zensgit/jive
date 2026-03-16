import 'import_service.dart';

class ImportRecordRepairFanoutStrategy {
  const ImportRecordRepairFanoutStrategy({
    this.matchSource = true,
    this.matchType = true,
    this.matchNormalizedRawText = true,
    this.minimumRawTextLength = 4,
    this.includeTarget = true,
  });

  final bool matchSource;
  final bool matchType;
  final bool matchNormalizedRawText;
  final int minimumRawTextLength;
  final bool includeTarget;
}

class ImportRecordRepairFanoutResult {
  const ImportRecordRepairFanoutResult({
    required this.updatedRecords,
    required this.affectedIndices,
    required this.summary,
  });

  final List<ImportParsedRecord> updatedRecords;
  final List<int> affectedIndices;
  final String summary;
}

class ImportRecordRepairFanoutService {
  ImportRecordRepairFanoutResult apply({
    required List<ImportParsedRecord> records,
    required int targetIndex,
    required ImportParsedRecord baselineRecord,
    required ImportParsedRecord patchedRecord,
    ImportRecordRepairFanoutStrategy strategy =
        const ImportRecordRepairFanoutStrategy(),
  }) {
    if (targetIndex < 0 || targetIndex >= records.length) {
      throw RangeError.index(targetIndex, records, 'targetIndex');
    }

    final nextRecords = List<ImportParsedRecord>.from(records);
    final affected = <int>[];
    for (var index = 0; index < records.length; index++) {
      if (!_matches(
        candidate: records[index],
        baseline: baselineRecord,
        strategy: strategy,
      )) {
        continue;
      }
      if (!strategy.includeTarget && index == targetIndex) {
        continue;
      }
      nextRecords[index] = _applyPatch(
        current: records[index],
        baseline: baselineRecord,
        patched: patchedRecord,
      );
      affected.add(index);
    }

    if (affected.isEmpty && strategy.includeTarget) {
      nextRecords[targetIndex] = patchedRecord;
      affected.add(targetIndex);
    }

    final summary = affected.length <= 1
        ? '已更新当前记录'
        : '已将结构化修复同步到 ${affected.length} 条相似记录';
    return ImportRecordRepairFanoutResult(
      updatedRecords: nextRecords,
      affectedIndices: affected,
      summary: summary,
    );
  }

  bool _matches({
    required ImportParsedRecord candidate,
    required ImportParsedRecord baseline,
    required ImportRecordRepairFanoutStrategy strategy,
  }) {
    if (strategy.matchSource &&
        _normalize(candidate.source) != _normalize(baseline.source)) {
      return false;
    }
    if (strategy.matchType &&
        _normalize(candidate.type) != _normalize(baseline.type)) {
      return false;
    }
    if (strategy.matchNormalizedRawText &&
        !_looksLikeSameRawText(
          candidate.rawText,
          baseline.rawText,
          minimumLength: strategy.minimumRawTextLength,
        )) {
      return false;
    }
    return true;
  }

  ImportParsedRecord _applyPatch({
    required ImportParsedRecord current,
    required ImportParsedRecord baseline,
    required ImportParsedRecord patched,
  }) {
    var next = current;

    if (current.source == baseline.source &&
        patched.source != baseline.source) {
      next = next.copyWith(source: patched.source);
    }
    if (current.type == baseline.type && patched.type != baseline.type) {
      next = next.copyWith(type: patched.type);
    }
    if (current.accountBookName == baseline.accountBookName &&
        patched.accountBookName != baseline.accountBookName) {
      next = next.copyWith(accountBookName: patched.accountBookName);
    }
    if (current.accountName == baseline.accountName &&
        patched.accountName != baseline.accountName) {
      next = next.copyWith(accountName: patched.accountName);
    }
    if (current.toAccountName == baseline.toAccountName &&
        patched.toAccountName != baseline.toAccountName) {
      next = next.copyWith(toAccountName: patched.toAccountName);
    }
    if (current.parentCategoryName == baseline.parentCategoryName &&
        patched.parentCategoryName != baseline.parentCategoryName) {
      next = next.copyWith(parentCategoryName: patched.parentCategoryName);
    }
    if (current.childCategoryName == baseline.childCategoryName &&
        patched.childCategoryName != baseline.childCategoryName) {
      next = next.copyWith(childCategoryName: patched.childCategoryName);
    }
    if (_sameTags(current.tagNames, baseline.tagNames) &&
        !_sameTags(patched.tagNames, baseline.tagNames)) {
      next = next.copyWith(tagNames: patched.tagNames);
    }
    if (current.serviceCharge == baseline.serviceCharge &&
        patched.serviceCharge != baseline.serviceCharge) {
      next = next.copyWith(serviceCharge: patched.serviceCharge);
    }

    return next;
  }

  bool _looksLikeSameRawText(
    String? left,
    String? right, {
    required int minimumLength,
  }) {
    final normalizedLeft = _normalize(left);
    final normalizedRight = _normalize(right);
    if (normalizedLeft.isEmpty || normalizedRight.isEmpty) {
      return normalizedLeft == normalizedRight;
    }
    if (normalizedLeft == normalizedRight) return true;
    final minLength = normalizedLeft.length < normalizedRight.length
        ? normalizedLeft.length
        : normalizedRight.length;
    if (minLength < minimumLength) return false;
    return normalizedLeft.contains(normalizedRight) ||
        normalizedRight.contains(normalizedLeft);
  }

  bool _sameTags(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  String _normalize(String? value) {
    return (value ?? '').trim().toLowerCase().replaceAll(
      RegExp(r'[\s,，;；、_/\-]+'),
      '',
    );
  }
}
