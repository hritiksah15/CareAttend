import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';

/// Batch CSV scoring — pick a CSV of up to 100 patients, score them via
/// /api/batch, and show the returned results table. (Staff/admin)
class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  bool _busy = false;
  String? _error;
  String? _filename;
  List<List<String>> _rows = [];

  Future<void> _pickAndScore() async {
    setState(() {
      _busy = true;
      _error = null;
      _rows = [];
    });
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        setState(() => _busy = false);
        return;
      }
      final f = picked.files.first;
      final bytes = f.bytes;
      if (bytes == null) {
        setState(() => _error = 'Could not read the file.');
        return;
      }
      _filename = f.name;
      final csv = await ApiService.batchPredict(bytes, f.name);
      setState(() => _rows = _parseCsv(csv));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<List<String>> _parseCsv(String csv) {
    return csv
        .trim()
        .split('\n')
        .map((line) => line.split(',').map((c) => c.replaceAll('"', '').trim()).toList())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Batch Upload',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
            'Upload a CSV of up to 100 patients. Required columns: Age, Gender, '
            'AppointmentLeadTimeDays, SMSReceived, PriorDNACount, IMDDecile.',
            style: TextStyle(color: NHSTheme.darkGrey)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _busy ? null : _pickAndScore,
          icon: const Icon(Icons.upload_file),
          label: Text(_busy ? 'Scoring…' : 'Pick CSV & Score'),
        ),
        if (_filename != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('File: $_filename',
                style: const TextStyle(
                    color: NHSTheme.darkGrey, fontSize: 12)),
          ),
        if (_error != null)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!,
                      style: const TextStyle(color: NHSTheme.riskHigh)))),
        if (_rows.isNotEmpty) ...[
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(NHSTheme.paleGrey),
              columns: [
                for (final h in _rows.first) DataColumn(label: Text(h)),
              ],
              rows: [
                for (final r in _rows.skip(1))
                  DataRow(cells: [for (final c in r) DataCell(Text(c))]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
