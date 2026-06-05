import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';

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
        const SnackBar(content: Text('Audit failed. Check server connection.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header card
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ethical Bias Monitoring Dashboard',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: NHSTheme.blue)),
                const SizedBox(height: 4),
                const Text(
                    'Fairness metrics across protected characteristic groups. Threshold: 0.10.',
                    style:
                        TextStyle(fontSize: 14, color: NHSTheme.darkGrey)),
                const SizedBox(height: 16),

                // Tab bar (Age / Gender / IMD)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: NHSTheme.blue, width: 2),
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
                    tabs: const [
                      Tab(text: 'Age'),
                      Tab(text: 'Gender'),
                      Tab(text: 'IMD'),
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
                      : const Text('Run Bias Audit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_auditData != null) ...[
            // Overall metrics
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall Model Performance',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: NHSTheme.blue)),
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
                  _buildAuditPanel(_auditData!['age_group'], 'Age Group'),
                  _buildAuditPanel(_auditData!['gender'], 'Gender'),
                  _buildAuditPanel(_auditData!['imd_band'], 'IMD Band'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Plain-English Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                    left: BorderSide(color: NHSTheme.lightBlue, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Plain-English Summary',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: NHSTheme.blue)),
                  const SizedBox(height: 6),
                  Text(_generateSummary(),
                      style: const TextStyle(
                          fontSize: 13, color: NHSTheme.darkGrey)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsRow(Map<String, dynamic> om) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _metricBox('F1-Score', '${om['f1_score']}'),
        _metricBox('Recall', '${om['recall']}'),
        _metricBox('Precision', '${om['precision']}'),
        _metricBox('Samples', '${om['total_samples']}'),
      ],
    );
  }

  Widget _metricBox(String label, String value) => Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NHSTheme.paleGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: NHSTheme.blue)),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: NHSTheme.darkGrey)),
          ],
        ),
      );

  Widget _buildAuditPanel(Map<String, dynamic> audit, String title) {
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
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: NHSTheme.blue)),
            const SizedBox(height: 12),

            // Demographic Parity bars
            const Text('DEMOGRAPHIC PARITY DIFFERENCE',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: NHSTheme.darkGrey,
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
    final barWidth = (value * 4).clamp(0.0, 1.0);
    final status = value <= 0.10
        ? 'PASS'
        : value <= 0.12
            ? 'WARN'
            : 'FAIL';
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
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
                      color: NHSTheme.darkGrey,
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
          Text('[$status]',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor)),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, bool pass) => Container(
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
              child: Text(pass ? 'Pass' : 'Fail',
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

  String _generateSummary() {
    if (_auditData == null) return '';

    final failures = <String>[];
    void check(Map<String, dynamic> audit, String name) {
      if (audit['dp_status'] != 'Pass') failures.add('$name (demographic parity)');
      if (audit['eo_status'] != 'Pass') failures.add('$name (equalised odds)');
    }

    check(_auditData!['age_group'], 'age');
    check(_auditData!['gender'], 'gender');
    check(_auditData!['imd_band'], 'IMD');

    if (failures.isEmpty) {
      return 'Model shows acceptable fairness across all protected attribute groups. All metrics within the 0.10 threshold.';
    }
    return 'Model shows acceptable fairness across most age groups. The following exceed the 0.10 threshold: ${failures.join(', ')}. This may reflect genuine clinical risk rather than algorithmic bias.';
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: child,
      );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
