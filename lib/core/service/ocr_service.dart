import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  Future<String> recognizeTextFromImagePath(String imagePath) async {
    if (kIsWeb) {
      throw UnsupportedError('Web 暂不支持 OCR');
    }
    final file = File(imagePath);
    if (!await file.exists()) {
      throw ArgumentError('图片不存在: $imagePath');
    }

    final image = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.chinese);
    try {
      final recognized = await recognizer.processImage(image);
      return recognized.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}
