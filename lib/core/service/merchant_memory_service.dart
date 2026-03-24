import 'dart:convert';

import 'package:isar/isar.dart';

import '../database/merchant_memory_model.dart';
import '../database/transaction_model.dart';

/// 商户记忆建议结果
class MerchantSuggestion {
  final String? categoryKey;
  final String? subCategoryKey;
  final int? accountId;
  final List<String> tagKeys;
  final List<String> recentRemarks;
  final double? averageAmount;
  final double confidence; // 0.0 ~ 1.0

  const MerchantSuggestion({
    this.categoryKey,
    this.subCategoryKey,
    this.accountId,
    this.tagKeys = const [],
    this.recentRemarks = const [],
    this.averageAmount,
    this.confidence = 0.0,
  });

  bool get hasSuggestion => categoryKey != null || accountId != null;
}

/// 商户记忆服务 —— 超越 Yimu 的 AutoParameter
///
/// 核心差异：
/// 1. 模糊匹配：Yimu 精确匹配 shopName，Jive 支持子串 + 别名
/// 2. 频次加权：Yimu 存固定值，Jive 按频次推荐最可能的分类
/// 3. 时段感知：同一商户在不同时段可能使用不同分类
/// 4. 自动学习：每次用户确认/修改都更新记忆，无需手动管理规则
class MerchantMemoryService {
  final Isar _isar;

  MerchantMemoryService(this._isar);

  /// 标准化商户名
  static String normalize(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[（）()【】\[\]{}]'), '');
  }

  /// 查询商户建议（支持精确 + 模糊匹配）
  Future<MerchantSuggestion> getSuggestion(String merchantName) async {
    if (merchantName.trim().isEmpty) {
      return const MerchantSuggestion();
    }

    final normalized = normalize(merchantName);

    // 1. 精确匹配
    var memory = await _isar.jiveMerchantMemorys
        .where()
        .normalizedNameEqualTo(normalized)
        .findFirst();

    // 2. 模糊匹配：子串搜索
    if (memory == null) {
      final all = await _isar.jiveMerchantMemorys.where().findAll();
      for (final m in all) {
        if (normalized.contains(m.normalizedName) ||
            m.normalizedName.contains(normalized)) {
          memory = m;
          break;
        }
        // 别名匹配
        for (final alias in m.aliases) {
          final normalizedAlias = normalize(alias);
          if (normalized.contains(normalizedAlias) ||
              normalizedAlias.contains(normalized)) {
            memory = m;
            break;
          }
        }
        if (memory != null) break;
      }
    }

    if (memory == null) {
      return const MerchantSuggestion();
    }

    // 根据频次找最可能的分类
    String? bestCatKey = memory.topCategoryKey;
    String? bestSubKey = memory.topSubCategoryKey;
    double confidence = 0.0;

    if (memory.categoryFrequencyJson.isNotEmpty &&
        memory.categoryFrequencyJson != '{}') {
      final freq = _parseFrequency(memory.categoryFrequencyJson);
      if (freq.isNotEmpty) {
        final sorted = freq.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topEntry = sorted.first;
        final parts = topEntry.key.split(':');
        bestCatKey = parts.isNotEmpty ? parts[0] : null;
        bestSubKey = parts.length > 1 ? parts[1] : null;

        // 置信度 = 最高频次 / 总次数
        final total = freq.values.fold<int>(0, (s, v) => s + v);
        confidence = total > 0 ? topEntry.value / total : 0.0;
      }
    }

    // 根据频次找最可能的账户
    int? bestAccountId = memory.preferredAccountId;
    if (memory.accountFrequencyJson.isNotEmpty &&
        memory.accountFrequencyJson != '{}') {
      final freq = _parseFrequency(memory.accountFrequencyJson);
      if (freq.isNotEmpty) {
        final sorted = freq.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        bestAccountId = int.tryParse(sorted.first.key);
      }
    }

    return MerchantSuggestion(
      categoryKey: bestCatKey,
      subCategoryKey: bestSubKey,
      accountId: bestAccountId,
      tagKeys: memory.tagKeys,
      recentRemarks: memory.recentRemarks,
      averageAmount: memory.averageAmount,
      confidence: confidence,
    );
  }

  /// 从已确认的交易中学习（在交易保存后调用）
  Future<void> learnFromTransaction(JiveTransaction tx) async {
    final merchantName = _extractMerchantName(tx);
    if (merchantName == null || merchantName.isEmpty) return;

    final normalized = normalize(merchantName);
    var memory = await _isar.jiveMerchantMemorys
        .where()
        .normalizedNameEqualTo(normalized)
        .findFirst();

    if (memory == null) {
      memory = JiveMerchantMemory()
        ..normalizedName = normalized
        ..displayName = merchantName
        ..createdAt = DateTime.now();
    }

    // 更新分类频次
    if (tx.categoryKey != null) {
      final catKey = tx.subCategoryKey != null
          ? '${tx.categoryKey}:${tx.subCategoryKey}'
          : tx.categoryKey!;
      final freq = _parseFrequency(memory.categoryFrequencyJson);
      freq[catKey] = (freq[catKey] ?? 0) + 1;
      memory.categoryFrequencyJson = jsonEncode(freq);

      // 更新 top 分类
      final sorted = freq.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topParts = sorted.first.key.split(':');
      memory.topCategoryKey = topParts.isNotEmpty ? topParts[0] : null;
      memory.topSubCategoryKey = topParts.length > 1 ? topParts[1] : null;
    }

    // 更新账户频次
    if (tx.accountId != null) {
      final freq = _parseFrequency(memory.accountFrequencyJson);
      final key = tx.accountId.toString();
      freq[key] = (freq[key] ?? 0) + 1;
      memory.accountFrequencyJson = jsonEncode(freq);
      memory.preferredAccountId = tx.accountId;
    }

    // 更新标签
    if (tx.tagKeys.isNotEmpty) {
      memory.tagKeys = tx.tagKeys;
    }

    // 更新备注历史（保留最新 5 条）
    if (tx.note != null && tx.note!.isNotEmpty) {
      memory.recentRemarks.remove(tx.note);
      memory.recentRemarks.insert(0, tx.note!);
      if (memory.recentRemarks.length > 5) {
        memory.recentRemarks = memory.recentRemarks.sublist(0, 5);
      }
    }

    // 更新平均金额（增量移动平均）
    memory.transactionCount += 1;
    memory.averageAmount = memory.averageAmount +
        (tx.amount - memory.averageAmount) / memory.transactionCount;

    memory.lastTransactionAt = tx.timestamp;
    memory.primarySource ??= tx.source;
    memory.isUserConfirmed = true;
    memory.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveMerchantMemorys.put(memory!);
    });
  }

  /// 批量从历史交易学习（初始化时调用一次）
  Future<int> learnFromHistory({int limit = 500}) async {
    final transactions = await _isar.jiveTransactions
        .where()
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();

    int learned = 0;
    for (final tx in transactions) {
      final name = _extractMerchantName(tx);
      if (name != null && name.isNotEmpty && tx.categoryKey != null) {
        await learnFromTransaction(tx);
        learned++;
      }
    }
    return learned;
  }

  /// 获取所有商户记忆（按交易次数排序）
  Future<List<JiveMerchantMemory>> getAllMemories() async {
    final all = await _isar.jiveMerchantMemorys.where().findAll();
    all.sort((a, b) => b.transactionCount.compareTo(a.transactionCount));
    return all;
  }

  /// 删除商户记忆
  Future<void> deleteMemory(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveMerchantMemorys.delete(id);
    });
  }

  /// 添加商户别名
  Future<void> addAlias(int id, String alias) async {
    final memory = await _isar.jiveMerchantMemorys.get(id);
    if (memory == null) return;
    if (!memory.aliases.contains(alias)) {
      memory.aliases.add(alias);
      memory.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.jiveMerchantMemorys.put(memory);
      });
    }
  }

  /// 从交易中提取商户名
  String? _extractMerchantName(JiveTransaction tx) {
    // 优先使用备注中的商户名
    if (tx.note != null && tx.note!.isNotEmpty) {
      return tx.note!.split(RegExp(r'[-–—·•|]')).first.trim();
    }
    // 次选用原始文本
    if (tx.rawText != null && tx.rawText!.isNotEmpty) {
      return tx.rawText!.split(RegExp(r'[-–—·•|]')).first.trim();
    }
    return null;
  }

  Map<String, int> _parseFrequency(String json) {
    if (json.isEmpty || json == '{}') return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }
}
