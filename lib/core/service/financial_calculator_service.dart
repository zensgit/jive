import 'dart:math';

/// Result of a fixed-deposit calculation.
class DepositResult {
  final double maturityAmount;
  final double totalInterest;
  final List<MonthlyDepositBreakdown> monthlyBreakdown;

  const DepositResult({
    required this.maturityAmount,
    required this.totalInterest,
    required this.monthlyBreakdown,
  });
}

/// One month in the deposit breakdown.
class MonthlyDepositBreakdown {
  final int month;
  final double interestEarned;
  final double accumulatedInterest;
  final double balance;

  const MonthlyDepositBreakdown({
    required this.month,
    required this.interestEarned,
    required this.accumulatedInterest,
    required this.balance,
  });
}

/// A single loan payment row.
class LoanPayment {
  final int month;
  final double principal;
  final double interest;
  final double payment;
  final double remainingBalance;

  const LoanPayment({
    required this.month,
    required this.principal,
    required this.interest,
    required this.payment,
    required this.remainingBalance,
  });
}

/// Result of a loan calculation.
class LoanResult {
  final List<LoanPayment> monthlyPayments;
  final double totalInterest;
  final double totalPayment;

  const LoanResult({
    required this.monthlyPayments,
    required this.totalInterest,
    required this.totalPayment,
  });
}

/// Pure-calculation service — no database, no state.
class FinancialCalculatorService {
  /// Fixed deposit with simple monthly compounding.
  DepositResult calculateFixedDeposit({
    required double principal,
    required double annualRate,
    required int months,
  }) {
    final monthlyRate = annualRate / 100 / 12;
    double balance = principal;
    double accumulatedInterest = 0;
    final breakdown = <MonthlyDepositBreakdown>[];

    for (int m = 1; m <= months; m++) {
      final interest = balance * monthlyRate;
      accumulatedInterest += interest;
      balance += interest;
      breakdown.add(MonthlyDepositBreakdown(
        month: m,
        interestEarned: _r(interest),
        accumulatedInterest: _r(accumulatedInterest),
        balance: _r(balance),
      ));
    }

    return DepositResult(
      maturityAmount: _r(balance),
      totalInterest: _r(accumulatedInterest),
      monthlyBreakdown: breakdown,
    );
  }

  /// Equal-principal repayment (等额本金).
  LoanResult calculateLoanEqualPrincipal({
    required double principal,
    required double annualRate,
    required int months,
  }) {
    final monthlyRate = annualRate / 100 / 12;
    final monthlyPrincipal = principal / months;
    double remaining = principal;
    double totalInterest = 0;
    double totalPayment = 0;
    final payments = <LoanPayment>[];

    for (int m = 1; m <= months; m++) {
      final interest = remaining * monthlyRate;
      final payment = monthlyPrincipal + interest;
      remaining -= monthlyPrincipal;
      if (remaining < 0) remaining = 0;
      totalInterest += interest;
      totalPayment += payment;
      payments.add(LoanPayment(
        month: m,
        principal: _r(monthlyPrincipal),
        interest: _r(interest),
        payment: _r(payment),
        remainingBalance: _r(remaining),
      ));
    }

    return LoanResult(
      monthlyPayments: payments,
      totalInterest: _r(totalInterest),
      totalPayment: _r(totalPayment),
    );
  }

  /// Equal-installment repayment (等额本息).
  LoanResult calculateLoanEqualInstallment({
    required double principal,
    required double annualRate,
    required int months,
  }) {
    final monthlyRate = annualRate / 100 / 12;
    final double fixedPayment;

    if (monthlyRate == 0) {
      fixedPayment = principal / months;
    } else {
      fixedPayment = principal *
          monthlyRate *
          pow(1 + monthlyRate, months) /
          (pow(1 + monthlyRate, months) - 1);
    }

    double remaining = principal;
    double totalInterest = 0;
    final payments = <LoanPayment>[];

    for (int m = 1; m <= months; m++) {
      final interest = remaining * monthlyRate;
      final princ = fixedPayment - interest;
      remaining -= princ;
      if (remaining < 0) remaining = 0;
      totalInterest += interest;
      payments.add(LoanPayment(
        month: m,
        principal: _r(princ),
        interest: _r(interest),
        payment: _r(fixedPayment),
        remainingBalance: _r(remaining),
      ));
    }

    return LoanResult(
      monthlyPayments: payments,
      totalInterest: _r(totalInterest),
      totalPayment: _r(fixedPayment * months),
    );
  }

  /// Calculate interest saved by making an early repayment.
  double calculateEarlyRepayment({
    required double remainingPrincipal,
    required double annualRate,
    required int remainingMonths,
    required double earlyAmount,
  }) {
    // Interest without early repayment (equal-installment).
    final before = calculateLoanEqualInstallment(
      principal: remainingPrincipal,
      annualRate: annualRate,
      months: remainingMonths,
    );

    final newPrincipal = remainingPrincipal - earlyAmount;
    if (newPrincipal <= 0) return _r(before.totalInterest);

    final after = calculateLoanEqualInstallment(
      principal: newPrincipal,
      annualRate: annualRate,
      months: remainingMonths,
    );

    return _r(before.totalInterest - after.totalInterest);
  }

  /// Round to 2 decimal places.
  static double _r(double v) => (v * 100).roundToDouble() / 100;
}
