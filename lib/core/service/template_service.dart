import 'package:isar/isar.dart';
import '../database/template_model.dart';
import '../database/transaction_model.dart';

class TemplateService {
  final Isar _isar;

  TemplateService(this._isar);

  /// 从交易创建模板
  Future<JiveTemplate> createFromTransaction({
    required JiveTransaction transaction,
    required String name,
    String? description,
    bool saveAmount = true,
    String? groupName,
  }) async {
    final template = JiveTemplate()
      ..name = name
      ..description = description
      ..amount = saveAmount ? transaction.amount : 0
      ..type = transaction.type ?? 'expense'
      ..accountId = transaction.accountId
      ..toAccountId = transaction.toAccountId
      ..categoryKey = transaction.categoryKey
      ..subCategoryKey = transaction.subCategoryKey
      ..category = transaction.category
      ..subCategory = transaction.subCategory
      ..note = transaction.note
      ..groupName = groupName
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveTemplates.put(template);
    });

    return template;
  }

  /// 获取所有模板（按置顶和使用次数排序）
  Future<List<JiveTemplate>> getTemplates() async {
    return await _isar.jiveTemplates
        .where()
        .sortByIsPinnedDesc()
        .thenByUsageCountDesc()
        .findAll();
  }

  /// 按分组获取模板
  Future<Map<String, List<JiveTemplate>>> getTemplatesGrouped() async {
    final templates = await getTemplates();
    final grouped = <String, List<JiveTemplate>>{};

    // 先添加置顶
    final pinned = templates.where((t) => t.isPinned).toList();
    if (pinned.isNotEmpty) {
      grouped['置顶'] = pinned;
    }

    // 按分组名称分组
    for (final template in templates.where((t) => !t.isPinned)) {
      final group = template.groupName ?? '未分组';
      grouped.putIfAbsent(group, () => []).add(template);
    }

    return grouped;
  }

  /// 更新模板
  Future<void> updateTemplate(JiveTemplate template) async {
    await _isar.writeTxn(() async {
      await _isar.jiveTemplates.put(template);
    });
  }

  /// 删除模板
  Future<void> deleteTemplate(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveTemplates.delete(id);
    });
  }

  /// 使用模板（更新使用次数）
  Future<void> incrementUsage(JiveTemplate template) async {
    template.usageCount++;
    template.lastUsedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveTemplates.put(template);
    });
  }

  /// 切换置顶状态
  Future<void> togglePin(JiveTemplate template) async {
    template.isPinned = !template.isPinned;
    await _isar.writeTxn(() async {
      await _isar.jiveTemplates.put(template);
    });
  }

  /// 从模板创建交易（返回预填充的交易对象，不保存）
  JiveTransaction createTransactionFromTemplate(JiveTemplate template) {
    return JiveTransaction()
      ..amount = template.amount
      ..type = template.type
      ..source = '模板'
      ..timestamp = DateTime.now()
      ..accountId = template.accountId
      ..toAccountId = template.toAccountId
      ..categoryKey = template.categoryKey
      ..subCategoryKey = template.subCategoryKey
      ..category = template.category
      ..subCategory = template.subCategory
      ..note = template.note;
  }
}
