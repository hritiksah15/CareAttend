import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'download_stub.dart' if (dart.library.html) 'download_web.dart';

/// Export helpers — PDF (share/print, cross-platform), CSV and JSON (web download).
class Exporter {
  static const _blue = PdfColor.fromInt(0xFF003087);
  static const batchCsvColumns = [
    'Age',
    'Gender',
    'AppointmentLeadTimeDays',
    'SMSReceived',
    'PriorDNACount',
    'IMDDecile',
  ];
  static const _batchCsvTemplateRows = [
    [78, 0, 21, 0, 4, 2],
    [45, 1, 7, 1, 0, 8],
    [66, 0, 35, 0, 2, 4],
  ];

  // ── Patient risk report ──

  static Future<void> patientPdf(Map<String, dynamic> r) async {
    final shap = (r['shap_values'] as List?) ?? [];
    final doc = pw.Document();
    doc.addPage(pw.Page(build: (ctx) {
      return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Care Attend — Patient Risk Report',
                style: const pw.TextStyle(
                    fontSize: 18,
                    color: _blue,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Generated: ${DateTime.now()}'),
            pw.SizedBox(height: 12),
            _kv('Risk Score', '${r['percentage']}%'),
            _kv('Risk Tier', '${r['risk_tier']}'),
            _kv('Age Group', '${r['age_group']}'),
            _kv('Model', '${r['model_used'] ?? 'Logistic Regression'}'),
            pw.SizedBox(height: 12),
            pw.Text('SHAP Risk Factors',
                style: const pw.TextStyle(
                    fontSize: 14,
                    color: _blue,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const ['Factor', 'Impact', 'Direction'],
              data: [
                for (final s in shap)
                  [
                    '${s['label']}',
                    (s['value'] as num).toStringAsFixed(4),
                    '${s['direction']}'
                  ]
              ],
            ),
            if (r['nl_summary'] != null) ...[
              pw.SizedBox(height: 12),
              pw.Text('Summary',
                  style: const pw.TextStyle(
                      fontSize: 14,
                      color: _blue,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('${r['nl_summary']}'),
            ],
            pw.SizedBox(height: 16),
            pw.Text(
                'Care Attend | COM668 | Ulster University | GDPR Art 5(1)(c) | No patient data stored',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ]);
    }));
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static void patientCsv(Map<String, dynamic> r) {
    final patient = (r['patient_summary'] as Map?) ?? const {};
    final row = <String, dynamic>{
      'Age': patient['Age'],
      'Gender': patient['Gender'],
      'AppointmentLeadTimeDays': patient['AppointmentLeadTimeDays'],
      'SMSReceived': patient['SMSReceived'],
      'PriorDNACount': patient['PriorDNACount'],
      'IMDDecile': patient['IMDDecile'],
    };
    final csv = [
      batchCsvColumns.map(_csvCell).join(','),
      batchCsvColumns.map((c) => _csvCell(row[c])).join(','),
    ].join('\n');
    downloadText('CareAttend_Patient_Assessment.csv', csv, 'text/csv');
  }

  static void batchTemplateCsv() {
    final csv = [
      batchCsvColumns.map(_csvCell).join(','),
      for (final row in _batchCsvTemplateRows) row.map(_csvCell).join(','),
    ].join('\n');
    downloadText('sample_batch_upload.csv', csv, 'text/csv');
  }

  static void json(Map<String, dynamic> data, String filename) {
    downloadText(filename, const JsonEncoder.withIndent('  ').convert(data),
        'application/json');
  }

  // ── Bias audit report ──

  static Future<void> biasPdf(Map<String, dynamic> d, String summary) async {
    final doc = pw.Document();
    final groups = {
      'Age Group': d['age_group'],
      'Gender': d['gender'],
      'IMD Band': d['imd_band'],
    };
    final om = d['overall_metrics'] as Map? ?? {};
    doc.addPage(pw.MultiPage(build: (ctx) {
      return [
        pw.Text('Care Attend — Ethical Bias Audit',
            style: const pw.TextStyle(
                fontSize: 18, color: _blue, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Generated: ${DateTime.now()}'),
        pw.SizedBox(height: 12),
        pw.Text('Overall',
            style: const pw.TextStyle(fontSize: 14, color: _blue)),
        _kv('F1-Score', '${om['f1_score']}'),
        _kv('Recall', '${om['recall']}'),
        _kv('Precision', '${om['precision']}'),
        pw.SizedBox(height: 12),
        for (final e in groups.entries)
          if (e.value is Map) ...[
            pw.Text('${e.key} fairness',
                style: const pw.TextStyle(fontSize: 14, color: _blue)),
            _kv('Demographic parity',
                '${e.value['demographic_parity_diff']} [${e.value['dp_status']}]'),
            _kv('Equalised odds',
                '${e.value['equalised_odds_diff']} [${e.value['eo_status']}]'),
            pw.SizedBox(height: 8),
          ],
        pw.SizedBox(height: 8),
        pw.Text('Summary',
            style: const pw.TextStyle(fontSize: 14, color: _blue)),
        pw.Text(summary),
      ];
    }));
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static pw.Widget _kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [
          pw.SizedBox(width: 150, child: pw.Text(k)),
          pw.Text(v, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ]),
      );

  static String _csvCell(Object? value) {
    final text = value == null ? '' : '$value';
    return '"${text.replaceAll('"', '""')}"';
  }
}
