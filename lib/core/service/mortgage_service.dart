import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

/// 还款方式
enum MortgageMethod {
  equalPayment('equal_payment'), // 等额本息
  equalPrincipal('equal_principal'); // 等额本金

  final String value;
  const MortgageMethod(this.value);

  String get label {
    switch (this) {
      case MortgageMethod.equalPayment:
        return '等额本息';
      case MortgageMethod.equalPrincipal:
        return '等额本金';
    }
  }

  static MortgageMethod fromValue(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => equalPayment);
}

/// 房贷基本信息
class MortgageInfo {
  final String id;
  final String name;
  final double principal;
  final double annualRate;
  final int termMonths;
  final double monthlyPayment;
  final MortgageMethod method;
  final DateTime startDate;

  const MortgageInfo({
    required this.id,
    required this.name,
    required this.principal,
    required this.annualRate,
    required this.termMonths,
    required this.monthlyPayment,
    required this.method,
    required this.startDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'principal': principal,
        'annualRate': annualRate,
        'termMonths': termMonths,
        'monthlyPayment': monthlyPayment,
        'method': method.value,
        'startDate': startDate.toIso8601String(),
      };

  factory MortgageInfo.fromJson(Map<String, dynamic> json) => MortgageInfo(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '房贷',
        principal: (json['principal'] as num).toDouble(),
        annualRate: (json['annualRate'] as num).toDouble(),
        termMonths: json['termMonths'] as int,
        monthlyPayment: (json['monthlyPayment'] as num).toDouble(),
        method: MortgageMethod.fromValue(json['method'] as String),
        startDate: DateTime.parse(json['startDate'] as String),
      );
}

/// 还款进度
class MortgageProgress {
  final int paidMonths;
  final int remainingMonths;
  final double paidPrincipal;
  final double remainingPrincipal;
  final double paidInterest;
  final double totalInterest;

  const MortgageProgress({
    required this.paidMonths,
    required this.remainingMonths,
    required this.paidPrincipal,
    required this.remainingPrincipal,
    required this.paidInterest,
    required this.totalInterest,
  });
}

/// 每月还款明细
class MortgagePayment {
  final int month;
  final double principal;
  final double interest;
  final double total;
  final double remainingPrincipal;

  const MortgagePayment({
    required this.month,
    required this.principal,
    required this.interest,
    required this.total,
    required this.remainingPrincipal,
  });
}

/// 房贷管理服务
class MortgageService {
  static const _prefKey = 'jive_mortgages';

  // ── 计算月供 ──────────────────────────────────────────────────────────────

  /// 等额本息月供
  static double calcEqualPaymentMonthly(
      double principal, double annualRate, int termMonths) {
    if (termMonths <= 0) return 0;
    final r = annualRate / 12;
    if (r == 0) return principal / termMonths;
    final factor = math.pow(1 + r, termMonths);
    return principal * r * factor / (factor - 1);
  }

  /// 等额本金首月月供
  static double calcEqualPrincipalFirstMonthly(
      double principal, double annualRate, int termMonths) {
    if (termMonths <= 0) return 0;
    final r = annualRate / 12;
    return principal / termMonths + principal * r;
  }

  // ── 还款进度 ──────────────────────────────────────────────────────────────

  static MortgageProgress calculateProgress(MortgageInfo info) {
    final schedule = getAmortizationSchedule(info);
    final now = DateTime.now();
    final monthsElapsed = (now.year - info.startDate.year) * 12 +
        (now.month - info.startDate.month);
    final paidMonths = monthsElapsed.clamp(0, info.termMonths);

    double paidPrincipal = 0;
    double paidInterest = 0;
    double totalInterest = 0;

    for (int i = 0; i < schedule.length; i++) {
      totalInterest += schedule[i].interest;
      if (i < paidMonths) {
        paidPrincipal += schedule[i].principal;
        paidInterest += schedule[i].interest;
      }
    }

    return MortgageProgress(
      paidMonths: paidMonths,
      remainingMonths: info.termMonths - paidMonths,
      paidPrincipal: _round2(paidPrincipal),
      remainingPrincipal: _round2(info.principal - paidPrincipal),
      paidInterest: _round2(paidInterest),
      totalInterest: _round2(totalInterest),
    );
  }

  // ── 还款计划表 ────────────────────────────────────────────────────────────

  static List<MortgagePayment> getAmortizationSchedule(MortgageInfo info) {
    switch (info.method) {
      case MortgageMethod.equalPayment:
        return _equalPaymentSchedule(info);
      case MortgageMethod.equalPrincipal:
        return _equalPrincipalSchedule(info);
    }
  }

  static List<MortgagePayment> _equalPaymentSchedule(MortgageInfo info) {
    final r = info.annualRate / 12;
    final monthly = info.monthlyPayment;
    double remaining = info.principal;
    final result = <MortgagePayment>[];

    for (int i = 1; i <= info.termMonths; i++) {
      final interest = remaining * r;
      final principal = monthly - interest;
      remaining -= principal;
      if (remaining < 0) remaining = 0;
      result.add(MortgagePayment(
        month: i,
        principal: _round2(principal),
        interest: _round2(interest),
        total: _round2(monthly),
        remainingPrincipal: _round2(remaining),
      ));
    }
    return result;
  }

  static List<MortgagePayment> _equalPrincipalSchedule(MortgageInfo info) {
    final r = info.annualRate / 12;
    final monthlyPrincipal = info.principal / info.termMonths;
    double remaining = info.principal;
    final result = <MortgagePayment>[];

    for (int i = 1; i <= info.termMonths; i++) {
      final interest = remaining * r;
      remaining -= monthlyPrincipal;
      if (remaining < 0) remaining = 0;
      result.add(MortgagePayment(
        month: i,
        principal: _round2(monthlyPrincipal),
        interest: _round2(interest),
        total: _round2(monthlyPrincipal + interest),
        remainingPrincipal: _round2(remaining),
      ));
    }
    return result;
  }

  // ── SharedPreferences 持久化 ──────────────────────────────────────────────

  static Future<List<MortgageInfo>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => MortgageInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveAll(List<MortgageInfo> mortgages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKey, jsonEncode(mortgages.map((m) => m.toJson()).toList()));
  }

  static Future<void> addMortgage(MortgageInfo info) async {
    final list = await loadAll();
    list.add(info);
    await saveAll(list);
  }

  static Future<void> removeMortgage(String id) async {
    final list = await loadAll();
    list.removeWhere((m) => m.id == id);
    await saveAll(list);
  }

  static double _round2(double value) => (value * 100).round() / 100;
}
