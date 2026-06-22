import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _fb;
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
      try {
        fb = await ApiService.feedbackSummary();
      } catch (_) {/* feedback optional */}
      setState(() {
        _data = data;
        _fb = fb;
      });
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('Practice Dashboard',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Session-scoped overview of assessments made this session.',
              style: TextStyle(color: NHSTheme.darkGrey)),
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
    final d = _data!;
    final total = d['total'] ?? 0;
    if (total == 0) {
      return [Card(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: const [
          Icon(Icons.bar_chart, size: 48, color: NHSTheme.grey),
          SizedBox(height: 8),
          Text('No assessments yet. Run a Patient Assessment first.'),
        ]),
      ))];
    }
    return [
      Row(children: [
        _statCard('Total', '$total', NHSTheme.blue),
        _statCard('High', '${d['high_risk'] ?? 0}', NHSTheme.riskHigh),
      ]),
      Row(children: [
        _statCard('Medium', '${d['medium_risk'] ?? 0}', NHSTheme.riskMedium),
        _statCard('Low', '${d['low_risk'] ?? 0}', NHSTheme.riskLow),
      ]),
      const SizedBox(height: 8),
      Card(child: ListTile(
        leading: const Icon(Icons.percent, color: NHSTheme.blue),
        title: const Text('Average risk'),
        trailing: Text(
            '${(((d['average_risk'] ?? 0) as num) * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      )),
      if (_fb != null && (_fb!['feedback_received'] ?? 0) > 0)
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
      const SizedBox(height: 8),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text('Recent assessments',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      ...((d['recent_assessments'] as List?) ?? []).map((r) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: NHSTheme.riskColor(r['risk_tier'] ?? 'Low'),
                child: Text('${r['age']}',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
              title: Text('${r['risk_tier']} risk · ${r['age_group']}'),
              trailing: Text(
                  '${(((r['probability'] ?? 0) as num) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          )),
    ];
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
}
