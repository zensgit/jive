import 'dart:convert';

enum ImportColumnMappingFailfastStatus {
  ready('ready'),
  review('review'),
  block('block');

  const ImportColumnMappingFailfastStatus(this.value);
  final String value;
}

enum ImportColumnMappingFailfastMode {
  direct('direct'),
  manualReview('manual_review'),
  blocked('blocked');

  const ImportColumnMappingFailfastMode(this.value);
  final String value;
}

class ImportColumnMappingFailfastInput {
  const ImportColumnMappingFailfastInput({
    required this.sourceScope,
    this.headers = const [],
    this.requireCategoryMapping = true,
    this.requireAccountBookMappingForReady = true,
    required this.accountBookColumnIndex,
    required this.assetColumnIndex,
    required this.parentCategoryColumnIndex,
    required this.childCategoryColumnIndex,
    required this.dateColumnIndex,
    required this.amountColumnIndex,
    required this.remarkColumnIndex,
    required this.typeColumnIndex,
  });

  final String sourceScope;
  final List<String> headers;
  final bool requireCategoryMapping;
  final bool requireAccountBookMappingForReady;
  final int? accountBookColumnIndex;
  final int? assetColumnIndex;
  final int? parentCategoryColumnIndex;
  final int? childCategoryColumnIndex;
  final int? dateColumnIndex;
  final int? amountColumnIndex;
  final int? remarkColumnIndex;
  final int? typeColumnIndex;

  Map<String, dynamic> toJson() {
    return {
      'sourceScope': sourceScope,
      'headers': headers,
      'requireCategoryMapping': requireCategoryMapping,
      'requireAccountBookMappingForReady': requireAccountBookMappingForReady,
      'accountBookColumnIndex': accountBookColumnIndex,
      'assetColumnIndex': assetColumnIndex,
      'parentCategoryColumnIndex': parentCategoryColumnIndex,
      'childCategoryColumnIndex': childCategoryColumnIndex,
      'dateColumnIndex': dateColumnIndex,
      'amountColumnIndex': amountColumnIndex,
      'remarkColumnIndex': remarkColumnIndex,
      'typeColumnIndex': typeColumnIndex,
    };
  }
}

class ImportColumnMappingFailfastResult {
  const ImportColumnMappingFailfastResult({
    required this.input,
    required this.status,
    required this.mode,
    required this.reason,
    required this.action,
    required this.recommendation,
    required this.evaluatedAt,
  });

  final ImportColumnMappingFailfastInput input;
  final ImportColumnMappingFailfastStatus status;
  final ImportColumnMappingFailfastMode mode;
  final String reason;
  final String action;
  final String recommendation;
  final DateTime evaluatedAt;

  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      'mode': mode.value,
      'reason': reason,
      'action': action,
      'recommendation': recommendation,
      'evaluatedAt': evaluatedAt.toIso8601String(),
      'input': input.toJson(),
    };
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  String exportMarkdown() {
    return '''
# 导入列映射 Fail-Fast 报告

- status: ${status.value}
- mode: ${mode.value}
- reason: $reason
- action: $action
- recommendation: $recommendation
- evaluatedAt: ${evaluatedAt.toIso8601String()}

## Input
- sourceScope: ${input.sourceScope}
- headers: ${input.headers.join(' | ')}
- accountBookColumnIndex: ${input.accountBookColumnIndex}
- assetColumnIndex: ${input.assetColumnIndex}
- parentCategoryColumnIndex: ${input.parentCategoryColumnIndex}
- childCategoryColumnIndex: ${input.childCategoryColumnIndex}
- dateColumnIndex: ${input.dateColumnIndex}
- amountColumnIndex: ${input.amountColumnIndex}
- remarkColumnIndex: ${input.remarkColumnIndex}
- typeColumnIndex: ${input.typeColumnIndex}
''';
  }

  String exportCsv() {
    final rows = <List<String>>[
      ['field', 'value'],
      ['status', status.value],
      ['mode', mode.value],
      ['reason', reason],
      ['action', action],
      ['recommendation', recommendation],
      ['evaluatedAt', evaluatedAt.toIso8601String()],
      ['sourceScope', input.sourceScope],
      ['headers', input.headers.join(' | ')],
      ['accountBookColumnIndex', '${input.accountBookColumnIndex ?? ''}'],
      ['assetColumnIndex', '${input.assetColumnIndex ?? ''}'],
      ['parentCategoryColumnIndex', '${input.parentCategoryColumnIndex ?? ''}'],
      ['childCategoryColumnIndex', '${input.childCategoryColumnIndex ?? ''}'],
      ['dateColumnIndex', '${input.dateColumnIndex ?? ''}'],
      ['amountColumnIndex', '${input.amountColumnIndex ?? ''}'],
      ['remarkColumnIndex', '${input.remarkColumnIndex ?? ''}'],
      ['typeColumnIndex', '${input.typeColumnIndex ?? ''}'],
    ];
    return rows.map((row) => row.map(_csvEscape).join(',')).join('\n');
  }

  String _csvEscape(String raw) {
    if (raw.contains(',') || raw.contains('"') || raw.contains('\n')) {
      return '"${raw.replaceAll('"', '""')}"';
    }
    return raw;
  }
}

class ImportColumnMappingFailfastService {
  ImportColumnMappingFailfastResult evaluate(
    ImportColumnMappingFailfastInput input,
  ) {
    if (input.amountColumnIndex == null) {
      return _result(
        input: input,
        status: ImportColumnMappingFailfastStatus.block,
        mode: ImportColumnMappingFailfastMode.blocked,
        reason: '金额列未映射',
        action: '阻断进入下一步并要求先选择金额列',
        recommendation: '建议默认高亮金额候选列',
      );
    }

    if (input.dateColumnIndex == null) {
      return _result(
        input: input,
        status: ImportColumnMappingFailfastStatus.block,
        mode: ImportColumnMappingFailfastMode.blocked,
        reason: '日期列未映射',
        action: '阻断进入下一步并要求先选择日期列',
        recommendation: '建议默认高亮日期候选列',
      );
    }

    if (input.requireCategoryMapping &&
        input.parentCategoryColumnIndex == null &&
        input.childCategoryColumnIndex == null) {
      return _result(
        input: input,
        status: ImportColumnMappingFailfastStatus.block,
        mode: ImportColumnMappingFailfastMode.blocked,
        reason: '分类列未映射',
        action: '阻断进入下一步并要求至少选择一级或二级分类列',
        recommendation: '建议分类映射缺失时直接定位到分类控件',
      );
    }

    final usedColumns = <int, String>{};
    final duplicateFields = <String>[];
    void collect(String field, int? columnIndex) {
      if (columnIndex == null) return;
      final previous = usedColumns[columnIndex];
      if (previous != null) {
        duplicateFields.add('$previous/$field -> col:$columnIndex');
        return;
      }
      usedColumns[columnIndex] = field;
    }

    collect('账本', input.accountBookColumnIndex);
    collect('账户', input.assetColumnIndex);
    collect('一级分类', input.parentCategoryColumnIndex);
    collect('二级分类', input.childCategoryColumnIndex);
    collect('日期', input.dateColumnIndex);
    collect('金额', input.amountColumnIndex);
    collect('备注', input.remarkColumnIndex);
    collect('收支类型', input.typeColumnIndex);

    if (duplicateFields.isNotEmpty) {
      return _result(
        input: input,
        status: ImportColumnMappingFailfastStatus.block,
        mode: ImportColumnMappingFailfastMode.blocked,
        reason: '存在重复列映射：${duplicateFields.join('；')}',
        action: '阻断进入下一步并要求重新分配列映射',
        recommendation: '建议列选择器实时禁用已占用列',
      );
    }

    final blankHeaders = <int>[];
    final dirtyHeaders = <String>[];
    final canonicalHeaders = <String, List<String>>{};
    for (var index = 0; index < input.headers.length; index++) {
      final raw = input.headers[index];
      final trimmed = raw.trim();
      if (trimmed.isEmpty) {
        blankHeaders.add(index);
        continue;
      }
      final normalized = _normalizeHeader(trimmed);
      final canonical = _canonicalHeader(normalized);
      if (canonical != null) {
        canonicalHeaders.putIfAbsent(canonical, () => <String>[]).add(trimmed);
        if (_looksDirtyHeader(trimmed)) {
          dirtyHeaders.add('$trimmed -> $canonical');
        }
      }
    }

    final duplicateHeaderTargets = canonicalHeaders.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => '${entry.key}: ${entry.value.join(" / ")}')
        .toList(growable: false);

    if (blankHeaders.isNotEmpty ||
        dirtyHeaders.isNotEmpty ||
        duplicateHeaderTargets.isNotEmpty) {
      final reasons = <String>[];
      if (blankHeaders.isNotEmpty) {
        reasons.add(
          '存在空列头：${blankHeaders.map((value) => value + 1).join("、")}',
        );
      }
      if (dirtyHeaders.isNotEmpty) {
        reasons.add('存在脏列头：${dirtyHeaders.join("；")}');
      }
      if (duplicateHeaderTargets.isNotEmpty) {
        reasons.add('存在重复候选列头：${duplicateHeaderTargets.join("；")}');
      }
      return _result(
        input: input,
        status: ImportColumnMappingFailfastStatus.review,
        mode: ImportColumnMappingFailfastMode.manualReview,
        reason: reasons.join('；'),
        action: '允许继续预览，但要求先人工确认列头映射',
        recommendation: '建议在导入前清理空列、脏列和重复候选列头',
      );
    }

    final incompleteOptionalFields = <String>[];
    if (input.requireAccountBookMappingForReady &&
        input.accountBookColumnIndex == null) {
      incompleteOptionalFields.add('账本');
    }
    if (input.assetColumnIndex == null) {
      incompleteOptionalFields.add('账户');
    }
    if (input.typeColumnIndex == null) {
      incompleteOptionalFields.add('收支类型');
    }

    if (incompleteOptionalFields.isNotEmpty) {
      return _result(
        input: input,
        status: ImportColumnMappingFailfastStatus.review,
        mode: ImportColumnMappingFailfastMode.manualReview,
        reason: '${incompleteOptionalFields.join("/")}映射不完整，后续导入可能需要人工复核',
        action: '允许继续，但标记为人工复核',
        recommendation: '建议导入前补齐${incompleteOptionalFields.join("、")}映射',
      );
    }

    return _result(
      input: input,
      status: ImportColumnMappingFailfastStatus.ready,
      mode: ImportColumnMappingFailfastMode.direct,
      reason: '列映射满足 fail-fast 约束',
      action: '允许进入下一步导入预览',
      recommendation: '建议保留当前映射模板供下次复用',
    );
  }

  ImportColumnMappingFailfastResult _result({
    required ImportColumnMappingFailfastInput input,
    required ImportColumnMappingFailfastStatus status,
    required ImportColumnMappingFailfastMode mode,
    required String reason,
    required String action,
    required String recommendation,
  }) {
    return ImportColumnMappingFailfastResult(
      input: input,
      status: status,
      mode: mode,
      reason: reason,
      action: action,
      recommendation: recommendation,
      evaluatedAt: DateTime.now(),
    );
  }

  String _normalizeHeader(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }

  bool _looksDirtyHeader(String raw) {
    final trimmed = raw.trim();
    if (trimmed != raw) return true;
    return RegExp(r'[\s_\-]').hasMatch(trimmed);
  }

  String? _canonicalHeader(String normalized) {
    for (final entry in _headerAliases.entries) {
      if (entry.value.contains(normalized)) {
        return entry.key;
      }
    }
    return null;
  }

  static const Map<String, Set<String>> _headerAliases = {
    '账本': {'账本', 'accountbook', 'book'},
    '账户': {'账户', 'asset', 'account'},
    '一级分类': {'一级分类', 'parentcategory', 'parentcategoryname', 'category'},
    '二级分类': {'二级分类', 'childcategory', 'childcategoryname', 'subcategory'},
    '日期': {'日期', 'date', 'time', 'datetime', 'timestamp', '交易时间', '入账时间'},
    '金额': {'金额', 'amount', 'money', 'amt', '交易金额', '收支金额'},
    '备注': {'备注', 'remark', 'note', 'desc', '摘要', '说明'},
    '收支类型': {'收支类型', '交易类型', 'type', 'direction', '收支'},
  };
}
