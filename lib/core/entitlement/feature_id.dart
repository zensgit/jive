/// Enumeration of gated features.
///
/// Each feature has a required [UserTier] defined in [FeatureRegistry].
/// Adding a new gated feature = add an entry here + register its tier.
enum FeatureId {
  // --- Always available (free) ---
  manualTransaction,
  categoryManagement,
  basicStats,
  tagManagement,

  // --- Paid tier ---
  autoBookkeeping,
  multiCurrency,
  csvExport,
  budgetUnlimited,
  recurringRules,
  projectTracking,
  billSplit,
  debtManagement,
  merchantMemory,

  // --- Subscriber tier ---
  cloudSync,
  multiDevice,
  investmentTracking,
  advancedAnalytics,
  savingsGoals,
  pdfReport,
  voiceBookkeeping,
}
