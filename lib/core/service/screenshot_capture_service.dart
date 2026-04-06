import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screenshot_ocr_service.dart';

/// Service that monitors the device screenshot directories, detects new
/// screenshots, and automatically parses payment information via OCR.
class ScreenshotCaptureService {
  static const _enabledKey = 'screenshot_capture_enabled';
  static const _lastCheckKey = 'screenshot_capture_last_check';
  static const _recentPathsKey = 'screenshot_capture_recent_paths';
  static const _maxRecentPaths = 20;

  final ScreenshotOcrService _ocrService;

  ScreenshotCaptureService({ScreenshotOcrService? ocrService})
      : _ocrService = ocrService ?? ScreenshotOcrService();

  // -- Enabled toggle --

  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  // -- Last-check timestamp --

  Future<DateTime> get lastCheckTimestamp async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastCheckKey);
    if (ms == null) return DateTime.now();
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> _updateLastCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  // -- Screenshot directory candidates --

  List<String> _screenshotDirectories() {
    if (!Platform.isAndroid) return [];
    // Common Android screenshot paths
    final base = '/storage/emulated/0';
    return [
      '$base/DCIM/Screenshots',
      '$base/Pictures/Screenshots',
      '$base/Screenshots',
    ];
  }

  /// Scan for new screenshot files created after the last check timestamp.
  Future<List<String>> checkForNewScreenshots() async {
    final since = await lastCheckTimestamp;
    final results = <String>[];

    for (final dirPath in _screenshotDirectories()) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;

      try {
        await for (final entity in dir.list()) {
          if (entity is! File) continue;
          final name = entity.path.toLowerCase();
          if (!name.endsWith('.png') && !name.endsWith('.jpg') && !name.endsWith('.jpeg')) {
            continue;
          }
          final stat = await entity.stat();
          if (stat.modified.isAfter(since)) {
            results.add(entity.path);
          }
        }
      } catch (e) {
        debugPrint('Error scanning $dirPath: $e');
      }
    }

    await _updateLastCheck();
    return results;
  }

  /// Parse a single screenshot and return the OCR result (if any).
  Future<ScreenshotParseResult?> processScreenshot(String path) async {
    try {
      final result = await _ocrService.parsePaymentScreenshot(path);
      if (result != null) {
        await _addRecentPath(path);
      }
      return result;
    } catch (e) {
      debugPrint('Failed to process screenshot $path: $e');
      return null;
    }
  }

  // -- Recent captures persistence --

  Future<List<String>> getRecentPaths({int count = 5}) async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getStringList(_recentPathsKey) ?? [];
    return all.take(count).toList();
  }

  Future<void> _addRecentPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getStringList(_recentPathsKey) ?? [];
    all.remove(path);
    all.insert(0, path);
    if (all.length > _maxRecentPaths) {
      all.removeRange(_maxRecentPaths, all.length);
    }
    await prefs.setStringList(_recentPathsKey, all);
  }
}
