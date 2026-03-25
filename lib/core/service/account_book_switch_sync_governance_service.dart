enum AccountBookSwitchSyncStatus {
  ready('ready'),
  review('review'),
  block('block');

  const AccountBookSwitchSyncStatus(this.value);
  final String value;
}

enum AccountBookSwitchSyncMode {
  direct('direct'),
  manualReview('manual_review'),
  blocked('blocked');

  const AccountBookSwitchSyncMode(this.value);
  final String value;
}

class AccountBookSwitchSyncGovernanceResult {
  final AccountBookSwitchSyncStatus status;
  final AccountBookSwitchSyncMode mode;
  final String reason;

  const AccountBookSwitchSyncGovernanceResult({
    required this.status,
    this.mode = AccountBookSwitchSyncMode.direct,
    this.reason = '',
  });

  Map<String, dynamic> toJson() => {
        'status': status.value,
        'mode': mode.value,
        'reason': reason,
      };
}
