import 'dart:async';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../database/account_model.dart';
import '../database/auto_draft_model.dart';
import '../database/bill_relation_model.dart';
import '../database/budget_model.dart';
import '../database/category_model.dart';
import '../database/currency_model.dart';
import '../database/import_job_model.dart';
import '../database/import_job_record_model.dart';
import '../database/project_model.dart';
import '../database/recurring_rule_model.dart';
import '../database/tag_conversion_log.dart';
import '../database/tag_model.dart';
import '../database/tag_rule_model.dart';
import '../database/template_model.dart';
import '../database/transaction_model.dart';
import '../database/merchant_memory_model.dart';
import '../database/installment_model.dart';
import '../database/bill_split_model.dart';
import '../database/savings_goal_model.dart';
import '../database/dream_log_model.dart';
import '../database/book_model.dart';
import '../database/debt_model.dart';
import '../database/investment_model.dart';
import '../database/sync_conflict_model.dart';
import '../database/reimbursement_model.dart';
import '../database/shared_ledger_model.dart';
import '../database/travel_trip_model.dart';
import '../database/user_auto_rule_model.dart';

/// 统一的数据库服务，确保所有地方使用相同的 schema 列表
class DatabaseService {
  static Isar? _instance;
  static const Duration _openTimeout = Duration(seconds: 10);

  /// 所有 schema 的完整列表（必须保持一致）
  static final List<CollectionSchema<dynamic>> schemas = [
    JiveTransactionSchema,
    JiveCategorySchema,
    JiveCategoryOverrideSchema,
    JiveAccountSchema,
    JiveAutoDraftSchema,
    JiveBillRelationSchema,
    JiveImportJobSchema,
    JiveImportJobRecordSchema,
    JiveInstallmentSchema,
    JiveBudgetSchema,
    JiveBudgetUsageSchema,
    JiveTemplateSchema,
    JiveTagSchema,
    JiveTagGroupSchema,
    JiveTagRuleSchema,
    JiveTagConversionLogSchema,
    JiveProjectSchema,
    JiveCurrencySchema,
    JiveExchangeRateSchema,
    JiveExchangeRateHistorySchema,
    JiveCurrencyPreferenceSchema,
    JiveRecurringRuleSchema,
    JiveMerchantMemorySchema,
    JiveBillSplitSchema,
    JiveSplitMemberSchema,
    JiveSavingsGoalSchema,
    JiveBookSchema,
    JiveDebtSchema,
    JiveDebtPaymentSchema,
    JiveSecuritySchema,
    JiveHoldingSchema,
    JiveInvestmentTransactionSchema,
    JivePriceHistorySchema,
    JiveSyncConflictSchema,
    JiveUserAutoRuleSchema,
    JiveSharedLedgerSchema,
    JiveSharedLedgerMemberSchema,
    JiveDreamLogSchema,
    JiveReimbursementSchema,
    JiveTravelTripSchema,
  ];

  /// 获取或创建 Isar 实例
  static Future<Isar> getInstance() async {
    if (_instance != null && _instance!.isOpen) {
      return _instance!;
    }

    // 检查是否已有实例
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) {
      _instance = existing;
      return _instance!;
    }

    // 创建新实例
    final dir = await getApplicationDocumentsDirectory().timeout(
      _openTimeout,
      onTimeout: () => throw TimeoutException('读取数据库目录超时'),
    );
    _instance = await Isar.open(
      schemas,
      directory: dir.path,
    ).timeout(_openTimeout, onTimeout: () => throw TimeoutException('打开数据库超时'));
    return _instance!;
  }

  /// 关闭数据库（通常不需要调用）
  static Future<void> close() async {
    if (_instance != null && _instance!.isOpen) {
      await _instance!.close();
      _instance = null;
    }
  }
}
