import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'iflytek_speech_service.dart';

enum SpeechEngine {
  system,
  baidu,
  iflytek,
}

extension SpeechEngineValue on SpeechEngine {
  String get value {
    switch (this) {
      case SpeechEngine.system:
        return 'system';
      case SpeechEngine.baidu:
        return 'baidu';
      case SpeechEngine.iflytek:
        return 'iflytek';
    }
  }
}

class SpeechRecognitionResult {
  final String? text;
  final String? errorCode;
  final String? errorMessage;

  const SpeechRecognitionResult({
    this.text,
    this.errorCode,
    this.errorMessage,
  });

  bool get hasText => text != null && text!.trim().isNotEmpty;

  SpeechRecognitionResult copyWith({
    String? text,
    String? errorCode,
    String? errorMessage,
  }) {
    return SpeechRecognitionResult(
      text: text ?? this.text,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static SpeechRecognitionResult fromChannel(dynamic result) {
    if (result is String) {
      final normalized = result.trim();
      return SpeechRecognitionResult(
        text: normalized.isEmpty ? null : normalized,
      );
    }
    if (result is Map) {
      String? text;
      final rawText = result['text'];
      if (rawText is String) {
        final normalized = rawText.trim();
        if (normalized.isNotEmpty) {
          text = normalized;
        }
      } else if (rawText != null) {
        final normalized = rawText.toString().trim();
        if (normalized.isNotEmpty) {
          text = normalized;
        }
      }

      final errorCode = result['error']?.toString();
      final errorMessage = result['message']?.toString();

      return SpeechRecognitionResult(
        text: text,
        errorCode: errorCode,
        errorMessage: errorMessage,
      );
    }
    return const SpeechRecognitionResult();
  }
}

abstract class SpeechService {
  Future<SpeechRecognitionResult> recognizeOnce({
    String? locale,
    bool preferOffline = false,
    SpeechEngine engine = SpeechEngine.system,
  });

  Future<SpeechRecognitionResult> startListening({
    String? locale,
    bool preferOffline = false,
    SpeechEngine engine = SpeechEngine.system,
  });

  Future<SpeechRecognitionResult> stopListening();

  Future<bool> cancel();
}

class SpeechServiceStub implements SpeechService {
  @override
  Future<SpeechRecognitionResult> recognizeOnce({
    String? locale,
    bool preferOffline = false,
    SpeechEngine engine = SpeechEngine.system,
  }) async {
    return const SpeechRecognitionResult(errorCode: 'UNAVAILABLE');
  }

  @override
  Future<SpeechRecognitionResult> startListening({
    String? locale,
    bool preferOffline = false,
    SpeechEngine engine = SpeechEngine.system,
  }) async {
    return const SpeechRecognitionResult(errorCode: 'UNAVAILABLE');
  }

  @override
  Future<SpeechRecognitionResult> stopListening() async {
    return const SpeechRecognitionResult(errorCode: 'UNAVAILABLE');
  }

  @override
  Future<bool> cancel() async {
    return false;
  }
}

class MethodChannelSpeechService implements SpeechService {
  static const MethodChannel _channel = MethodChannel('com.jive.app/speech');

  @override
  Future<SpeechRecognitionResult> recognizeOnce({
    String? locale,
    bool preferOffline = false,
    SpeechEngine engine = SpeechEngine.system,
  }) async {
    try {
      final result = await _channel.invokeMethod<dynamic>(
        'recognizeOnce',
        {
          if (locale != null && locale.isNotEmpty) 'locale': locale,
          'preferOffline': preferOffline,
          'engine': engine.value,
        },
      );
      return SpeechRecognitionResult.fromChannel(result);
    } on MissingPluginException {
      return const SpeechRecognitionResult(errorCode: 'UNAVAILABLE');
    } on PlatformException catch (error) {
      return SpeechRecognitionResult(
        errorCode: error.code,
        errorMessage: error.message,
      );
    }
  }

  @override
  Future<SpeechRecognitionResult> startListening({
    String? locale,
    bool preferOffline = false,
    SpeechEngine engine = SpeechEngine.system,
  }) async {
    try {
      final result = await _channel.invokeMethod<dynamic>(
        'startListening',
        {
          if (locale != null && locale.isNotEmpty) 'locale': locale,
          'preferOffline': preferOffline,
          'engine': engine.value,
        },
      );
      return SpeechRecognitionResult.fromChannel(result);
    } on MissingPluginException {
      return const SpeechRecognitionResult(errorCode: 'UNAVAILABLE');
    } on PlatformException catch (error) {
      return SpeechRecognitionResult(
        errorCode: error.code,
        errorMessage: error.message,
      );
    }
  }

  @override
  Future<SpeechRecognitionResult> stopListening() async {
    try {
      final result = await _channel.invokeMethod<dynamic>('stopListening');
      return SpeechRecognitionResult.fromChannel(result);
    } on MissingPluginException {
      return const SpeechRecognitionResult(errorCode: 'UNAVAILABLE');
    } on PlatformException catch (error) {
      return SpeechRecognitionResult(
        errorCode: error.code,
        errorMessage: error.message,
      );
    }
  }

  @override
  Future<bool> cancel() async {
    try {
      final result = await _channel.invokeMethod<bool>('cancel');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

class SpeechServiceFactory {
  static SpeechService create({bool usePlatform = true}) {
    if (!usePlatform) return SpeechServiceStub();
    return CompositeSpeechService(
      platform: MethodChannelSpeechService(),
      iflytek: IflytekSpeechService(),
    );
  }
}

class CompositeSpeechService implements SpeechService {
  CompositeSpeechService({
    required SpeechService platform,
    required IflytekSpeechService iflytek,
  })  : _platform = platform,
        _iflytek = iflytek;

  final SpeechService _platform;
  final IflytekSpeechService _iflytek;
  SpeechEngine? _activeEngine;

  @override
  Future<SpeechRecognitionResult> recognizeOnce({
    String? locale,
    bool preferOffline = false,
    SpeechEngine engine = SpeechEngine.system,
  }) {
    if (engine == SpeechEngine.iflytek) {
      return _iflytek.recognizeOnce(
        locale: locale,
        preferOffline: preferOffline,
        engine: engine,
      );
    }
    return _platform.recognizeOnce(
      locale: locale,
      preferOffline: preferOffline,
      engine: engine,
    );
  }

  @override
  Future<SpeechRecognitionResult> startListening({
    String? locale,
    bool preferOffline = false,
    SpeechEngine engine = SpeechEngine.system,
  }) async {
    _activeEngine = engine;
    if (engine == SpeechEngine.iflytek) {
      return _iflytek.startListening(
        locale: locale,
        preferOffline: preferOffline,
        engine: engine,
      );
    }
    return _platform.startListening(
      locale: locale,
      preferOffline: preferOffline,
      engine: engine,
    );
  }

  @override
  Future<SpeechRecognitionResult> stopListening() {
    final engine = _activeEngine;
    _activeEngine = null;
    if (engine == SpeechEngine.iflytek) {
      return _iflytek.stopListening();
    }
    return _platform.stopListening();
  }

  @override
  Future<bool> cancel() {
    final engine = _activeEngine;
    _activeEngine = null;
    if (engine == SpeechEngine.iflytek) {
      return _iflytek.cancel();
    }
    return _platform.cancel();
  }
}
