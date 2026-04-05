import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/transaction_model.dart';

/// Fields available for export templates.
enum ExportField {
  date('date', '日期'),
  amount('amount', '金额'),
  type('type', '类型'),
  category('category', '分类'),
  subCategory('subCategory', '子分类'),
  account('account', '账户'),
  note('note', '备注'),
  tags('tags', '标签'),
  source('source', '来源'),
  rawText('rawText', '原始文本');

  final String key;
  final String label;

  const ExportField(this.key, this.label);

  static ExportField fromKey(String key) {
    return ExportField.values.firstWhere(
      (f) => f.key == key,
      orElse: () => ExportField.date,
    );
  }
}

/// A reusable export profile that defines which fields to include,
/// their order, date formatting, sorting, and header preferences.
class ExportTemplate {
  final String name;
  final List<ExportField> fields;
  final String dateFormat;
  final ExportField sortBy;
  final bool ascending;
  final bool includeHeader;

  const ExportTemplate({
    required this.name,
    required this.fields,
    this.dateFormat = 'yyyy-MM-dd',
    this.sortBy = ExportField.date,
    this.ascending = true,
    this.includeHeader = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'fields': fields.map((f) => f.key).toList(),
        'dateFormat': dateFormat,
        'sortBy': sortBy.key,
        'ascending': ascending,
        'includeHeader': includeHeader,
      };

  factory ExportTemplate.fromJson(Map<String, dynamic> json) {
    return ExportTemplate(
      name: json['name'] as String,
      fields: (json['fields'] as List<dynamic>)
          .map((k) => ExportField.fromKey(k as String))
          .toList(),
      dateFormat: json['dateFormat'] as String? ?? 'yyyy-MM-dd',
      sortBy: ExportField.fromKey(json['sortBy'] as String? ?? 'date'),
      ascending: json['ascending'] as bool? ?? true,
      includeHeader: json['includeHeader'] as bool? ?? true,
    );
  }

  ExportTemplate copyWith({
    String? name,
    List<ExportField>? fields,
    String? dateFormat,
    ExportField? sortBy,
    bool? ascending,
    bool? includeHeader,
  }) {
    return ExportTemplate(
      name: name ?? this.name,
      fields: fields ?? this.fields,
      dateFormat: dateFormat ?? this.dateFormat,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      includeHeader: includeHeader ?? this.includeHeader,
    );
  }
}

/// Manages user-defined export templates persisted via [SharedPreferences].
class ExportTemplateService {
  static const _storageKey = 'jive_export_templates';

  /// Returns all user-saved templates from [SharedPreferences].
  Future<List<ExportTemplate>> getTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    return raw.map((json) {
      return ExportTemplate.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    }).toList();
  }

  /// Persists [template]. If a template with the same name exists it is
  /// replaced; otherwise the new template is appended.
  Future<void> saveTemplate(ExportTemplate template) async {
    final templates = await getTemplates();
    final index = templates.indexWhere((t) => t.name == template.name);
    if (index >= 0) {
      templates[index] = template;
    } else {
      templates.add(template);
    }
    await _persist(templates);
  }

  /// Removes the template whose [name] matches.
  Future<void> deleteTemplate(String name) async {
    final templates = await getTemplates();
    templates.removeWhere((t) => t.name == name);
    await _persist(templates);
  }

  /// Three built-in templates that are always available.
  List<ExportTemplate> getDefaultTemplates() {
    return const [
      ExportTemplate(
        name: '完整导出',
        fields: ExportField.values,
        dateFormat: 'yyyy-MM-dd',
        sortBy: ExportField.date,
        ascending: true,
        includeHeader: true,
      ),
      ExportTemplate(
        name: '简洁导出',
        fields: [
          ExportField.date,
          ExportField.amount,
          ExportField.type,
          ExportField.category,
          ExportField.note,
        ],
        dateFormat: 'yyyy-MM-dd',
        sortBy: ExportField.date,
        ascending: true,
        includeHeader: true,
      ),
      ExportTemplate(
        name: '分类汇总',
        fields: [
          ExportField.category,
          ExportField.subCategory,
          ExportField.amount,
          ExportField.type,
          ExportField.date,
        ],
        dateFormat: 'yyyy-MM-dd',
        sortBy: ExportField.category,
        ascending: true,
        includeHeader: true,
      ),
    ];
  }

  /// Generates CSV content for [transactions] using the given [template].
  String exportWithTemplate(
    ExportTemplate template,
    List<JiveTransaction> transactions,
  ) {
    final dateFmt = DateFormat(template.dateFormat);

    // Sort
    final sorted = List<JiveTransaction>.of(transactions);
    sorted.sort((a, b) {
      final cmp = _compareByField(a, b, template.sortBy, dateFmt);
      return template.ascending ? cmp : -cmp;
    });

    final buffer = StringBuffer();

    // BOM for Excel compatibility
    buffer.write('\uFEFF');

    // Header row
    if (template.includeHeader) {
      buffer.writeln(
        template.fields.map((f) => _escapeCsv(f.label)).join(','),
      );
    }

    // Data rows
    for (final tx in sorted) {
      buffer.writeln(
        template.fields
            .map((f) => _escapeCsv(_fieldValue(tx, f, dateFmt)))
            .join(','),
      );
    }

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _persist(List<ExportTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = templates.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  String _fieldValue(JiveTransaction tx, ExportField field, DateFormat fmt) {
    switch (field) {
      case ExportField.date:
        return fmt.format(tx.timestamp);
      case ExportField.amount:
        return tx.amount.toStringAsFixed(2);
      case ExportField.type:
        return _typeLabel(tx.type);
      case ExportField.category:
        return tx.category ?? '';
      case ExportField.subCategory:
        return tx.subCategory ?? '';
      case ExportField.account:
        return tx.accountId?.toString() ?? '';
      case ExportField.note:
        return tx.note ?? '';
      case ExportField.tags:
        return tx.tagKeys.join('|');
      case ExportField.source:
        return tx.source;
      case ExportField.rawText:
        return tx.rawText ?? '';
    }
  }

  int _compareByField(
    JiveTransaction a,
    JiveTransaction b,
    ExportField field,
    DateFormat fmt,
  ) {
    switch (field) {
      case ExportField.date:
        return a.timestamp.compareTo(b.timestamp);
      case ExportField.amount:
        return a.amount.compareTo(b.amount);
      case ExportField.type:
        return (a.type ?? '').compareTo(b.type ?? '');
      case ExportField.category:
        return (a.category ?? '').compareTo(b.category ?? '');
      case ExportField.subCategory:
        return (a.subCategory ?? '').compareTo(b.subCategory ?? '');
      case ExportField.account:
        return (a.accountId ?? 0).compareTo(b.accountId ?? 0);
      case ExportField.note:
        return (a.note ?? '').compareTo(b.note ?? '');
      case ExportField.tags:
        return a.tagKeys.join().compareTo(b.tagKeys.join());
      case ExportField.source:
        return a.source.compareTo(b.source);
      case ExportField.rawText:
        return (a.rawText ?? '').compareTo(b.rawText ?? '');
    }
  }

  static String _typeLabel(String? rawType) {
    switch (rawType?.trim()) {
      case 'income':
        return '收入';
      case 'transfer':
        return '转账';
      default:
        return '支出';
    }
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
