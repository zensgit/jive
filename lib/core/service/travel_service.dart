import 'package:isar/isar.dart';

import '../database/transaction_model.dart';
import '../database/travel_trip_model.dart';

/// Summary statistics for a single trip.
class TripSummary {
  final double totalExpense;
  final Map<String, double> byCategory;
  final double dailyAverage;
  final int daysCount;

  const TripSummary({
    required this.totalExpense,
    required this.byCategory,
    required this.dailyAverage,
    required this.daysCount,
  });
}

class TravelService {
  final Isar _isar;

  TravelService(this._isar);

  /// Create a new trip in 'planning' status.
  Future<JiveTravelTrip> createTrip({
    required String name,
    required String destination,
    double? budget,
    String baseCurrency = 'CNY',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final trip = JiveTravelTrip()
      ..name = name
      ..destination = destination
      ..budget = budget
      ..baseCurrency = baseCurrency
      ..startDate = startDate
      ..endDate = endDate
      ..status = 'planning'
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.jiveTravelTrips.put(trip);
    });
    return trip;
  }

  /// Activate a trip (set status to 'active').
  Future<void> startTrip(int tripId) async {
    await _isar.writeTxn(() async {
      final trip = await _isar.jiveTravelTrips.get(tripId);
      if (trip == null) return;
      trip
        ..status = 'active'
        ..startDate ??= DateTime.now()
        ..updatedAt = DateTime.now();
      await _isar.jiveTravelTrips.put(trip);
    });
  }

  /// Complete a trip (set status to 'completed').
  Future<void> completeTrip(int tripId) async {
    await _isar.writeTxn(() async {
      final trip = await _isar.jiveTravelTrips.get(tripId);
      if (trip == null) return;
      trip
        ..status = 'completed'
        ..endDate ??= DateTime.now()
        ..updatedAt = DateTime.now();
      await _isar.jiveTravelTrips.put(trip);
    });
  }

  /// Get the currently active trip (if any).
  Future<JiveTravelTrip?> getActiveTrip() async {
    return await _isar.jiveTravelTrips
        .filter()
        .statusEqualTo('active')
        .findFirst();
  }

  /// Get all trips, sorted by createdAt descending.
  Future<List<JiveTravelTrip>> getAllTrips() async {
    return await _isar.jiveTravelTrips
        .where()
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get a single trip by id.
  Future<JiveTravelTrip?> getTrip(int tripId) async {
    return await _isar.jiveTravelTrips.get(tripId);
  }

  /// Update an existing trip.
  Future<void> updateTrip(JiveTravelTrip trip) async {
    trip.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveTravelTrips.put(trip);
    });
  }

  /// Delete a trip.
  Future<void> deleteTrip(int tripId) async {
    await _isar.writeTxn(() async {
      await _isar.jiveTravelTrips.delete(tripId);
    });
  }

  /// Get expenses that fall within a trip's date range.
  Future<List<JiveTransaction>> getTripExpenses(int tripId) async {
    final trip = await _isar.jiveTravelTrips.get(tripId);
    if (trip == null) return [];

    final start = trip.startDate;
    if (start == null) return [];

    final end = trip.endDate ?? DateTime.now();

    return await _isar.jiveTransactions
        .filter()
        .typeEqualTo('expense')
        .timestampBetween(start, end)
        .findAll();
  }

  /// Build a summary of a trip's expenses.
  Future<TripSummary> getTripSummary(int tripId) async {
    final expenses = await getTripExpenses(tripId);
    final trip = await _isar.jiveTravelTrips.get(tripId);

    double total = 0;
    final byCategory = <String, double>{};

    for (final tx in expenses) {
      total += tx.amount;
      final cat = tx.category ?? '未分类';
      byCategory[cat] = (byCategory[cat] ?? 0) + tx.amount;
    }

    final start = trip?.startDate;
    final end = trip?.endDate ?? DateTime.now();
    final days = start != null ? end.difference(start).inDays + 1 : 1;

    return TripSummary(
      totalExpense: total,
      byCategory: byCategory,
      dailyAverage: days > 0 ? total / days : total,
      daysCount: days,
    );
  }
}
