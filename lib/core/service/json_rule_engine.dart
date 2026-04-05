import 'dart:convert';

import '../database/transaction_model.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// A single condition that evaluates a transaction field.
class RuleCondition {
  RuleCondition({
    required this.field,
    required this.operator,
    required this.value,
    this.secondValue,
  });

  /// Transaction field to inspect.
  /// One of: 'description', 'amount', 'source', 'merchant'.
  final String field;

  /// Comparison operator.
  /// Text fields: 'contains', 'equals', 'startsWith', 'endsWith', 'regex'.
  /// Numeric fields: 'gt', 'lt', 'between', 'equals'.
  final String operator;

  /// Primary comparison value.
  final dynamic value;

  /// Secondary value used only by the 'between' operator (upper bound).
  final dynamic secondValue;

  Map<String, dynamic> toJson() => {
        'field': field,
        'operator': operator,
        'value': value,
        if (secondValue != null) 'secondValue': secondValue,
      };

  factory RuleCondition.fromJson(Map<String, dynamic> json) {
    return RuleCondition(
      field: json['field'] as String,
      operator: json['operator'] as String,
      value: json['value'],
      secondValue: json['secondValue'],
    );
  }
}

/// An action to apply when a rule matches.
class RuleAction {
  RuleAction({
    required this.type,
    required this.value,
  });

  /// One of: 'setCategory', 'setType', 'addTag', 'setAccount'.
  final String type;

  /// The value to set/add (category key, type string, tag key, account id).
  final String value;

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
      };

  factory RuleAction.fromJson(Map<String, dynamic> json) {
    return RuleAction(
      type: json['type'] as String,
      value: json['value'] as String,
    );
  }
}

/// A complete JSON rule with conditions, actions, and metadata.
class JsonRule {
  JsonRule({
    required this.name,
    required this.conditions,
    this.conditionLogic = 'and',
    required this.actions,
    this.priority = 0,
    this.isEnabled = true,
  });

  final String name;
  final List<RuleCondition> conditions;

  /// 'and' — all conditions must match; 'or' — any condition suffices.
  final String conditionLogic;
  final List<RuleAction> actions;

  /// Lower number = higher priority.
  final int priority;
  final bool isEnabled;

  JsonRule copyWith({
    String? name,
    List<RuleCondition>? conditions,
    String? conditionLogic,
    List<RuleAction>? actions,
    int? priority,
    bool? isEnabled,
  }) {
    return JsonRule(
      name: name ?? this.name,
      conditions: conditions ?? this.conditions,
      conditionLogic: conditionLogic ?? this.conditionLogic,
      actions: actions ?? this.actions,
      priority: priority ?? this.priority,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'conditionLogic': conditionLogic,
        'actions': actions.map((a) => a.toJson()).toList(),
        'priority': priority,
        'isEnabled': isEnabled,
      };

  factory JsonRule.fromJson(Map<String, dynamic> json) {
    return JsonRule(
      name: json['name'] as String,
      conditions: (json['conditions'] as List<dynamic>)
          .map((e) => RuleCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
      conditionLogic: json['conditionLogic'] as String? ?? 'and',
      actions: (json['actions'] as List<dynamic>)
          .map((e) => RuleAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      priority: json['priority'] as int? ?? 0,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }
}

/// Result returned when a rule matches a transaction.
class RuleMatchResult {
  RuleMatchResult({
    required this.rule,
    required this.matchedConditions,
  });

  final JsonRule rule;

  /// Human-readable descriptions of the conditions that matched.
  final List<String> matchedConditions;
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

class JsonRuleEngine {
  const JsonRuleEngine();

  /// Evaluate [rules] against [tx], returning the first matching result (by
  /// priority, then list order). Only enabled rules are considered.
  RuleMatchResult? evaluateTransaction(
    JiveTransaction tx,
    List<JsonRule> rules,
  ) {
    final sorted = List<JsonRule>.from(rules)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (final rule in sorted) {
      if (!rule.isEnabled) continue;
      final matched = <String>[];
      bool ruleMatches;

      if (rule.conditionLogic == 'or') {
        ruleMatches = false;
        for (final cond in rule.conditions) {
          if (evaluateCondition(cond, tx)) {
            matched.add(_describeCondition(cond));
            ruleMatches = true;
          }
        }
      } else {
        // 'and' logic
        ruleMatches = true;
        for (final cond in rule.conditions) {
          if (evaluateCondition(cond, tx)) {
            matched.add(_describeCondition(cond));
          } else {
            ruleMatches = false;
            break;
          }
        }
      }

      if (ruleMatches && matched.isNotEmpty) {
        return RuleMatchResult(rule: rule, matchedConditions: matched);
      }
    }

    return null;
  }

  /// Evaluate a single [condition] against a [tx].
  bool evaluateCondition(RuleCondition condition, JiveTransaction tx) {
    final fieldValue = _resolveField(condition.field, tx);

    // Numeric operators
    if (condition.operator == 'gt' ||
        condition.operator == 'lt' ||
        condition.operator == 'between') {
      final num? numField = fieldValue is num
          ? fieldValue
          : num.tryParse(fieldValue?.toString() ?? '');
      if (numField == null) return false;

      switch (condition.operator) {
        case 'gt':
          return numField > _toNum(condition.value);
        case 'lt':
          return numField < _toNum(condition.value);
        case 'between':
          return numField >= _toNum(condition.value) &&
              numField <= _toNum(condition.secondValue);
        default:
          return false;
      }
    }

    // String operators
    final str = (fieldValue?.toString() ?? '').toLowerCase();
    final target = (condition.value?.toString() ?? '').toLowerCase();

    switch (condition.operator) {
      case 'contains':
        return str.contains(target);
      case 'equals':
        if (fieldValue is num) {
          return fieldValue == _toNum(condition.value);
        }
        return str == target;
      case 'startsWith':
        return str.startsWith(target);
      case 'endsWith':
        return str.endsWith(target);
      case 'regex':
        try {
          return RegExp(condition.value.toString()).hasMatch(str);
        } catch (_) {
          return false;
        }
      default:
        return false;
    }
  }

  /// Apply a list of [actions] to a copy-like modification of [tx].
  /// Returns the same [tx] instance (mutated in-place) for convenience.
  JiveTransaction applyActions(
    List<RuleAction> actions,
    JiveTransaction tx,
  ) {
    for (final action in actions) {
      switch (action.type) {
        case 'setCategory':
          tx.categoryKey = action.value;
          break;
        case 'setType':
          tx.type = action.value;
          break;
        case 'addTag':
          if (!tx.tagKeys.contains(action.value)) {
            tx.tagKeys = [...tx.tagKeys, action.value];
          }
          break;
        case 'setAccount':
          tx.accountId = int.tryParse(action.value);
          break;
      }
    }
    return tx;
  }

  /// Serialize a [JsonRule] to a JSON string.
  String serializeRule(JsonRule rule) => jsonEncode(rule.toJson());

  /// Deserialize a JSON string into a [JsonRule].
  JsonRule deserializeRule(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return JsonRule.fromJson(map);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  dynamic _resolveField(String field, JiveTransaction tx) {
    switch (field) {
      case 'description':
        return tx.rawText ?? '';
      case 'amount':
        return tx.amount;
      case 'source':
        return tx.source;
      case 'merchant':
        return tx.note ?? '';
      default:
        return '';
    }
  }

  num _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _describeCondition(RuleCondition cond) {
    final fieldLabel = _fieldLabel(cond.field);
    final opLabel = _operatorLabel(cond.operator);
    if (cond.operator == 'between') {
      return '$fieldLabel $opLabel ${cond.value} ~ ${cond.secondValue}';
    }
    return '$fieldLabel $opLabel "${cond.value}"';
  }

  String _fieldLabel(String field) {
    switch (field) {
      case 'description':
        return '描述';
      case 'amount':
        return '金额';
      case 'source':
        return '来源';
      case 'merchant':
        return '商户';
      default:
        return field;
    }
  }

  String _operatorLabel(String op) {
    switch (op) {
      case 'contains':
        return '包含';
      case 'equals':
        return '等于';
      case 'startsWith':
        return '开头是';
      case 'endsWith':
        return '结尾是';
      case 'regex':
        return '匹配正则';
      case 'gt':
        return '大于';
      case 'lt':
        return '小于';
      case 'between':
        return '介于';
      default:
        return op;
    }
  }
}
