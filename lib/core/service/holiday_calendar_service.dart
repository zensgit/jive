import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lunar/lunar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum JiveHolidayType { rest, work }

class JiveHolidayCalendarService {
  static final JiveHolidayCalendarService instance =
      JiveHolidayCalendarService._();

  static const String _assetPath = 'assets/holidays/cn_public_holidays.json';

  static const String _prefKeyCnEtag = 'holiday_cn_etag';
  static const String _prefKeyCnLastAttemptMs = 'holiday_cn_last_attempt_ms';
  static const String _prefKeyCnLastSuccessMs = 'holiday_cn_last_success_ms';

  static const Duration _refreshTtl = Duration(hours: 24);
  static const String _remoteCnUrl = String.fromEnvironment(
    'JIVE_HOLIDAY_CN_URL',
    defaultValue: '',
  );

  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  bool _initialized = false;
  Map<int, JiveHolidayType> _baseCn = const {};
  Map<int, JiveHolidayType> _overrideCn = const {};

  JiveHolidayCalendarService._();

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _baseCn = await _loadCnFromAsset();
    _overrideCn = await _loadCnOverrideFromDisk();
    _initialized = true;
    revision.value += 1;

    // Best-effort background refresh if a remote source is configured.
    unawaited(refreshCnIfNeeded());
  }

  JiveHolidayType? getCnHolidayType(DateTime day) {
    final key = _ymdKey(day);
    final overrideHit = _overrideCn[key];
    if (overrideHit != null) return overrideHit;
    final baseHit = _baseCn[key];
    if (baseHit != null) return baseHit;

    // Fallback to the lunar package dataset.
    final holiday = HolidayUtil.getHolidayByYmd(day.year, day.month, day.day);
    if (holiday == null) return null;
    return holiday.isWork() ? JiveHolidayType.work : JiveHolidayType.rest;
  }

  Future<void> refreshCnIfNeeded() async {
    if (_remoteCnUrl.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastAttemptMs = prefs.getInt(_prefKeyCnLastAttemptMs);
    if (lastAttemptMs != null) {
      final lastAttempt = DateTime.fromMillisecondsSinceEpoch(lastAttemptMs);
      if (now.difference(lastAttempt) < _refreshTtl) return;
    }
    await prefs.setInt(_prefKeyCnLastAttemptMs, now.millisecondsSinceEpoch);

    final uri = Uri.tryParse(_remoteCnUrl.trim());
    if (uri == null) return;

    final headers = <String, String>{};
    final etag = prefs.getString(_prefKeyCnEtag);
    if (etag != null && etag.isNotEmpty) {
      headers['If-None-Match'] = etag;
    }

    http.Response response;
    try {
      response = await http.get(uri, headers: headers);
    } catch (_) {
      return;
    }

    if (response.statusCode == 304) {
      await prefs.setInt(_prefKeyCnLastSuccessMs, now.millisecondsSinceEpoch);
      return;
    }

    if (response.statusCode != 200) return;

    Map<int, JiveHolidayType> parsed;
    try {
      parsed = parseCnHolidayJson(response.body);
    } catch (_) {
      return;
    }

    // Persist to disk so the data survives restarts and is available offline.
    try {
      final file = await _cnOverrideFile();
      await file.parent.create(recursive: true);
      await file.writeAsString(response.body);
    } catch (_) {
      // Ignore disk errors; we still keep in-memory override.
    }

    final newEtag = response.headers['etag'];
    if (newEtag != null && newEtag.isNotEmpty) {
      await prefs.setString(_prefKeyCnEtag, newEtag);
    }
    await prefs.setInt(_prefKeyCnLastSuccessMs, now.millisecondsSinceEpoch);

    _overrideCn = parsed;
    revision.value += 1;
  }

  static Map<int, JiveHolidayType> parseCnHolidayJson(String content) {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Holiday json must be an object');
    }
    final daysRaw = decoded['days'];
    if (daysRaw is! Map) {
      throw const FormatException('Holiday json missing "days" object');
    }

    final map = <int, JiveHolidayType>{};
    for (final entry in daysRaw.entries) {
      final key = entry.key;
      if (key is! String) continue;
      final parsedKey = _parseYmdKey(key);
      if (parsedKey == null) continue;
      final value = entry.value;
      final type = _parseType(value);
      if (type == null) continue;
      map[parsedKey] = type;
    }
    return map;
  }

  static int _ymdKey(DateTime day) =>
      day.year * 10000 + day.month * 100 + day.day;

  static int? _parseYmdKey(String ymd) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(ymd.trim());
    if (m == null) return null;
    final y = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    final d = int.tryParse(m.group(3)!);
    if (y == null || mo == null || d == null) return null;
    return y * 10000 + mo * 100 + d;
  }

  static JiveHolidayType? _parseType(Object? value) {
    if (value is String) {
      switch (value.toLowerCase().trim()) {
        case 'work':
        case 'workday':
          return JiveHolidayType.work;
        case 'rest':
        case 'holiday':
          return JiveHolidayType.rest;
      }
    }
    if (value is bool) {
      // true -> work, false -> rest
      return value ? JiveHolidayType.work : JiveHolidayType.rest;
    }
    return null;
  }

  Future<Map<int, JiveHolidayType>> _loadCnFromAsset() async {
    try {
      final content = await rootBundle.loadString(_assetPath);
      return parseCnHolidayJson(content);
    } catch (_) {
      return const {};
    }
  }

  Future<Map<int, JiveHolidayType>> _loadCnOverrideFromDisk() async {
    try {
      final file = await _cnOverrideFile();
      if (!await file.exists()) return const {};
      return parseCnHolidayJson(await file.readAsString());
    } catch (_) {
      return const {};
    }
  }

  Future<File> _cnOverrideFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/holidays/cn_public_holidays_override.json');
  }
}
