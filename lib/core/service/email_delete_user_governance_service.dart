import 'dart:convert';

class EmailDeleteUserGovernanceInput {
  const EmailDeleteUserGovernanceInput({
    required this.accountId,
    required this.email,
    required this.emailVerified,
    required this.verificationCodeSent,
    required this.verificationCodeValidMinutes,
    required this.clearDataReady,
    required this.backupConfirmed,
    required this.deletionCooldownHours,
    required this.highRiskOperation,
    required this.currentSessionValid,
    required this.confirmTextMatched,
    required this.pendingSharedBookCount,
  });

  final String accountId;
  final String email;
  final bool emailVerified;
  final bool verificationCodeSent;
  final int verificationCodeValidMinutes;
  final bool clearDataReady;
  final bool backupConfirmed;
  final int deletionCooldownHours;
  final bool highRiskOperation;
  final bool currentSessionValid;
  final bool confirmTextMatched;
  final int pendingSharedBookCount;

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'email': email,
      'emailVerified': emailVerified,
      'verificationCodeSent': verificationCodeSent,
      'verificationCodeValidMinutes': verificationCodeValidMinutes,
      'clearDataReady': clearDataReady,
      'backupConfirmed': backupConfirmed,
      'deletionCooldownHours': deletionCooldownHours,
      'highRiskOperation': highRiskOperation,
      'currentSessionValid': currentSessionValid,
      'confirmTextMatched': confirmTextMatched,
      'pendingSharedBookCount': pendingSharedBookCount,
    };
  }
}

class EmailDeleteUserGovernanceResult {
  const EmailDeleteUserGovernanceResult({
    required this.input,
    required this.status,
    required this.governanceMode,
    required this.reason,
    required this.action,
    required this.recommendation,
  });

  final EmailDeleteUserGovernanceInput input;
  final String status;
  final String governanceMode;
  final String reason;
  final String action;
  final String recommendation;

  Map<String, dynamic> toJson() {
    return {
      'input': input.toJson(),
      'status': status,
      'governanceMode': governanceMode,
      'reason': reason,
      'action': action,
      'recommendation': recommendation,
    };
  }
}

class EmailDeleteUserGovernanceService {
  const EmailDeleteUserGovernanceService();

  EmailDeleteUserGovernanceResult evaluate({
    required String accountId,
    required String email,
    required bool emailVerified,
    required bool verificationCodeSent,
    required int verificationCodeValidMinutes,
    required bool clearDataReady,
    required bool backupConfirmed,
    required int deletionCooldownHours,
    required bool highRiskOperation,
    required bool currentSessionValid,
    required bool confirmTextMatched,
    required int pendingSharedBookCount,
  }) {
    final normalizedAccountId = accountId.trim();
    final normalizedEmail = email.trim();
    final safeCodeValidMinutes = verificationCodeValidMinutes < 0
        ? 0
        : verificationCodeValidMinutes;
    final safeDeletionCooldownHours = deletionCooldownHours < 0
        ? 0
        : deletionCooldownHours;
    final safePendingSharedBookCount = pendingSharedBookCount < 0
        ? 0
        : pendingSharedBookCount;

    final input = EmailDeleteUserGovernanceInput(
      accountId: normalizedAccountId,
      email: normalizedEmail,
      emailVerified: emailVerified,
      verificationCodeSent: verificationCodeSent,
      verificationCodeValidMinutes: safeCodeValidMinutes,
      clearDataReady: clearDataReady,
      backupConfirmed: backupConfirmed,
      deletionCooldownHours: safeDeletionCooldownHours,
      highRiskOperation: highRiskOperation,
      currentSessionValid: currentSessionValid,
      confirmTextMatched: confirmTextMatched,
      pendingSharedBookCount: safePendingSharedBookCount,
    );

    if (normalizedAccountId.isEmpty ||
        normalizedEmail.isEmpty ||
        !normalizedEmail.contains('@') ||
        !currentSessionValid) {
      return EmailDeleteUserGovernanceResult(
        input: input,
        status: 'block',
        governanceMode: 'invalid_delete_context',
        reason: '账号上下文、邮箱格式或会话状态无效',
        action: '重新登录并校验账号上下文后再尝试注销',
        recommendation: '建议强制重新鉴权后执行销户流程。',
      );
    }

    if (highRiskOperation || safePendingSharedBookCount > 0) {
      return EmailDeleteUserGovernanceResult(
        input: input,
        status: 'block',
        governanceMode: 'delete_risk_block',
        reason: '存在高风险操作或未迁移的共享账本成员关系',
        action: '先解除共享关系并完成风险审核',
        recommendation: '建议销户前完成账本与成员迁移。',
      );
    }

    if (!emailVerified || !verificationCodeSent) {
      return EmailDeleteUserGovernanceResult(
        input: input,
        status: 'review',
        governanceMode: 'email_verify_review',
        reason: '邮箱验证或验证码发送前置条件未满足',
        action: '完成邮箱验证并发送验证码',
        recommendation: '建议销户必须经过邮箱二次校验。',
      );
    }

    if (safeCodeValidMinutes <= 0 || safeCodeValidMinutes > 30) {
      return EmailDeleteUserGovernanceResult(
        input: input,
        status: 'block',
        governanceMode: 'verification_code_window_block',
        reason: '验证码有效期不合法，存在销户冒用风险',
        action: '重新获取验证码并限制有效期',
        recommendation: '建议验证码有效期控制在 10 分钟内。',
      );
    }

    if (safeDeletionCooldownHours > 0) {
      return EmailDeleteUserGovernanceResult(
        input: input,
        status: 'review',
        governanceMode: 'deletion_cooldown_review',
        reason: '销户流程处于冷却窗口',
        action: '等待冷却结束并再次确认销户意图',
        recommendation: '建议冷却期内展示可恢复入口。',
      );
    }

    if (!clearDataReady || !backupConfirmed || !confirmTextMatched) {
      return EmailDeleteUserGovernanceResult(
        input: input,
        status: 'review',
        governanceMode: 'pre_delete_check_review',
        reason: '清理数据、备份确认或销户确认文案未完成',
        action: '完成清理前置检查并二次确认销户文案',
        recommendation: '建议清理与备份核验通过后再执行销户。',
      );
    }

    return EmailDeleteUserGovernanceResult(
      input: input,
      status: 'ready',
      governanceMode: 'email_delete_user_ready',
      reason: '邮箱注销治理检查通过',
      action: '允许执行清理并发起账号注销',
      recommendation: '建议注销后立即回收会话并记录审计事件。',
    );
  }

  String exportJson(
    EmailDeleteUserGovernanceResult result, {
    bool pretty = true,
  }) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(result.toJson());
    }
    return jsonEncode(result.toJson());
  }

  String exportMarkdown(EmailDeleteUserGovernanceResult result) {
    return [
      '# 邮箱注销治理报告',
      '',
      '- status: ${result.status}',
      '- governanceMode: ${result.governanceMode}',
      '- reason: ${result.reason}',
      '- action: ${result.action}',
      '- recommendation: ${result.recommendation}',
      '',
      '| field | value |',
      '| --- | --- |',
      '| accountId | ${result.input.accountId} |',
      '| email | ${result.input.email} |',
      '| emailVerified | ${result.input.emailVerified} |',
      '| verificationCodeSent | ${result.input.verificationCodeSent} |',
      '| verificationCodeValidMinutes | ${result.input.verificationCodeValidMinutes} |',
      '| clearDataReady | ${result.input.clearDataReady} |',
      '| backupConfirmed | ${result.input.backupConfirmed} |',
      '| deletionCooldownHours | ${result.input.deletionCooldownHours} |',
      '| highRiskOperation | ${result.input.highRiskOperation} |',
      '| currentSessionValid | ${result.input.currentSessionValid} |',
      '| confirmTextMatched | ${result.input.confirmTextMatched} |',
      '| pendingSharedBookCount | ${result.input.pendingSharedBookCount} |',
    ].join('\n');
  }

  String exportCsv(EmailDeleteUserGovernanceResult result) {
    final values = <String>[
      _csvEscape(result.input.accountId),
      _csvEscape(result.input.email),
      result.input.emailVerified ? '1' : '0',
      result.input.verificationCodeSent ? '1' : '0',
      '${result.input.verificationCodeValidMinutes}',
      result.input.clearDataReady ? '1' : '0',
      result.input.backupConfirmed ? '1' : '0',
      '${result.input.deletionCooldownHours}',
      result.input.highRiskOperation ? '1' : '0',
      result.input.currentSessionValid ? '1' : '0',
      result.input.confirmTextMatched ? '1' : '0',
      '${result.input.pendingSharedBookCount}',
      result.status,
      result.governanceMode,
      _csvEscape(result.reason),
      _csvEscape(result.action),
      _csvEscape(result.recommendation),
    ];
    return [
      'account_id,email,email_verified,verification_code_sent,verification_code_valid_minutes,clear_data_ready,backup_confirmed,deletion_cooldown_hours,high_risk_operation,current_session_valid,confirm_text_matched,pending_shared_book_count,status,governance_mode,reason,action,recommendation',
      values.join(','),
    ].join('\n');
  }
}

String _csvEscape(String value) {
  if (!value.contains(',') && !value.contains('"') && !value.contains('\n')) {
    return value;
  }
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}
