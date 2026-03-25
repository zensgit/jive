enum ImportEditReconciliationStatus {
  ready('ready'),
  review('review'),
  block('block');

  const ImportEditReconciliationStatus(this.value);
  final String value;
}

enum ImportEditReconciliationMode {
  direct('direct'),
  manualReview('manual_review'),
  blocked('blocked');

  const ImportEditReconciliationMode(this.value);
  final String value;
}

class ImportEditReconciliationGovernanceResult {
  final ImportEditReconciliationStatus status;
  final ImportEditReconciliationMode mode;
  final String reason;

  const ImportEditReconciliationGovernanceResult({
    required this.status,
    this.mode = ImportEditReconciliationMode.direct,
    this.reason = '',
  });

  Map<String, dynamic> toJson() => {
        'status': status.value,
        'mode': mode.value,
        'reason': reason,
      };
}
