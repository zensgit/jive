import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/pdf_report_service.dart';

void main() {
  group('PdfReportService', () {
    test('class exists and can be referenced', () {
      // Verify the PdfReportService class is importable and exists.
      expect(PdfReportService, isNotNull);
    });

    test('generateAnnualReport static method has correct return type', () {
      // Verify the static method signature returns Future<Uint8List>.
      // We cannot call it without Isar, but we can confirm the type.
      final Future<Uint8List> Function(int) generator =
          PdfReportService.generateAnnualReport;

      expect(generator, same(PdfReportService.generateAnnualReport));
    });
  });
}
