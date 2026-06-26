import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _fb;
  Map<String, dynamic>? _outcomes;
  String? _error;
  bool _loading = false;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.dashboard();
      Map<String, dynamic>? fb;
      Map<String, dynamic>? outcomes;
      try {
        fb = await ApiService.feedbackSummary();
      } catch (_) {/* feedback optional */}
      try {
        outcomes = await ApiService.operationalOutcomes();
      } catch (_) {/* operational outcomes optional */}
      if (!mounted) return;
      setState(() {
        _data = data;
        _fb = fb;
        _outcomes = outcomes;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(AppLocalizations.of(context).practiceDashboard,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context).practiceOverview,
              style: const TextStyle(color: NHSTheme.darkGrey)),
          const SizedBox(height: 16),
          if (_loading) const Center(child: Padding(
              padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          if (_error != null)
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: NHSTheme.riskHigh)))),
          if (_data != null) ..._buildContent(),
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    final t = AppLocalizations.of(context);
    final d = _data!;
    final total = d['total'] ?? 0;
    final widgets = <Widget>[];
    if (total == 0) {
      widgets.add(Card(
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Icon(Icons.bar_chart, size: 48, color: NHSTheme.grey),
          const SizedBox(height: 8),
          Text(t.noAssessmentsYet, textAlign: TextAlign.center),
        ]),
      )));
    } else {
      widgets.addAll([
        Row(children: [
          _statCard(t.statTotal, '$total', NHSTheme.blue),
          const SizedBox(width: 10),
          _statCard(t.statHigh, '${d['high_risk'] ?? 0}', NHSTheme.riskHigh),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _statCard(t.statMedium, '${d['medium_risk'] ?? 0}', NHSTheme.riskMedium),
          const SizedBox(width: 10),
          _statCard(t.statLow, '${d['low_risk'] ?? 0}', NHSTheme.riskLow),
        ]),
        const SizedBox(height: 8),
        Card(child: ListTile(
          leading: const Icon(Icons.percent, color: NHSTheme.blue),
          title: Text(t.averageRisk),
          trailing: Text(
              '${(((d['average_risk'] ?? 0) as num) * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        )),
      ]);
    }
    if (_fb != null && (_fb!['feedback_received'] ?? 0) > 0)
      widgets.add(
        Card(child: ListTile(
          leading: const Icon(Icons.fact_check_outlined, color: NHSTheme.blue),
          title: Text('Feedback: ${_fb!['feedback_received']} of '
              '${_fb!['total_predictions']}'),
          trailing: Text(
              _fb!['accuracy'] == null
                  ? '—'
                  : '${((_fb!['accuracy'] as num) * 100).toStringAsFixed(0)}% acc',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: NHSTheme.riskLow)),
        )),
      );
    widgets.add(const SizedBox(height: 8));
    widgets.add(Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(t.recentAssessments,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    ));
    widgets.addAll(
      ((d['recent_assessments'] as List?) ?? []).map((r) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: NHSTheme.riskColor(r['risk_tier'] ?? 'Low'),
                // Age is intentionally not persisted (NFR-01), so show the risk
                // tier initial rather than the literal string "Not stored".
                child: Text(
                    (r['risk_tier'] ?? '?').toString().isNotEmpty
                        ? (r['risk_tier'] as String)[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              title: Text('${r['risk_tier']} risk · ${r['age_group']}'),
              trailing: Text(
                  '${(((r['probability'] ?? 0) as num) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          )),
    );
    widgets.add(const SizedBox(height: 8));
    widgets.add(_buildOutcomesCard());
    return widgets;
  }

  Widget _buildOutcomesCard() {
    final o = _outcomes;
    if (o == null || o['appointments'] == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).operationalOutcomes,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Outcome metrics are not available yet.',
                  style: TextStyle(color: NHSTheme.darkGrey)),
            ],
          ),
        ),
      );
    }

    final appointments = o['appointments'] as Map<String, dynamic>;
    final outcomes = (o['outcomes'] as Map<String, dynamic>?) ?? {};
    final interventions = (o['interventions'] as Map<String, dynamic>?) ?? {};
    final actioned = (interventions['actioned_completed_appointments'] as Map<String, dynamic>?) ?? {};
    final unactioned = (interventions['unactioned_completed_appointments'] as Map<String, dynamic>?) ?? {};
    final delta = interventions['actioned_vs_unactioned_dna_gap'];

    double? asDouble(dynamic value) => value is num ? value.toDouble() : null;
    String fmt(double? value) => value == null ? '--' : '${(value * 100).toStringAsFixed(1)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Operational Outcomes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric('${appointments['completed'] ?? 0}', 'Completed', NHSTheme.blue),
              _metric(fmt(asDouble(outcomes['attended_rate'])), 'Attendance', NHSTheme.riskLow),
              _metric(fmt(asDouble(outcomes['dna_rate'])), 'DNA', NHSTheme.riskHigh),
              _metric('${interventions['completed_actions'] ?? 0}', 'Actions', NHSTheme.darkGrey),
              _metric(
                delta is num ? fmt(delta.toDouble()) : '--',
                'DNA Gap (obs.)',
                NHSTheme.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.black12),
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(0.8),
              2: FlexColumnWidth(0.8),
              3: FlexColumnWidth(0.8),
              4: FlexColumnWidth(0.8),
            },
            children: [
              _tableRow(['Cohort', 'Done', 'Att.', 'DNA', 'DNA Rate'], header: true),
              _tableRow([
                'Actioned',
                '${actioned['total'] ?? 0}',
                '${actioned['attended'] ?? 0}',
                '${actioned['dna'] ?? 0}',
                fmt(asDouble(actioned['dna_rate'])),
              ]),
              _tableRow([
                'Unactioned',
                '${unactioned['total'] ?? 0}',
                '${unactioned['attended'] ?? 0}',
                '${unactioned['dna'] ?? 0}',
                fmt(asDouble(unactioned['dna_rate'])),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Text('${interventions['note'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: NHSTheme.darkGrey)),
        ]),
      ),
    );
  }

  TableRow _tableRow(List<String> cells, {bool header = false}) {
    return TableRow(
      children: cells
          .map((c) => Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  c,
                  style: TextStyle(
                    fontWeight: header ? FontWeight.w700 : FontWeight.w400,
                    fontSize: header ? 12 : 13,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(children: [
            Text(value, style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: NHSTheme.darkGrey)),
          ]),
        ),
      ),
    );
  }

  Widget _metric(String value, String label, Color color) {
    return SizedBox(
      width: 110,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border(top: BorderSide(color: color, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 11, color: NHSTheme.darkGrey)),
          ]),
        ),
      ),
    );
  }
}
