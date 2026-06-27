import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../theme/design_tokens.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../utils/export.dart';
import '../widgets/ui.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic>? result;
  final VoidCallback onNewAssessment;
  final VoidCallback onBiasDashboard;

  const ResultScreen({
    super.key,
    required this.result,
    required this.onNewAssessment,
    required this.onBiasDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assessment_outlined,
                size: 64, color: NHSTheme.grey),
            const SizedBox(height: 16),
            Text(t.noAssessmentYet,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(t.noAssessmentDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(color: NHSTheme.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onNewAssessment,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 44)),
              child: Text(t.goToAssessment),
            ),
          ],
        ),
      );
    }

    final tier = (result!['risk_tier'] as String).toLowerCase();
    final percentage = (result!['percentage'] as num).toDouble();
    final shapValues = result!['shap_values'] as List;
    final interventions = result!['interventions'] as List;
    final ageGroup = result!['age_group'] as String;
    final fullSessionId = result!['sessionId'] as String?;
    final sessionId = fullSessionId?.substring(0, 6).toUpperCase() ?? '---';
    final patient = result!['patient_summary'] as Map<String, dynamic>;
    final modelUsed = '${result!['model_used'] ?? 'Logistic Regression'}';
    final nlSummary = result!['nl_summary'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Risk Score Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Theme.of(context).brightness == Brightness.dark
                  ? Border.all(color: AppColors.darkOutline)
                  : null,
              boxShadow: Theme.of(context).brightness == Brightness.light
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                  : null,
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                // Session bar
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: NHSTheme.blue,
                  child: Text(
                    'Session: #$sessionId  |  Age Group: $ageGroup',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Gauge
                      SizedBox(
                        width: 180,
                        height: 180,
                        // Animate both the arc sweep and the % counter from 0 so
                        // the score reads as a deliberate, polished reveal.
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: percentage),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => RepaintBoundary(
                            child: CustomPaint(
                              painter:
                                  _GaugePainter(percentage: value, tier: tier),
                              child: Center(
                                child: Text('${value.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Risk tier badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 10),
                        decoration: BoxDecoration(
                          color: NHSTheme.riskColor(tier),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tier == 'high'
                              ? t.highRisk
                              : tier == 'medium'
                                  ? t.mediumRisk
                                  : t.lowRisk,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Patient meta chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: [
                          _chip('Age: ${patient['Age']}'),
                          _chip('Group: $ageGroup'),
                          _chip(
                              'Gender: ${patient['Gender'] == 1 ? 'Male' : 'Female'}'),
                          _chip('IMD: ${patient['IMDDecile']}'),
                          _chip('Lead: ${patient['AppointmentLeadTimeDays']}d'),
                          _chip('DNAs: ${patient['PriorDNACount']}'),
                          _chip('Model: $modelUsed'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SHAP Explanation Card
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.whyThisScore,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: NHSTheme.blue)),
                const SizedBox(height: 16),
                ...shapValues.take(3).map((sv) {
                  final value = (sv['value'] as num).toDouble();
                  final isRisk = value > 0;
                  final absVal = value.abs();
                  final maxVal = shapValues
                      .take(3)
                      .map((s) => (s['value'] as num).toDouble().abs())
                      .reduce(max);
                  final barWidth = maxVal > 0 ? absVal / maxVal : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(sv['label'] as String,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              if (!isRisk) ...[
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: FractionallySizedBox(
                                      widthFactor: barWidth,
                                      child: Container(
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: NHSTheme.riskLow,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Expanded(child: SizedBox()),
                              ] else ...[
                                const Expanded(child: SizedBox()),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: barWidth,
                                      child: Container(
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: NHSTheme.riskHigh,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRisk ? t.increasesRisk : t.reducesRisk,
                          style: TextStyle(
                            fontSize: 11,
                            color: isRisk ? NHSTheme.riskHigh : NHSTheme.riskLow,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Interventions Card
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.interventions,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: NHSTheme.blue)),
                const SizedBox(height: 12),
                ...interventions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final iv = entry.value as Map<String, dynamic>;
                  final priority = iv['priority'] as int;
                  final color = priority == 1
                      ? NHSTheme.riskHigh
                      : priority == 2
                          ? NHSTheme.riskMedium
                          : NHSTheme.riskLow;
                  final bgColor = priority == 1
                      ? NHSTheme.riskHighBg
                      : priority == 2
                          ? NHSTheme.riskMediumBg
                          : NHSTheme.riskLowBg;

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(left: BorderSide(color: color, width: 4)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: color,
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(iv['title'] as String,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: NHSTheme.blue)),
                              Text(iv['description'] as String,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Plain-English summary
          if (nlSummary != null && nlSummary.isNotEmpty) ...[
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.plainEnglishSummary,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: NHSTheme.blue)),
                  const SizedBox(height: 8),
                  Text(nlSummary,
                      style: const TextStyle(fontSize: 15, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Export
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.exportReport,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    onPressed: () => Exporter.patientPdf(result!),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Exporter.patientCsv(result!),
                    icon: const Icon(Icons.table_chart, size: 18),
                    label: const Text('CSV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Exporter.json(
                        result!, 'CareAttend_Patient_Report.json'),
                    icon: const Icon(Icons.data_object, size: 18),
                    label: const Text('JSON'),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Prediction feedback
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.feedbackQuestion,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: NHSTheme.blue)),
                const SizedBox(height: 4),
                Text(t.feedbackDesc,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 12),
                _FeedbackButtons(predictionId: fullSessionId),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Session risk history
          if (ApiService.riskHistory.length >= 2) ...[
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.riskHistory,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: NHSTheme.blue)),
                  const SizedBox(height: 16),
                  SizedBox(height: 180, child: _RiskHistoryChart()),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons (Fig 3.6b)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onNewAssessment,
                  child: Text(t.newAssessment),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onBiasDashboard,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: NHSTheme.darkBlue),
                  child: Text(t.biasDashboard),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) =>
      AppCard(padding: const EdgeInsets.all(20), child: child);

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: NHSTheme.paleGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            Text(text, style: const TextStyle(fontSize: 12, color: AppColors.darkGrey)),
      );
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final String tier;

  _GaugePainter({required this.percentage, required this.tier});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;
    const startAngle = 135 * pi / 180;
    const sweepTotal = 270 * pi / 180;
    final sweepValue = sweepTotal * (percentage / 100);

    // Background arc
    final bgPaint = Paint()
      ..color = NHSTheme.paleGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepTotal,
        false,
        bgPaint);

    // Value arc
    final valuePaint = Paint()
      ..color = NHSTheme.riskColor(tier)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepValue,
        false,
        valuePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FeedbackButtons extends StatefulWidget {
  final String? predictionId;
  const _FeedbackButtons({required this.predictionId});

  @override
  State<_FeedbackButtons> createState() => _FeedbackButtonsState();
}

class _FeedbackButtonsState extends State<_FeedbackButtons> {
  String? _done;
  bool _busy = false;

  Future<void> _send(String outcome) async {
    if (widget.predictionId == null) return;
    setState(() => _busy = true);
    try {
      await ApiService.submitFeedback(widget.predictionId!, outcome);
      setState(() => _done = outcome);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_done != null) {
      return Text(t.feedbackRecorded(_done!),
          style: TextStyle(
              color: NHSTheme.riskLow, fontWeight: FontWeight.w600));
    }
    Widget btn(String label, String outcome, Color c) => OutlinedButton(
          onPressed: _busy ? null : () => _send(outcome),
          style: OutlinedButton.styleFrom(
              foregroundColor: c, side: BorderSide(color: c)),
          child: Text(label),
        );
    return Wrap(spacing: 8, runSpacing: 8, children: [
      btn(t.feedbackAttended, 'attended', NHSTheme.riskLow),
      btn(t.feedbackDna, 'dna', NHSTheme.riskHigh),
      btn(t.feedbackCorrect, 'correct', NHSTheme.blue),
      btn(t.feedbackIncorrect, 'incorrect', Theme.of(context).colorScheme.onSurfaceVariant),
    ]);
  }
}

class _RiskHistoryChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hist = ApiService.riskHistory;
    final spots = <FlSpot>[
      for (var i = 0; i < hist.length; i++)
        FlSpot(i.toDouble(), (hist[i]['percentage'] as num).toDouble()),
    ];
    return LineChart(LineChartData(
      minY: 0,
      maxY: 100,
      titlesData: const FlTitlesData(
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: NHSTheme.blue,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ],
    ));
  }
}
