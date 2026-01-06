import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class JiveLogger {
  static late Logger _logger;
  static File? _logFile;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${dir.path}/logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    // 按天生成文件名
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _logFile = File('${logDir.path}/jive_$dateStr.log');

    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: false, // 文件日志不带颜色
        printEmojis: false,
        printTime: true,
      ),
      output: FileOutput(file: _logFile!),
    );
    
    // 清理旧日志 (保留7天)
    _cleanOldLogs(logDir);
  }

  static void i(String message) {
    _logger.i(message);
  }

  static void d(String message) {
    _logger.d(message);
  }
  
  static void w(String message) {
    _logger.w(message);
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // 导出日志
  static Future<void> exportLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await Share.shareXFiles([XFile(_logFile!.path)], text: 'Jive App Logs');
    } else {
      print("No log file to export.");
    }
  }

  static void _cleanOldLogs(Directory dir) {
    dir.listSync().forEach((FileSystemEntity file) {
      if (file is File) {
        final stat = file.statSync();
        final now = DateTime.now();
        if (now.difference(stat.modified).inDays > 7) {
          file.delete();
        }
      }
    });
  }
}

// 自定义文件输出
class FileOutput extends LogOutput {
  final File file;

  FileOutput({required this.file});

  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      // 同时打印到控制台和文件
      // ignore: avoid_print
      print(line); 
      file.writeAsStringSync("$line\n", mode: FileMode.append);
    }
  }
}