import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Metadata for a stored-value / gift-voucher card linked to an account.
class StoredValueInfo {
  final int accountId;
  final double originalBalance;
  final double currentBalance;
  final DateTime? expiryDate;
  final String? cardNumber;

  const StoredValueInfo({
    required this.accountId,
    required this.originalBalance,
    required this.currentBalance,
    this.expiryDate,
    this.cardNumber,
  });

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'originalBalance': originalBalance,
        'currentBalance': currentBalance,
        'expiryDate': expiryDate?.toIso8601String(),
        'cardNumber': cardNumber,
      };

  factory StoredValueInfo.fromJson(Map<String, dynamic> json) {
    return StoredValueInfo(
      accountId: json['accountId'] as int,
      originalBalance: (json['originalBalance'] as num).toDouble(),
      currentBalance: (json['currentBalance'] as num).toDouble(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null,
      cardNumber: json['cardNumber'] as String?,
    );
  }

  StoredValueInfo copyWith({
    double? currentBalance,
    DateTime? expiryDate,
    String? cardNumber,
  }) {
    return StoredValueInfo(
      accountId: accountId,
      originalBalance: originalBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      expiryDate: expiryDate ?? this.expiryDate,
      cardNumber: cardNumber ?? this.cardNumber,
    );
  }
}

/// Manages stored-value / gift-voucher card metadata via SharedPreferences.
class StoredValueService {
  static const _prefixKey = 'stored_value_';

  /// Create (or overwrite) a stored-value card linked to [accountId].
  Future<StoredValueInfo> createStoredValue(
    int accountId,
    double originalBalance, {
    DateTime? expiryDate,
    String? cardNumber,
  }) async {
    final info = StoredValueInfo(
      accountId: accountId,
      originalBalance: originalBalance,
      currentBalance: originalBalance,
      expiryDate: expiryDate,
      cardNumber: cardNumber,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefixKey$accountId', jsonEncode(info.toJson()));
    return info;
  }

  /// Return all stored-value cards sorted by expiry (earliest first).
  Future<List<StoredValueInfo>> getStoredValues() async {
    final prefs = await SharedPreferences.getInstance();
    final results = <StoredValueInfo>[];

    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefixKey)) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        results.add(StoredValueInfo.fromJson(json));
      } catch (_) {
        // skip corrupted entries
      }
    }

    results.sort((a, b) {
      if (a.expiryDate == null && b.expiryDate == null) return 0;
      if (a.expiryDate == null) return 1;
      if (b.expiryDate == null) return -1;
      return a.expiryDate!.compareTo(b.expiryDate!);
    });

    return results;
  }

  /// Return cards expiring within [daysAhead] days.
  Future<List<StoredValueInfo>> getExpiringCards(int daysAhead) async {
    final all = await getStoredValues();
    final deadline = DateTime.now().add(Duration(days: daysAhead));
    return all
        .where((c) => c.expiryDate != null && c.expiryDate!.isBefore(deadline))
        .toList();
  }

  /// Update the current balance for a stored-value card.
  Future<void> updateBalance(int accountId, double newBalance) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefixKey$accountId');
    if (raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final info = StoredValueInfo.fromJson(json).copyWith(currentBalance: newBalance);
    await prefs.setString('$_prefixKey$accountId', jsonEncode(info.toJson()));
  }

  /// Delete a stored-value card entry.
  Future<void> deleteStoredValue(int accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefixKey$accountId');
  }
}
