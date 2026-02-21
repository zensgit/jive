# Currency Spending Uses Account Currency (2026-02-21)

## Implementation

### 1) New analytics service
- Added `lib/core/service/currency_spending_analytics_service.dart`.
- Exposed pure entry: `CurrencySpendingAnalyticsService.buildSpendingData(...)`.
- Inputs:
  - `transactions`
  - `accountById`
  - `baseCurrency`
  - `selectedMonths`
  - `now`
  - optional `converter` callback (`CurrencyAmountConverter`) for conversion boundary
- Output:
  - `CurrencySpendingAnalyticsResult` containing:
    - per-currency grouped totals (`CurrencySpendingData`)
    - monthly series (`MonthlySpending`) with missing months filled by zero
    - accumulated converted total (`totalConvertedSpending`)

### 2) Currency source rule
- Implemented in `_resolveCurrency(...)`:
  - `expense` / `income`: resolve from `transaction.accountId -> accountById[accountId].currency`
  - if account is missing or currency empty: fallback to `baseCurrency`
  - non `expense`/`income` fallback to `baseCurrency`

### 3) Screen integration
- Updated `lib/feature/currency/foreign_currency_spending_screen.dart` to use `CurrencySpendingAnalyticsService`.
- Removed hardcoded `'CNY'` currency assignment path.
- Loaded accounts once and passed `accountById` into analytics service.
- Kept UI structure/behavior unchanged (same widgets, same sorting/display behavior).

### 4) Unit tests
- Added `test/currency_spending_analytics_service_test.dart` covering:
  1. multi-account multi-currency aggregation
  2. fallback to base currency when account missing/invalid currency
  3. monthly gap fill with zero values
  4. converted total accumulation path correctness (grouped conversion calls and final total)

## Verification

### Commands run
```bash
dart format lib/core/service/currency_spending_analytics_service.dart lib/feature/currency/foreign_currency_spending_screen.dart test/currency_spending_analytics_service_test.dart
flutter analyze --no-fatal-infos
flutter test test/currency_spending_analytics_service_test.dart
```

### Results
- `dart format`: formatted all touched Dart files successfully.
- `flutter analyze --no-fatal-infos`: `No issues found! (ran in 6.8s)`.
- `flutter test test/currency_spending_analytics_service_test.dart`: `All tests passed!` (4 tests).
