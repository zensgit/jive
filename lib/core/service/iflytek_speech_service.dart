part of 'speech_service.dart';

class IflytekSpeechService implements SpeechService {
  static const _host = 'iat-api.xfyun.cn';
  static const _path = '/v2/iat';
  static const _frameSize = 1280;
  static const _frameInterval = Duration(milliseconds: 40);
  static const _appId = String.fromEnvironment('IFLYTEK_APP_ID');
  static const _apiKey = String.fromEnvironment('IFLYTEK_API_KEY');
  static const _apiSecret = String.fromEnvironment('IFLYTEK_API_SECRET');

  static bool get hasCredentials =>
      _appId.isNotEmpty && _apiKey.isNotEmpty && _apiSecret.isNotEmpty;

  static List<String> get missingCredentialKeys {
    final keys = <String>[];
    if (_appId.isEmpty) keys.add('IFLYTEK_APP_ID');
    if (_apiKey.isEmpty) keys.add('IFLYTEK_API_KEY');
    if (_apiSecret.isEmpty) keys.add('IFLYTEK_API_SECRET');
    return keys;
  }

  final AudioRecorder _recorder = AudioRecorder();
  String? _recordPath;
  bool _recording = false;

  @override
  Future<SpeechRecognitionResult> recognizeOnce({
    String? locale,
    bool preferOffline = false,
    SpeechEngine engine = SpeechEngine.iflytek,
  }) async {
    final startResult = await startListening(
      locale: locale,
      preferOffline: preferOffline,
      engine: engine,
    );
    if (startResult.errorCode != null) return startResult;
    await Future<void>.delayed(const Duration(seconds: 4));
    return stopListening();
  }

  @override
  Future<SpeechRecognitionResult> startListening({
    String? locale,
    bool preferOffline = false,
    SpeechEngine engine = SpeechEngine.iflytek,
  }) async {
    if (engine != SpeechEngine.iflytek) {
      return const SpeechRecognitionResult(errorCode: 'UNSUPPORTED');
    }
    if (!hasCredentials) {
      return const SpeechRecognitionResult(errorCode: 'NO_CREDENTIALS');
    }
    if (_recording) {
      return const SpeechRecognitionResult(errorCode: 'BUSY');
    }
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      return const SpeechRecognitionResult(errorCode: 'NO_PERMISSION');
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/iflytek_${DateTime.now().millisecondsSinceEpoch}.pcm';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _recording = true;
    _recordPath = path;
    return const SpeechRecognitionResult();
  }

  @override
  Future<SpeechRecognitionResult> stopListening() async {
    if (!_recording) {
      return const SpeechRecognitionResult(errorCode: 'NO_SESSION');
    }
    final path = await _recorder.stop();
    _recording = false;
    final filePath = path ?? _recordPath;
    _recordPath = null;
    if (filePath == null || filePath.isEmpty) {
      return const SpeechRecognitionResult(errorCode: 'AUDIO');
    }
    final file = File(filePath);
    if (!await file.exists()) {
      return const SpeechRecognitionResult(errorCode: 'AUDIO');
    }
    final audioBytes = await file.readAsBytes();
    if (audioBytes.isEmpty) {
      return const SpeechRecognitionResult(errorCode: 'NO_MATCH');
    }
    return _transcribe(audioBytes);
  }

  @override
  Future<bool> cancel() async {
    if (_recording) {
      await _recorder.stop();
      _recording = false;
      _recordPath = null;
    }
    return true;
  }

  Future<SpeechRecognitionResult> _transcribe(Uint8List audioBytes) async {
    WebSocketChannel? channel;
    try {
      final authUri = _buildAuthUri();
      channel = WebSocketChannel.connect(authUri);
      final segments = SplayTreeMap<int, String>();
      final done = Completer<SpeechRecognitionResult>();

      channel.stream.listen(
        (message) {
          final parsed = _handleMessage(message, segments);
          if (parsed != null && !done.isCompleted) {
            done.complete(parsed);
          }
        },
        onError: (error) {
          if (!done.isCompleted) {
            done.complete(
              SpeechRecognitionResult(
                errorCode: 'IFLYTEK_ERROR',
                errorMessage: error.toString(),
              ),
            );
          }
        },
        onDone: () {
          if (!done.isCompleted) {
            final text = segments.values.join();
            done.complete(
              SpeechRecognitionResult(
                text: text.isEmpty ? null : text,
                errorCode: text.isEmpty ? 'NO_MATCH' : null,
              ),
            );
          }
        },
      );

      await _sendFrames(channel.sink, audioBytes);
      return await done.future.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      return const SpeechRecognitionResult(errorCode: 'TIMEOUT');
    } catch (e) {
      return SpeechRecognitionResult(
        errorCode: 'IFLYTEK_ERROR',
        errorMessage: e.toString(),
      );
    } finally {
      await channel?.sink.close();
    }
  }

  Future<void> _sendFrames(WebSocketSink sink, Uint8List audioBytes) async {
    final totalFrames = (audioBytes.length / _frameSize).ceil();
    for (var i = 0; i < totalFrames; i++) {
      final start = i * _frameSize;
      final end = (start + _frameSize).clamp(0, audioBytes.length);
      final chunk = audioBytes.sublist(start, end);
      final status = i == 0 ? 0 : 1;
      final payload = _buildFramePayload(
        status: status,
        audio: base64.encode(chunk),
        includeParams: i == 0,
      );
      sink.add(payload);
      await Future<void>.delayed(_frameInterval);
    }
    sink.add(_buildFramePayload(status: 2, audio: '', includeParams: false));
  }

  SpeechRecognitionResult? _handleMessage(
    dynamic message,
    SplayTreeMap<int, String> segments,
  ) {
    if (message is! String) {
      return null;
    }
    final data = json.decode(message) as Map<String, dynamic>;
    final code = data['code'] as int?;
    if (code != null && code != 0) {
      return SpeechRecognitionResult(
        errorCode: 'IFLYTEK_ERROR_$code',
        errorMessage: data['message']?.toString(),
      );
    }

    final payload = data['data'] as Map<String, dynamic>?;
    final result = payload?['result'] as Map<String, dynamic>?;
    if (result != null) {
      _applyResult(result, segments);
    }

    final status = payload?['status'] as int?;
    if (status == 2) {
      final text = segments.values.join();
      return SpeechRecognitionResult(
        text: text.isEmpty ? null : text,
        errorCode: text.isEmpty ? 'NO_MATCH' : null,
      );
    }
    return null;
  }

  void _applyResult(Map<String, dynamic> parsed, SplayTreeMap<int, String> segments) {
    final ws = parsed['ws'] as List<dynamic>? ?? const [];
    final textBuffer = StringBuffer();
    for (final wsItem in ws) {
      final cwList = (wsItem as Map<String, dynamic>)['cw'] as List<dynamic>? ?? const [];
      if (cwList.isNotEmpty) {
        final first = cwList.first as Map<String, dynamic>;
        final word = first['w']?.toString();
        if (word != null) {
          textBuffer.write(word);
        }
      }
    }
    final segment = textBuffer.toString();
    if (segment.isEmpty) return;
    final snValue = _parseInt(parsed['sn']);
    final key = snValue ?? _nextSegmentKey(segments);
    final pgs = parsed['pgs']?.toString();
    final rg = parsed['rg'] as List<dynamic>?;
    if (pgs == 'rpl' && rg != null && rg.length >= 2) {
      final start = _parseInt(rg[0]);
      final end = _parseInt(rg[1]);
      if (start != null && end != null) {
        for (var index = start; index <= end; index++) {
          segments.remove(index);
        }
      }
    }
    segments[key] = segment;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  int _nextSegmentKey(SplayTreeMap<int, String> segments) {
    if (segments.isEmpty) return 0;
    return (segments.lastKey() ?? -1) + 1;
  }

  Uri _buildAuthUri() {
    final date = HttpDate.format(DateTime.now().toUtc());
    final signatureOrigin = 'host: $_host\ndate: $date\nGET $_path HTTP/1.1';
    final hmacSha = Hmac(sha256, utf8.encode(_apiSecret)).convert(utf8.encode(signatureOrigin));
    final signature = base64.encode(hmacSha.bytes);
    final authorizationOrigin =
        'api_key="$_apiKey", algorithm="hmac-sha256", headers="host date request-line", signature="$signature"';
    final authorization = base64.encode(utf8.encode(authorizationOrigin));

    return Uri(
      scheme: 'wss',
      host: _host,
      path: _path,
      queryParameters: {
        'authorization': authorization,
        'date': date,
        'host': _host,
      },
    );
  }

  String _buildFramePayload({
    required int status,
    required String audio,
    required bool includeParams,
  }) {
    final payload = <String, dynamic>{
      'common': {
        'app_id': _appId,
      },
      if (includeParams)
        'business': {
          'domain': 'iat',
          'language': 'zh_cn',
          'accent': 'mandarin',
          'vad_eos': 6000,
          'dwa': 'wpgs',
        },
      'data': {
        'status': status,
        'format': 'audio/L16;rate=16000',
        'encoding': 'raw',
        'audio': audio,
      },
    };
    return json.encode(payload);
  }
}
