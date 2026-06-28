import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';
import '../utils/export.dart';
import '../widgets/ui.dart';

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

  Future<void> _pickAndScore(AppLocalizations t) async {
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
        setState(() => _error = t.batchReadError);
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
        .map((line) =>
            line.split(',').map((c) => c.replaceAll('"', '').trim()).toList())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(t.batchUpload,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(t.batchUploadDesc,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _busy ? null : () => _pickAndScore(t),
          icon: const Icon(Icons.upload_file),
          label: Text(_busy ? t.batchScoring : t.batchPickCsv),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: Exporter.batchTemplateCsv,
          icon: const Icon(Icons.download),
          label: const Text('Download template CSV'),
        ),
        if (_filename != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(t.batchFile(_filename!),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12)),
          ),
        if (_error != null)
          AppCard(
              padding: const EdgeInsets.all(16),
              child: Text(_error!,
                  style: const TextStyle(color: NHSTheme.riskHigh))),
        if (_rows.isNotEmpty) ..._buildResults(t),
      ],
    );
  }

  /// Map a CSV tier value to the localized full-phrase tier label so word order
  /// stays correct in RTL/CY rather than interpolating a word into a template.
  String _tierPhrase(AppLocalizations t, String tier) {
    switch (tier.toLowerCase()) {
      case 'high':
        return t.highRisk;
      case 'medium':
        return t.mediumRisk;
      case 'low':
        return t.lowRisk;
      default:
        return tier;
    }
  }

  /// Render the returned CSV as readable per-patient cards instead of a wide
  /// table that overflows on a phone. Header row drives the field mapping so it
  /// works for both the success shape (risk_tier, ...) and the error shape.
  List<Widget> _buildResults(AppLocalizations t) {
    final header = _rows.first.map((h) => h.trim().toLowerCase()).toList();
    int col(String name) => header.indexOf(name);
    final dataRows =
        _rows.skip(1).where((r) => r.length == header.length).toList();

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
        _summary('${dataRows.length}', t.batchPatients,
            Theme.of(context).colorScheme.primary),
        _summary('$high', t.statHigh, NHSTheme.riskHigh),
        _summary('$med', t.statMedium, NHSTheme.riskMedium),
        _summary('$low', t.statLow, NHSTheme.riskLow),
      ]),
      const SizedBox(height: 12),
      ...dataRows.map((r) {
        if (iErr >= 0 && r[iErr].trim().isNotEmpty) {
          return AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading:
                  const Icon(Icons.error_outline, color: NHSTheme.riskHigh),
              title: Text(t.batchRow(iRow >= 0 ? r[iRow] : '?')),
              subtitle: Text(r[iErr]),
            ),
          );
        }
        final tier = iTier >= 0 ? r[iTier] : '';
        return AppCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: NHSTheme.riskColor(tier.isEmpty ? 'Low' : tier),
              child: Text(iAge >= 0 ? r[iAge] : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
            title: Text('${_tierPhrase(t, tier)}'
                '${iGroup >= 0 && r[iGroup].isNotEmpty ? " · ${r[iGroup]}" : ""}'),
            subtitle: iTop >= 0 && r[iTop].isNotEmpty
                ? Text(t.batchTopFactor(r[iTop]))
                : null,
            trailing: Text(iProb >= 0 ? '${r[iProb]}%' : '',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        );
      }),
    ];
  }

  Widget _summary(String value, String label, Color color) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}
