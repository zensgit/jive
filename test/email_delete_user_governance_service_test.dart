import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/email_delete_user_governance_service.dart';

void main() {
  const service = EmailDeleteUserGovernanceService();

  test('returns block for invalid context', () {
    final result = service.evaluate(
      accountId: 'user-1',
      email: 'user@example.com',
      emailVerified: true,
      verificationCodeSent: true,
      verificationCodeValidMinutes: 10,
      clearDataReady: true,
      backupConfirmed: true,
      deletionCooldownHours: 0,
      highRiskOperation: false,
      currentSessionValid: false,
      confirmTextMatched: true,
      pendingSharedBookCount: 0,
    );

    expect(result.status, 'block');
    expect(result.governanceMode, 'invalid_delete_context');
  });

  test('returns review when preconditions are incomplete', () {
    final result = service.evaluate(
      accountId: 'user-2',
      email: 'user@example.com',
      emailVerified: true,
      verificationCodeSent: true,
      verificationCodeValidMinutes: 10,
      clearDataReady: false,
      backupConfirmed: true,
      deletionCooldownHours: 0,
      highRiskOperation: false,
      currentSessionValid: true,
      confirmTextMatched: true,
      pendingSharedBookCount: 0,
    );

    expect(result.status, 'review');
    expect(result.governanceMode, 'pre_delete_check_review');
  });

  test('returns ready for stable delete context', () {
    final result = service.evaluate(
      accountId: 'user-3',
      email: 'user@example.com',
      emailVerified: true,
      verificationCodeSent: true,
      verificationCodeValidMinutes: 10,
      clearDataReady: true,
      backupConfirmed: true,
      deletionCooldownHours: 0,
      highRiskOperation: false,
      currentSessionValid: true,
      confirmTextMatched: true,
      pendingSharedBookCount: 0,
    );

    expect(result.status, 'ready');
    expect(result.governanceMode, 'email_delete_user_ready');
  });

  test('exports json/markdown/csv contain key fields', () {
    final result = service.evaluate(
      accountId: 'user-4',
      email: 'user@example.com',
      emailVerified: true,
      verificationCodeSent: true,
      verificationCodeValidMinutes: 10,
      clearDataReady: true,
      backupConfirmed: true,
      deletionCooldownHours: 0,
      highRiskOperation: false,
      currentSessionValid: true,
      confirmTextMatched: true,
      pendingSharedBookCount: 0,
    );
    final jsonText = service.exportJson(result);
    final markdown = service.exportMarkdown(result);
    final csv = service.exportCsv(result);
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;

    expect(decoded['status'], 'ready');
    expect(markdown, contains('# 邮箱注销治理报告'));
    expect(csv, contains('account_id,email,email_verified'));
  });
}
