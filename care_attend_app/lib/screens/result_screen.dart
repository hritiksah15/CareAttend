import 'dart:math';
import 'package:flutter/material.dart';
import '../nhs_theme.dart';

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
    if (result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assessment_outlined,
                size: 64, color: NHSTheme.grey),
            const SizedBox(height: 16),
            const Text('No Assessment Yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: NHSTheme.darkGrey)),
            const SizedBox(height: 8),
            const Text('Complete patient assessment to view results.',
                style: TextStyle(color: NHSTheme.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onNewAssessment,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 44)),
              child: const Text('Go to Assessment'),
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
    final sessionId = (result!['sessionId'] as String?)?.substring(0, 6).toUpperCase() ?? '---';
    final patient = result!['patient_summary'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Risk Score Card
          Container(
            width: double.infinity,
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
                        child: CustomPaint(
                          painter: _GaugePainter(
                              percentage: percentage, tier: tier),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${percentage.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700)),
                              ],
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
                          '${tier.toUpperCase()} RISK',
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
                const Text('Why This Score? (SHAP)',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: NHSTheme.blue)),
                const SizedBox(height: 16),
                ...shapValues.take(5).map((sv) {
                  final value = (sv['value'] as num).toDouble();
                  final isRisk = value > 0;
                  final absVal = value.abs();
                  final maxVal = shapValues
                      .take(5)
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
                          isRisk ? 'Increases Risk' : 'Reduces Risk',
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
                const Text('Recommended Interventions',
                    style: TextStyle(
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
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: NHSTheme.darkGrey)),
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

          // Action buttons (Fig 3.6b)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onNewAssessment,
                  child: const Text('New Assessment'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onBiasDashboard,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: NHSTheme.darkBlue),
                  child: const Text('Bias Dashboard'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
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

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: NHSTheme.paleGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            Text(text, style: const TextStyle(fontSize: 12, color: NHSTheme.darkGrey)),
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
