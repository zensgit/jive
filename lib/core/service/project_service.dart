import 'package:isar/isar.dart';
import '../database/project_model.dart';
import '../database/transaction_model.dart';

class ProjectService {
  final Isar _isar;

  ProjectService(this._isar);

  /// 创建项目
  Future<JiveProject> createProject({
    required String name,
    String? description,
    String? iconName,
    String? colorHex,
    double budget = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final project = JiveProject()
      ..name = name
      ..description = description
      ..iconName = iconName
      ..colorHex = colorHex
      ..budget = budget
      ..startDate = startDate ?? DateTime.now()
      ..endDate = endDate
      ..status = 'active'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveProjects.put(project);
    });

    return project;
  }

  /// 获取所有活跃项目
  Future<List<JiveProject>> getActiveProjects() async {
    return await _isar.jiveProjects
        .filter()
        .statusEqualTo('active')
        .sortBySortOrder()
        .findAll();
  }

  /// 获取所有项目（按状态分组）
  Future<Map<String, List<JiveProject>>> getProjectsGrouped() async {
    final projects = await _isar.jiveProjects.where().findAll();
    final grouped = <String, List<JiveProject>>{};

    for (final project in projects) {
      final status = project.status == 'active'
          ? '进行中'
          : project.status == 'completed'
              ? '已完成'
              : '已归档';
      grouped.putIfAbsent(status, () => []).add(project);
    }

    return grouped;
  }

  /// 更新项目
  Future<void> updateProject(JiveProject project) async {
    project.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveProjects.put(project);
    });
  }

  /// 删除项目
  Future<void> deleteProject(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveProjects.delete(id);
    });
  }

  /// 完成项目
  Future<void> completeProject(JiveProject project) async {
    project.status = 'completed';
    project.completedDate = DateTime.now();
    project.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveProjects.put(project);
    });
  }

  /// 归档项目
  Future<void> archiveProject(JiveProject project) async {
    project.status = 'archived';
    project.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveProjects.put(project);
    });
  }

  /// 计算项目已花费金额
  Future<double> calculateProjectSpending(int projectId) async {
    final transactions = await _isar.jiveTransactions
        .filter()
        .projectIdEqualTo(projectId)
        .typeEqualTo('expense')
        .findAll();

    return transactions.fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }

  /// 获取项目交易列表
  Future<List<JiveTransaction>> getProjectTransactions(int projectId) async {
    return await _isar.jiveTransactions
        .filter()
        .projectIdEqualTo(projectId)
        .sortByTimestampDesc()
        .findAll();
  }

  /// 按分类统计项目支出
  Future<Map<String, double>> getProjectCategoryStats(int projectId) async {
    final transactions = await _isar.jiveTransactions
        .filter()
        .projectIdEqualTo(projectId)
        .typeEqualTo('expense')
        .findAll();

    final stats = <String, double>{};
    for (final tx in transactions) {
      final category = tx.category ?? '未分类';
      stats[category] = (stats[category] ?? 0) + tx.amount;
    }

    return stats;
  }
}
