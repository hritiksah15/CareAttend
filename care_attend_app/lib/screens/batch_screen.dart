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
        if (_rows.isNotEmpty) ..._buildResults(),
      ],
    );
  }

  /// Render the returned CSV as readable per-patient cards instead of a wide
  /// table that overflows on a phone. Header row drives the field mapping so it
  /// works for both the success shape (risk_tier, ...) and the error shape.
  List<Widget> _buildResults() {
    final header = _rows.first.map((h) => h.trim().toLowerCase()).toList();
    int col(String name) => header.indexOf(name);
    final dataRows = _rows.skip(1).where((r) => r.length == header.length).toList();

    final iTier = col('risk_tier');
    final iProb = col('risk_probability');
    final iAge = col('age');
    final iGroup = col('age_group');
    final iTop = col('top_risk_factor');
    final iRow = col('row');
    final iErr = col('error');

    int high = 0, med = 0, low = 0;
    if (iTier >= 0) {
      for (final r in dataRows) {
        switch (r[iTier].toLowerCase()) {
          case 'high':
            high++;
            break;
          case 'medium':
            med++;
            break;
          case 'low':
            low++;
            break;
        }
      }
    }

    return [
      const SizedBox(height: 16),
      Row(children: [
        _summary('${dataRows.length}', 'Patients', NHSTheme.blue),
        _summary('$high', 'High', NHSTheme.riskHigh),
        _summary('$med', 'Medium', NHSTheme.riskMedium),
        _summary('$low', 'Low', NHSTheme.riskLow),
      ]),
      const SizedBox(height: 12),
      ...dataRows.map((r) {
        if (iErr >= 0 && r[iErr].trim().isNotEmpty) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: NHSTheme.riskHigh),
              title: Text('Row ${iRow >= 0 ? r[iRow] : "?"}'),
              subtitle: Text(r[iErr]),
            ),
          );
        }
        final tier = iTier >= 0 ? r[iTier] : '';
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: NHSTheme.riskColor(tier.isEmpty ? 'Low' : tier),
              child: Text(iAge >= 0 ? r[iAge] : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
            title: Text('$tier risk'
                '${iGroup >= 0 && r[iGroup].isNotEmpty ? " · ${r[iGroup]}" : ""}'),
            subtitle: iTop >= 0 && r[iTop].isNotEmpty
                ? Text('Top factor: ${r[iTop]}')
                : null,
            trailing: Text(iProb >= 0 ? '${r[iProb]}%' : '',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        );
      }),
    ];
  }

  Widget _summary(String value, String label, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: NHSTheme.darkGrey)),
          ]),
        ),
      ),
    );
  }
}
