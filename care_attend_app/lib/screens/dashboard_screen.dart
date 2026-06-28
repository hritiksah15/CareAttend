import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../widgets/ui.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onOpenModule;
  const DashboardScreen({super.key, this.onOpenModule});

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
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context).practiceOverview,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (_loading) const SkeletonList(count: 4),
          if (_error != null)
            ErrorView(AppLocalizations.of(context).loadFailed, onRetry: _load),
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
    widgets.add(_buildModuleCards(d));
    widgets.add(const SizedBox(height: 12));
    if (total == 0) {
      widgets.add(AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Icon(Icons.bar_chart, size: 48, color: NHSTheme.grey),
          const SizedBox(height: 8),
          Text(t.noAssessmentsYet, textAlign: TextAlign.center),
        ]),
      ));
    } else {
      widgets.addAll([
        Row(children: [
          _statCard(
              t.statTotal, '$total', Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          _statCard(t.statHigh, '${d['high_risk'] ?? 0}', NHSTheme.riskHigh),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _statCard(
              t.statMedium, '${d['medium_risk'] ?? 0}', NHSTheme.riskMedium),
          const SizedBox(width: 10),
          _statCard(t.statLow, '${d['low_risk'] ?? 0}', NHSTheme.riskLow),
        ]),
        const SizedBox(height: 8),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.percent,
                color: Theme.of(context).colorScheme.primary),
            title: Text(t.averageRisk),
            trailing: Text(
                '${(((d['average_risk'] ?? 0) as num) * 100).toStringAsFixed(1)}%',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
      ]);
    }
    if (_fb != null && (_fb!['feedback_received'] ?? 0) > 0) {
      widgets.add(
        AppCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.fact_check_outlined,
                color: Theme.of(context).colorScheme.primary),
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
          ),
        ),
      );
    }
    widgets.add(const SizedBox(height: 8));
    widgets.add(_buildAgeBreakdownCard(d));
    widgets.add(const SizedBox(height: 8));
    widgets.add(Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(t.recentAssessments,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    ));
    final recent = ((d['recent_assessments'] as List?) ?? []);
    if (recent.isEmpty) {
      widgets.add(AppCard(
        padding: const EdgeInsets.all(16),
        child: Text('No recent assessments to review yet.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ));
    } else {
      widgets.addAll(recent.map(_buildAssessmentResultCard));
    }
    widgets.add(const SizedBox(height: 8));
    widgets.add(_buildOutcomesCard());
    return widgets;
  }

  Widget _buildModuleCards(Map<String, dynamic> data) {
    final modules = [
      const DashboardModule(
        icon: Icons.edit_note,
        title: 'New Assessment',
        metric: 'Score one patient',
        detail: 'Start the privacy-minimised risk workflow.',
        targetIndex: 0,
      ),
      const DashboardModule(
        icon: Icons.event_note,
        title: 'Clinic List',
        metric: 'Tomorrow worklist',
        detail: 'Track calls, SMS, transport and outcomes.',
        targetIndex: 10,
      ),
      const DashboardModule(
        icon: Icons.upload_file,
        title: 'Batch Upload',
        metric: 'Up to 100 patients',
        detail: 'Score a cohort with the wide CSV template.',
        targetIndex: 9,
      ),
      if (ApiService.canBias)
        DashboardModule(
          icon: Icons.balance,
          title: 'Bias Monitor',
          metric: '${data['total'] ?? 0} assessments',
          detail: 'Review fairness checks and tier thresholds.',
          targetIndex: 3,
        ),
    ];

    return DashboardModuleGrid(
      modules: modules,
      onOpenModule: widget.onOpenModule,
    );
  }

  Widget _buildAgeBreakdownCard(Map<String, dynamic> data) {
    final raw = data['age_breakdown'];
    final entries = raw is Map ? raw.entries.toList() : const [];
    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.groups_outlined,
            color: Theme.of(context).colorScheme.primary),
        title: const Text('Age Group Breakdown',
            style: TextStyle(fontWeight: FontWeight.w700)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: entries.isEmpty
            ? [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('No age-group breakdown available yet.',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                )
              ]
            : entries.map((entry) {
                final stats = entry.value is Map ? entry.value as Map : {};
                final total = (stats['total'] as num?)?.toDouble() ?? 0;
                final highRisk = (stats['high_risk'] as num?)?.toDouble() ?? 0;
                final pct = total > 0
                    ? '${((highRisk / total) * 100).toStringAsFixed(1)}%'
                    : '0.0%';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${entry.key}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${stats['high_risk'] ?? 0} high risk'),
                  trailing: Text('$pct high',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                );
              }).toList(),
      ),
    );
  }

  Widget _buildAssessmentResultCard(dynamic raw) {
    final r = raw is Map ? raw : {};
    final tier = '${r['risk_tier'] ?? 'Unknown'}';
    final probability = r['probability'] is num
        ? '${(((r['probability'] as num) * 100).toStringAsFixed(1))}%'
        : '--';
    final ageGroup = '${r['age_group'] ?? 'Not stored'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: NHSTheme.riskColor(tier),
            child: Text(_riskInitial(tier),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          title: Text('$tier risk · $ageGroup',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('$probability risk score · tap for detailed record'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            _detailRow('Assessment ID', '${r['id'] ?? '—'}'),
            _detailRow('Age', '${r['age'] ?? 'Not stored'}'),
            _detailRow('Age group', ageGroup),
            _detailRow('Risk tier', tier),
            _detailRow('Risk score', probability),
            _detailRow('Next action', _nextAction(tier)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onOpenModule == null
                        ? null
                        : () => widget.onOpenModule!(0),
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('New Assessment'),
                  ),
                  if (ApiService.role == 'staff' || ApiService.role == 'admin')
                    FilledButton.icon(
                      onPressed: widget.onOpenModule == null
                          ? null
                          : () => widget.onOpenModule!(10),
                      icon: const Icon(Icons.event_note, size: 18),
                      label: const Text('Clinic List'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 112,
          child: Text(label,
              style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ),
        Expanded(child: Text(value)),
      ]),
    );
  }

  String _riskInitial(String tier) {
    return tier.isNotEmpty ? tier.characters.first.toUpperCase() : '?';
  }

  String _nextAction(String tier) {
    switch (tier.toLowerCase()) {
      case 'high':
        return 'Prioritise same-day outreach and confirm transport or carer support.';
      case 'medium':
        return 'Send reminder and review practical barriers before the appointment.';
      default:
        return 'Standard reminder pathway.';
    }
  }

  Widget _buildOutcomesCard() {
    final o = _outcomes;
    if (o == null || o['appointments'] == null) {
      return AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          leading: Icon(Icons.analytics_outlined,
              color: Theme.of(context).colorScheme.primary),
          title: Text(AppLocalizations.of(context).operationalOutcomes,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Outcome metrics are not available yet.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      );
    }

    final appointments = o['appointments'] as Map<String, dynamic>;
    final outcomes = (o['outcomes'] as Map<String, dynamic>?) ?? {};
    final interventions = (o['interventions'] as Map<String, dynamic>?) ?? {};
    final actioned = (interventions['actioned_completed_appointments']
            as Map<String, dynamic>?) ??
        {};
    final unactioned = (interventions['unactioned_completed_appointments']
            as Map<String, dynamic>?) ??
        {};
    final delta = interventions['actioned_vs_unactioned_dna_gap'];

    double? asDouble(dynamic value) => value is num ? value.toDouble() : null;
    String fmt(double? value) =>
        value == null ? '--' : '${(value * 100).toStringAsFixed(1)}%';

    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.analytics_outlined,
            color: Theme.of(context).colorScheme.primary),
        title: const Text('Operational Outcomes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        subtitle: const Text('Expandable action and outcome record'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric('${appointments['completed'] ?? 0}', 'Completed',
                  Theme.of(context).colorScheme.primary),
              _metric(fmt(asDouble(outcomes['attended_rate'])), 'Attendance',
                  NHSTheme.riskLow),
              _metric(fmt(asDouble(outcomes['dna_rate'])), 'DNA',
                  NHSTheme.riskHigh),
              _metric('${interventions['completed_actions'] ?? 0}', 'Actions',
                  Theme.of(context).colorScheme.onSurfaceVariant),
              _metric(
                delta is num ? fmt(delta.toDouble()) : '--',
                'DNA Gap (obs.)',
                Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 520,
              child: Table(
                border: TableBorder.all(color: Colors.black12),
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(0.8),
                  2: FlexColumnWidth(0.8),
                  3: FlexColumnWidth(0.8),
                  4: FlexColumnWidth(0.8),
                },
                children: [
                  _tableRow(['Cohort', 'Done', 'Att.', 'DNA', 'DNA Rate'],
                      header: true),
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
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${interventions['note'] ?? ''}',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
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
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
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
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

class DashboardModuleGrid extends StatelessWidget {
  final List<DashboardModule> modules;
  final ValueChanged<int>? onOpenModule;

  const DashboardModuleGrid({
    super.key,
    required this.modules,
    this.onOpenModule,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 760 ? 4 : (width >= 520 ? 3 : 2);
      final aspectRatio = width < 380 ? 0.92 : (width < 520 ? 1.05 : 1.25);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: modules.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: aspectRatio,
        ),
        itemBuilder: (context, index) => _buildModuleCard(
          context,
          modules[index],
        ),
      );
    });
  }

  Widget _buildModuleCard(BuildContext context, DashboardModule module) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${module.title}, ${module.metric}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpenModule == null
            ? null
            : () => onOpenModule!(module.targetIndex),
        child: AppCard(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(module.icon, color: cs.primary, size: 20),
            ),
            const SizedBox(height: 10),
            Text(module.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 2),
            Text(module.metric,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: cs.onSurface, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Expanded(
              child: Text(module.detail,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 12, height: 1.25)),
            ),
          ]),
        ),
      ),
    );
  }
}

class DashboardModule {
  final IconData icon;
  final String title;
  final String metric;
  final String detail;
  final int targetIndex;

  const DashboardModule({
    required this.icon,
    required this.title,
    required this.metric,
    required this.detail,
    required this.targetIndex,
  });
}
