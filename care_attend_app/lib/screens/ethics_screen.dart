import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';
import '../widgets/ui.dart';

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
    final t = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.ethicsCvTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(t.ethicsCvDesc,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13)),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _cvBusy ? null : _runCv,
          icon: const Icon(Icons.analytics_outlined),
          label: Text(_cvBusy ? t.ethicsCvRunning : t.ethicsCvRun),
        ),
        if (_cv != null) ...[
          const SizedBox(height: 12),
          // Per-model cards rather than a wide table that overflowed the phone
          // and hid the 95% CI / Recall / ROC-AUC columns off-screen.
          for (final e in ((_cv!['models'] as Map?) ?? {}).entries)
            _cvModelCard(
              e.key.toString(),
              (e.value['mean_f1'] as num).toDouble(),
              e.value['ci_95_f1']['lower'],
              e.value['ci_95_f1']['upper'],
              (e.value['mean_recall'] as num).toDouble(),
              (e.value['mean_roc_auc'] as num).toDouble(),
            ),
          if ((_cv!['significance_tests'] as List?)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context).ethicsMcnemar,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...((_cv!['significance_tests'] as List).map((s) => Text(
                '${s['model_a']} vs ${s['model_b']}: p=${(s['mcnemar_p_value'] as num).toStringAsFixed(6)} '
                '${s['significant_at_005'] == true ? AppLocalizations.of(context).ethicsSignificant : ''}',
                style: const TextStyle(fontSize: 13)))),
          ],
        ],
      ]),
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

  Color _statusFill(String status) {
    if (status.toLowerCase().startsWith('addressed')) {
      return NHSTheme.calloutBg(context, const Color(0xFFEAF4FF));
    }
    if (status.toLowerCase().startsWith('partial')) {
      return NHSTheme.calloutBg(context, const Color(0xFFFFF8E1));
    }
    return NHSTheme.calloutBg(context, const Color(0xFFF3F5F8));
  }

  Widget _statusChip(String label, int count, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
            const SizedBox(height: 4),
            Text('$count',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _cvModelCard(String name, double f1, dynamic ciLo, dynamic ciHi,
      double recall, double rocAuc) {
    final t = AppLocalizations.of(context);
    Widget metricBar(String label, double value, Color accent) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: accent.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(height: 4),
              Text(value.toStringAsFixed(4),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        );
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: _statusFill('Addressed'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 10),
        Row(children: [
          metricBar(t.ethicsMeanF1, f1, NHSTheme.blue),
          const SizedBox(width: 10),
          metricBar(t.ethicsRecall, recall, NHSTheme.riskLow),
          const SizedBox(width: 10),
          metricBar(t.ethicsRocAuc, rocAuc, NHSTheme.lightBlue),
        ]),
        const SizedBox(height: 8),
        Text(t.ethicsCi('$ciLo', '$ciHi'),
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final principles = ((_data?['principles'] as List?) ?? const []);
    final addressed = principles
        .where((p) => '${p['status']}'.toLowerCase().startsWith('addressed'))
        .length;
    final partial = principles
        .where((p) => '${p['status']}'.toLowerCase().startsWith('partial'))
        .length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(t.ethicsFramework,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(t.ethicsSubtitle,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          _cvCard(),
          const SizedBox(height: 8),
          if (_loading) const SkeletonList(),
          if (_error != null) ErrorView(t.loadFailed, onRetry: _load),
          if (_data != null) ...[
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Framework coverage',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statusChip('Addressed', addressed, NHSTheme.riskLow),
                      const SizedBox(width: 10),
                      _statusChip('Partial', partial, NHSTheme.riskMedium),
                      const SizedBox(width: 10),
                      _statusChip('Total', principles.length, NHSTheme.blue),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...principles.map((p) => AppCard(
                  padding: EdgeInsets.zero,
                  color: _statusFill('${p['status']}'),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                            color: _statusColor('${p['status']}'), width: 5),
                      ),
                    ),
                    child: ExpansionTile(
                      leading: Icon(Icons.verified_user,
                          color: _statusColor('${p['status']}')),
                      title: Text('${p['principle']}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${p['status']}',
                          style: TextStyle(
                              color: _statusColor('${p['status']}'),
                              fontWeight: FontWeight.w700)),
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
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
