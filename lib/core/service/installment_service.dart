import 'package:isar/isar.dart';

import '../database/account_model.dart';
import '../database/auto_draft_model.dart';
import '../database/installment_model.dart';
import '../database/transaction_model.dart';

class InstallmentProcessResult {
  final int generatedDrafts;
  final int committedTransactions;
  final int finishedInstallments;

  const InstallmentProcessResult({
    required this.generatedDrafts,
    required this.committedTransactions,
    required this.finishedInstallments,
  });
}

class InstallmentService {
  InstallmentService(this.isar);

  final Isar isar;

  Future<List<JiveInstallment>> getInstallments({
    bool includeInactive = true,
  }) async {
    final list = includeInactive
        ? await isar.collection<JiveInstallment>().where().findAll()
        : await isar
              .collection<JiveInstallment>()
              .filter()
              .isActiveEqualTo(true)
              .findAll();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<JiveInstallment> createInstallment(JiveInstallment installment) async {
    final account = await isar.collection<JiveAccount>().get(
      installment.accountId,
    );
    if (account == null) {
      throw StateError('分期账户不存在');
    }
    if (account.type != 'liability' || account.subType != 'credit') {
      throw StateError('分期账户必须是信用卡');
    }
    if (installment.totalPeriods <= 0) {
      throw StateError('分期期数必须大于 0');
    }
    if (installment.principalAmount <= 0) {
      throw StateError('分期金额必须大于 0');
    }
    if (installment.totalFee < 0) {
      throw StateError('分期利息不能小于 0');
    }

    final now = DateTime.now();
    installment
      ..key = installment.key.trim().isEmpty
          ? _buildInstallmentKey(now)
          : installment.key.trim()
      ..name = installment.name.trim()
      ..feeType = InstallmentFeeType.fromValue(installment.feeType).value
      ..remainderType = InstallmentRemainderType.fromValue(
        installment.remainderType,
      ).value
      ..commitMode = InstallmentCommitMode.fromValue(
        installment.commitMode,
      ).value
      ..status = InstallmentStatus.active.value
      ..isActive = true
      ..executedPeriods = 0
      ..nextDueAt = _normalizedDueTime(installment.startDate)
      ..createdAt = now
      ..updatedAt = now;

    await isar.writeTxn(() async {
      await isar.collection<JiveInstallment>().put(installment);
    });
    return installment;
  }

  Future<void> updateInstallment(JiveInstallment installment) async {
    final existing = await isar.collection<JiveInstallment>().get(
      installment.id,
    );
    if (existing == null) {
      throw StateError('分期不存在');
    }
    if (installment.totalPeriods <= 0 || installment.principalAmount <= 0) {
      throw StateError('分期参数无效');
    }
    installment
      ..name = installment.name.trim()
      ..feeType = InstallmentFeeType.fromValue(installment.feeType).value
      ..remainderType = InstallmentRemainderType.fromValue(
        installment.remainderType,
      ).value
      ..commitMode = InstallmentCommitMode.fromValue(
        installment.commitMode,
      ).value
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.collection<JiveInstallment>().put(installment);
    });
  }

  Future<void> markInstallmentPrepaid(int installmentId) async {
    final installment = await isar.collection<JiveInstallment>().get(
      installmentId,
    );
    if (installment == null) return;
    installment
      ..status = InstallmentStatus.prepaid.value
      ..isActive = false
      ..finishedAt = DateTime.now()
      ..updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.collection<JiveInstallment>().put(installment);
    });
  }

  List<InstallmentPlanItem> buildPlanPreview(JiveInstallment installment) {
    if (installment.totalPeriods <= 0) return const [];
    final principal = _splitAmount(
      total: installment.principalAmount,
      count: installment.totalPeriods,
      remainderType: InstallmentRemainderType.fromValue(
        installment.remainderType,
      ),
    );
    final fee = _splitFee(
      totalFee: installment.totalFee,
      count: installment.totalPeriods,
      feeType: InstallmentFeeType.fromValue(installment.feeType),
      remainderType: InstallmentRemainderType.fromValue(
        installment.remainderType,
      ),
    );
    final list = <InstallmentPlanItem>[];
    for (var i = 0; i < installment.totalPeriods; i++) {
      list.add(
        InstallmentPlanItem(
          period: i + 1,
          dueAt: _dueAt(installment.startDate, i),
          principal: principal[i],
          fee: fee[i],
        ),
      );
    }
    return list;
  }

  Future<InstallmentProcessResult> processDueInstallments({
    DateTime? now,
  }) async {
    final reference = now ?? DateTime.now();
    final installments = await isar
        .collection<JiveInstallment>()
        .filter()
        .isActiveEqualTo(true)
        .and()
        .statusEqualTo(InstallmentStatus.active.value)
        .findAll();

    if (installments.isEmpty) {
      return const InstallmentProcessResult(
        generatedDrafts: 0,
        committedTransactions: 0,
        finishedInstallments: 0,
      );
    }

    var drafts = 0;
    var commits = 0;
    var finished = 0;

    for (final installment in installments) {
      final plan = buildPlanPreview(installment);
      if (plan.isEmpty) continue;

      while (!installment.nextDueAt.isAfter(reference) &&
          installment.executedPeriods < installment.totalPeriods) {
        final period = installment.executedPeriods;
        final item = plan[period];
        final dedupKey = _buildDedupKey(installment.id, item.period);

        if (InstallmentCommitMode.fromValue(installment.commitMode) ==
            InstallmentCommitMode.draft) {
          final created = await _createDraftIfAbsent(
            installment,
            item,
            dedupKey,
          );
          if (created) drafts += 1;
        } else {
          final created = await _createTransactionIfAbsent(
            installment,
            item,
            dedupKey,
          );
          if (created) commits += 1;
        }

        installment.executedPeriods += 1;
        installment.nextDueAt = _dueAt(
          installment.startDate,
          installment.executedPeriods,
        );
      }

      if (installment.executedPeriods >= installment.totalPeriods) {
        installment
          ..status = InstallmentStatus.finished.value
          ..isActive = false
          ..finishedAt = installment.finishedAt ?? reference;
        finished += 1;
      }
      installment.updatedAt = DateTime.now();
    }

    await isar.writeTxn(() async {
      await isar.collection<JiveInstallment>().putAll(installments);
    });

    return InstallmentProcessResult(
      generatedDrafts: drafts,
      committedTransactions: commits,
      finishedInstallments: finished,
    );
  }

  Future<bool> _createDraftIfAbsent(
    JiveInstallment installment,
    InstallmentPlanItem item,
    String dedupKey,
  ) async {
    var created = false;
    await isar.writeTxn(() async {
      final existing = await isar
          .collection<JiveAutoDraft>()
          .where()
          .dedupKeyEqualTo(dedupKey)
          .findFirst();
      if (existing != null) return;

      final draft = JiveAutoDraft()
        ..amount = _round2(item.total)
        ..source = 'Installment'
        ..timestamp = item.dueAt
        ..rawText = '${installment.name} 第${item.period}期'
        ..metadataJson = null
        ..type = 'expense'
        ..categoryKey = installment.categoryKey
        ..subCategoryKey = installment.subCategoryKey
        ..category = null
        ..subCategory = null
        ..accountId = installment.accountId
        ..toAccountId = null
        ..dedupKey = dedupKey
        ..createdAt = DateTime.now()
        ..tagKeys = const [];
      await isar.collection<JiveAutoDraft>().put(draft);
      created = true;
    });
    return created;
  }

  Future<bool> _createTransactionIfAbsent(
    JiveInstallment installment,
    InstallmentPlanItem item,
    String dedupKey,
  ) async {
    var created = false;
    await isar.writeTxn(() async {
      final existing = await isar
          .collection<JiveTransaction>()
          .where()
          .recurringKeyEqualTo(dedupKey)
          .findFirst();
      if (existing != null) return;

      final tx = JiveTransaction()
        ..amount = _round2(item.total)
        ..source = 'Installment'
        ..timestamp = item.dueAt
        ..rawText = '${installment.name} 第${item.period}期'
        ..type = 'expense'
        ..categoryKey = installment.categoryKey
        ..subCategoryKey = installment.subCategoryKey
        ..category = null
        ..subCategory = null
        ..note = installment.note
        ..accountId = installment.accountId
        ..toAccountId = null
        ..tagKeys = []
        ..smartTagKeys = []
        ..recurringRuleId = null
        ..recurringKey = dedupKey;
      await isar.collection<JiveTransaction>().put(tx);
      created = true;
    });
    return created;
  }

  List<double> _splitFee({
    required double totalFee,
    required int count,
    required InstallmentFeeType feeType,
    required InstallmentRemainderType remainderType,
  }) {
    if (count <= 0) return const [];
    if (totalFee <= 0) return List<double>.filled(count, 0);

    switch (feeType) {
      case InstallmentFeeType.first:
        final list = List<double>.filled(count, 0);
        list[0] = _round2(totalFee);
        return list;
      case InstallmentFeeType.last:
        final list = List<double>.filled(count, 0);
        list[count - 1] = _round2(totalFee);
        return list;
      case InstallmentFeeType.average:
        return _splitAmount(
          total: totalFee,
          count: count,
          remainderType: remainderType,
        );
    }
  }

  List<double> _splitAmount({
    required double total,
    required int count,
    required InstallmentRemainderType remainderType,
  }) {
    if (count <= 0) return const [];

    switch (remainderType) {
      case InstallmentRemainderType.intFirst:
      case InstallmentRemainderType.intLast:
        return _splitWithScale(
          total: total,
          count: count,
          scale: 1,
          toFirst: remainderType == InstallmentRemainderType.intFirst,
        );
      case InstallmentRemainderType.averageFirst:
      case InstallmentRemainderType.averageLast:
        return _splitWithScale(
          total: total,
          count: count,
          scale: 100,
          toFirst: remainderType == InstallmentRemainderType.averageFirst,
        );
      case InstallmentRemainderType.roundFirst:
      case InstallmentRemainderType.roundLast:
        final avg = total / count;
        final rounded = List<double>.filled(count, _round2(avg));
        final sum = rounded.fold<double>(0, (p, e) => p + e);
        final delta = _round2(total - sum);
        if (delta != 0) {
          final index = remainderType == InstallmentRemainderType.roundFirst
              ? 0
              : count - 1;
          rounded[index] = _round2(rounded[index] + delta);
        }
        return rounded;
    }
  }

  List<double> _splitWithScale({
    required double total,
    required int count,
    required int scale,
    required bool toFirst,
  }) {
    final scaled = (total * scale).round();
    final base = scaled ~/ count;
    final remainder = scaled - base * count;
    final result = List<int>.filled(count, base);
    if (remainder > 0) {
      final index = toFirst ? 0 : count - 1;
      result[index] += remainder;
    }
    return result.map((v) => v / scale).toList(growable: false);
  }

  DateTime _dueAt(DateTime startDate, int offset) {
    final base = _normalizedDueTime(startDate);
    final targetMonth = base.month + offset;
    final targetYear = base.year + (targetMonth - 1) ~/ 12;
    final month = ((targetMonth - 1) % 12) + 1;
    final day = base.day;
    final maxDay = DateTime(targetYear, month + 1, 0).day;
    final safeDay = day > maxDay ? maxDay : day;
    return DateTime(
      targetYear,
      month,
      safeDay,
      base.hour,
      base.minute,
      base.second,
      base.millisecond,
      base.microsecond,
    );
  }

  DateTime _normalizedDueTime(DateTime dateTime) {
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
    );
  }

  String _buildInstallmentKey(DateTime now) {
    return 'install_${now.microsecondsSinceEpoch}';
  }

  String _buildDedupKey(int installmentId, int period) {
    return 'installment_${installmentId}_$period';
  }

  double _round2(double value) {
    return (value * 100).round() / 100;
  }
}
