import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';

class EthicsScreen extends StatefulWidget {
  const EthicsScreen({super.key});

  @override
  State<EthicsScreen> createState() => _EthicsScreenState();
}

class _EthicsScreenState extends State<EthicsScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = false;

  Map<String, dynamic>? _cv;
  bool _cvBusy = false;

  Future<void> _runCv() async {
    setState(() => _cvBusy = true);
    try {
      final data = await ApiService.crossValidation();
      setState(() => _cv = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _cvBusy = false);
    }
  }

  Widget _cvCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Cross-Validation (5-Fold)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Bootstrap 95% CIs and McNemar significance tests.',
              style: TextStyle(color: NHSTheme.darkGrey, fontSize: 13)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _cvBusy ? null : _runCv,
            icon: const Icon(Icons.analytics_outlined),
            label: Text(_cvBusy ? 'Running…' : 'Run Cross-Validation'),
          ),
          if (_cv != null) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(NHSTheme.paleGrey),
                columns: const [
                  DataColumn(label: Text('Model')),
                  DataColumn(label: Text('Mean F1')),
                  DataColumn(label: Text('95% CI')),
                  DataColumn(label: Text('Recall')),
                  DataColumn(label: Text('ROC-AUC')),
                ],
                rows: [
                  for (final e in ((_cv!['models'] as Map?) ?? {}).entries)
                    DataRow(cells: [
                      DataCell(Text('${e.key}')),
                      DataCell(Text(
                          '${(e.value['mean_f1'] as num).toStringAsFixed(4)}')),
                      DataCell(Text(
                          '[${e.value['ci_95_f1']['lower']}, ${e.value['ci_95_f1']['upper']}]')),
                      DataCell(Text(
                          '${(e.value['mean_recall'] as num).toStringAsFixed(4)}')),
                      DataCell(Text(
                          '${(e.value['mean_roc_auc'] as num).toStringAsFixed(4)}')),
                    ]),
                ],
              ),
            ),
            if ((_cv!['significance_tests'] as List?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              const Text('McNemar significance',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ...((_cv!['significance_tests'] as List).map((t) => Text(
                  '${t['model_a']} vs ${t['model_b']}: p=${(t['mcnemar_p_value'] as num).toStringAsFixed(6)} '
                  '${t['significant_at_005'] == true ? '(significant)' : ''}',
                  style: const TextStyle(fontSize: 13)))),
            ],
          ],
        ]),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.ethicsFramework();
      setState(() => _data = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Color _statusColor(String status) {
    if (status.toLowerCase().startsWith('addressed')) return NHSTheme.riskLow;
    if (status.toLowerCase().startsWith('partial')) return NHSTheme.riskMedium;
    return NHSTheme.grey;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('Ethics Framework',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('NHS England (2024) six-principle mapping with evidence.',
              style: TextStyle(color: NHSTheme.darkGrey)),
          const SizedBox(height: 16),
          _cvCard(),
          const SizedBox(height: 8),
          if (_loading) const Center(child: Padding(
              padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          if (_error != null)
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: NHSTheme.riskHigh)))),
          if (_data != null)
            ...((_data!['principles'] as List?) ?? []).map((p) => Card(
                  child: ExpansionTile(
                    leading: Icon(Icons.verified_user,
                        color: _statusColor('${p['status']}')),
                    title: Text('${p['principle']}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${p['status']}',
                        style: TextStyle(color: _statusColor('${p['status']}'))),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: ((p['evidence'] as List?) ?? [])
                              .map<Widget>((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('•  '),
                                        Expanded(child: Text('$e')),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
