enum AccountBookDeleteTransferStatus {
  ready('ready'),
  review('review'),
  block('block');

  const AccountBookDeleteTransferStatus(this.value);
  final String value;
}

enum AccountBookDeleteTransferMode {
  direct('direct'),
  manualReview('manual_review'),
  blocked('blocked');

  const AccountBookDeleteTransferMode(this.value);
  final String value;
}

class AccountBookDeleteTransferPolicyResult {
  final AccountBookDeleteTransferStatus status;
  final AccountBookDeleteTransferMode mode;
  final String reason;

  const AccountBookDeleteTransferPolicyResult({
    required this.status,
    this.mode = AccountBookDeleteTransferMode.direct,
    this.reason = '',
  });

  Map<String, dynamic> toJson() => {
        'status': status.value,
        'mode': mode.value,
        'reason': reason,
      };
}
