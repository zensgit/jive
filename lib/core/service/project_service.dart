import 'package:isar/isar.dart';
import '../database/project_model.dart';
import '../database/transaction_model.dart';
import 'transaction_service.dart';

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

  /// 重新启用项目
  Future<void> reactivateProject(JiveProject project) async {
    project.status = 'active';
    project.completedDate = null;
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

  /// 初始化测试项目（如果没有项目则创建一个测试项目并关联最近几笔支出）
  Future<void> initTestProjectIfNeeded() async {
    final existingProjects = await _isar.jiveProjects.where().findAll();
    if (existingProjects.isNotEmpty) return;

    // 创建测试项目
    final project = JiveProject()
      ..name = '日本旅行'
      ..description = '2024年春节日本之旅'
      ..iconName = 'flight'
      ..colorHex = '#2196F3'
      ..budget = 15000
      ..startDate = DateTime.now().subtract(const Duration(days: 7))
      ..status = 'active'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveProjects.put(project);
    });

    // 将最近5笔支出关联到这个项目
    final recentExpenses = await _isar.jiveTransactions
        .filter()
        .typeEqualTo('expense')
        .sortByTimestampDesc()
        .limit(5)
        .findAll();

    if (recentExpenses.isNotEmpty) {
      await _isar.writeTxn(() async {
        for (final tx in recentExpenses) {
          tx.projectId = project.id;
          TransactionService.touchSyncMetadata(tx);
          await _isar.jiveTransactions.put(tx);
        }
      });
    }
  }

  /// 获取项目每日支出数据（用于趋势图）
  Future<List<DailySpending>> getProjectDailySpending(
    int projectId, {
    int days = 30,
  }) async {
    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    final transactions = await _isar.jiveTransactions
        .filter()
        .projectIdEqualTo(projectId)
        .typeEqualTo('expense')
        .timestampGreaterThan(startDate)
        .findAll();

    // 按日期分组
    final dailyMap = <String, double>{};
    for (final tx in transactions) {
      final dateKey =
          '${tx.timestamp.year}-${tx.timestamp.month.toString().padLeft(2, '0')}-${tx.timestamp.day.toString().padLeft(2, '0')}';
      dailyMap[dateKey] = (dailyMap[dateKey] ?? 0) + tx.amount;
    }

    // 生成完整日期列表
    final result = <DailySpending>[];
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      result.add(DailySpending(date: date, amount: dailyMap[dateKey] ?? 0));
    }

    return result;
  }

  /// 获取项目累计支出数据（用于累计趋势图）
  Future<List<DailySpending>> getProjectCumulativeSpending(
    int projectId, {
    int days = 30,
  }) async {
    final dailyData = await getProjectDailySpending(projectId, days: days);

    double cumulative = 0;
    final result = <DailySpending>[];
    for (final daily in dailyData) {
      cumulative += daily.amount;
      result.add(DailySpending(date: daily.date, amount: cumulative));
    }

    return result;
  }
}

/// 每日支出数据模型
class DailySpending {
  final DateTime date;
  final double amount;

  DailySpending({required this.date, required this.amount});
}
