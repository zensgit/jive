import 'package:isar/isar.dart';

import '../data/scene_templates.dart';
import '../database/book_model.dart';
import '../database/budget_model.dart';
import '../database/tag_model.dart';
import 'book_service.dart';
import 'budget_service.dart';
import 'category_service.dart';
import 'tag_service.dart';

/// 场景模板服务 — 将预置场景一键应用为 账本 + 分类 + 标签 + 预算。
class SceneTemplateService {
  final Isar _isar;
  final BookService _bookService;
  final CategoryService _categoryService;
  final TagService _tagService;
  final BudgetService _budgetService;

  SceneTemplateService(
    this._isar, {
    required BookService bookService,
    required CategoryService categoryService,
    required TagService tagService,
    required BudgetService budgetService,
  })  : _bookService = bookService,
        _categoryService = categoryService,
        _tagService = tagService,
        _budgetService = budgetService;

  /// 返回所有预置场景模板。
  List<SceneTemplate> getTemplates() => kSceneTemplates;

  /// 应用场景模板：
  /// 1. 创建新账本
  /// 2. 确保分类已初始化
  /// 3. 创建标签（如果不存在）
  /// 4. 创建月度预算
  Future<JiveBook> applyTemplate(SceneTemplate template) async {
    // 1. 创建账本
    final book = await _bookService.createBook(
      name: '${template.emoji} ${template.name}',
      iconName: 'book',
    );

    // 2. 确保默认分类已初始化（幂等）
    await _categoryService.initDefaultCategories();

    // 3. 创建标签（跳过已存在的）
    for (final tagName in template.tagKeys) {
      final existing = await _isar
          .collection<JiveTag>()
          .filter()
          .nameEqualTo(tagName)
          .findFirst();
      if (existing == null) {
        await _tagService.createTag(name: tagName);
      }
    }

    // 4. 创建月度预算
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final budget = await _budgetService.createBudget(
      name: '${template.name}预算',
      amount: template.suggestedBudget,
      currency: 'CNY',
      startDate: startDate,
      endDate: endDate,
      period: 'monthly',
    );

    // 关联预算到新账本
    budget.bookId = book.id;
    await _isar.writeTxn(() async {
      await _isar.jiveBudgets.put(budget);
    });

    return book;
  }
}
