import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';
import '../utils/export.dart';
import '../widgets/ui.dart';

class BiasScreen extends StatefulWidget {
  const BiasScreen({super.key});

  @override
  State<BiasScreen> createState() => _BiasScreenState();
}

class _BiasScreenState extends State<BiasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  Map<String, dynamic>? _auditData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _runAudit() async {
    final t = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final data = await ApiService.biasAudit();
      setState(() => _auditData = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.biasAuditFailed)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header card
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.biasMonitorTitle,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 4),
                Text(t.biasSubtitle,
                    style: TextStyle(
                        fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),

                // Tab bar (Age / Gender / IMD)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: NHSTheme.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: NHSTheme.blue,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerHeight: 0,
                    tabs: [
                      Tab(text: t.biasTabAge),
                      Tab(text: t.gender),
                      Tab(text: t.biasTabImd),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _runAudit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(t.runAudit),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_auditData != null) ...[
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.biasExportAudit,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          Exporter.biasPdf(_auditData!, _generateSummary()),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Exporter.json(
                          _auditData!, 'CareAttend_Bias_Audit.json'),
                      icon: const Icon(Icons.data_object, size: 18),
                      label: const Text('JSON'),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Overall metrics
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.biasOverallPerf,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 12),
                  _buildMetricsRow(_auditData!['overall_metrics']),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab content
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAuditPanel(_auditData!['age_group'], t.biasAgeGroup),
                  _buildAuditPanel(_auditData!['gender'], t.gender),
                  _buildAuditPanel(_auditData!['imd_band'], t.biasImdBand),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Plain-English Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NHSTheme.calloutBg(context, const Color(0xFFF0F7FF)),
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                    left: BorderSide(color: NHSTheme.lightBlue, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.plainEnglishSummary,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 6),
                  Text(_generateSummary(),
                      style: TextStyle(
                          fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsRow(Map<String, dynamic> om) {
    final t = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _metricBox(t.biasF1, '${om['f1_score']}'),
        _metricBox(t.ethicsRecall, '${om['recall']}'),
        _metricBox(t.biasPrecision, '${om['precision']}'),
        _metricBox(t.biasSamples, '${om['total_samples']}'),
      ],
    );
  }

  Widget _metricBox(String label, String value) => Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NHSTheme.calloutBg(context, NHSTheme.paleGrey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary)),
            Text(label,
                style:
                    TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );

  Widget _buildAuditPanel(Map<String, dynamic> audit, String title) {
    final t = AppLocalizations.of(context);
    final dpDiff = (audit['demographic_parity_diff'] as num).toDouble();
    final eoDiff = (audit['equalised_odds_diff'] as num).toDouble();
    final dpPass = audit['dp_status'] == 'Pass';
    final eoPass = audit['eo_status'] == 'Pass';
    final groups = audit['groups'] as Map<String, dynamic>;

    return SingleChildScrollView(
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 12),

            // Demographic Parity bars
            Text(t.biasDpDiff,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ...groups.entries.map((e) {
              final ppr =
                  (e.value['positive_prediction_rate'] as num).toDouble();
              return _biasBar(e.key, ppr);
            }),

            const SizedBox(height: 16),

            // Status badges
            Row(
              children: [
                _statusBadge('DP: ${dpDiff.toStringAsFixed(2)}', dpPass),
                const SizedBox(width: 8),
                _statusBadge('EO: ${eoDiff.toStringAsFixed(2)}', eoPass),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _biasBar(String label, double value) {
    final t = AppLocalizations.of(context);
    final barWidth = (value * 4).clamp(0.0, 1.0);
    final status = value <= 0.10
        ? 'PASS'
        : value <= 0.12
            ? 'WARN'
            : 'FAIL';
    final statusLabel = status == 'PASS'
        ? t.biasBarPass
        : status == 'WARN'
            ? t.biasBarWarn
            : t.biasBarFail;
    final statusColor = status == 'PASS'
        ? NHSTheme.riskLow
        : status == 'WARN'
            ? const Color(0xFFB8860B)
            : NHSTheme.riskHigh;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                textAlign: TextAlign.right),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: barWidth,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 3,
                  child: Text(value.toStringAsFixed(2),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text('[$statusLabel]',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor)),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, bool pass) {
    final t = AppLocalizations.of(context);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: pass ? NHSTheme.riskLowBg : NHSTheme.riskHighBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: pass ? NHSTheme.riskLowBg : NHSTheme.riskHighBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(pass ? t.biasPass : t.biasFail,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color:
                          pass ? NHSTheme.riskLow : NHSTheme.riskHigh)),
            ),
            const SizedBox(width: 4),
            Text(text,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        pass ? NHSTheme.riskLow : NHSTheme.riskHigh)),
          ],
        ),
      );
  }

  String _generateSummary() {
    if (_auditData == null) return '';
    final t = AppLocalizations.of(context);

    final failures = <String>[];
    void check(Map<String, dynamic> audit, String name) {
      if (audit['dp_status'] != 'Pass') failures.add('$name (${t.biasFailDp})');
      if (audit['eo_status'] != 'Pass') failures.add('$name (${t.biasFailEo})');
    }

    check(_auditData!['age_group'], t.biasNameAge);
    check(_auditData!['gender'], t.biasNameGender);
    check(_auditData!['imd_band'], t.biasNameImd);

    if (failures.isEmpty) {
      return t.biasSummaryPass;
    }
    return t.biasSummaryFail(failures.join(', '));
  }

  Widget _card({required Widget child}) =>
      AppCard(padding: const EdgeInsets.all(20), child: child);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
