import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/pdf_report_service.dart';

void main() {
  group('PdfReportService', () {
    test('generateAnnualReport is a callable static', () {
      expect(PdfReportService.generateAnnualReport, isA<Function>());
    });
  });
}
