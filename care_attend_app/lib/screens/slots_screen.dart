import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';

class SlotsScreen extends StatefulWidget {
  const SlotsScreen({super.key});

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  final _age = TextEditingController(text: '78');
  final _lead = TextEditingController(text: '21');
  final _prior = TextEditingController(text: '4');
  final _imd = TextEditingController(text: '2');
  final _slot = TextEditingController(text: '15');
  int _gender = 0;
  int _sms = 0;

  Map<String, dynamic>? _result;
  String? _error;
  bool _loading = false;

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final res = await ApiService.slotOptimisation([
        {
          'Age': int.tryParse(_age.text) ?? 0,
          'Gender': _gender,
          'AppointmentLeadTimeDays': int.tryParse(_lead.text) ?? 0,
          'SMSReceived': _sms,
          'PriorDNACount': int.tryParse(_prior.text) ?? 0,
          'IMDDecile': int.tryParse(_imd.text) ?? 1,
          'slotMinutes': int.tryParse(_slot.text) ?? 15,
        }
      ]);
      setState(() => _result = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Slot Optimisation',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Estimate DNA risk for a slot and whether it can be overbooked.',
            style: TextStyle(color: NHSTheme.darkGrey)),
        const SizedBox(height: 16),
        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              _num(_age, 'Age'),
              const SizedBox(width: 10),
              _num(_lead, 'Lead days'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _num(_prior, 'Prior DNAs'),
              const SizedBox(width: 10),
              _num(_imd, 'IMD (1-10)'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _num(_slot, 'Slot mins'),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<int>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Female')),
                  DropdownMenuItem(value: 1, child: Text('Male')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 0),
              )),
            ]),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('SMS reminder sent'),
              value: _sms == 1,
              onChanged: (v) => setState(() => _sms = v ? 1 : 0),
            ),
            const SizedBox(height: 6),
            ElevatedButton.icon(
              onPressed: _loading ? null : _run,
              icon: const Icon(Icons.event_available),
              label: Text(_loading ? 'Analysing…' : 'Analyse slot'),
            ),
          ]),
        )),
        if (_error != null)
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: const TextStyle(color: NHSTheme.riskHigh)))),
        if (_result != null) ..._buildResult(),
      ],
    );
  }

  Widget _metric(String value, String label) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: NHSTheme.paleGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: NHSTheme.blue)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: NHSTheme.darkGrey)),
          ]),
        ),
      );

  List<Widget> _buildResult() {
    final slots = (_result!['slots'] as List?) ?? [];
    if (slots.isEmpty) return [];
    final summary = _result!['summary'] as Map<String, dynamic>?;
    final s = slots.first as Map<String, dynamic>;
    if (s.containsKey('error')) {
      return [Card(child: Padding(
        padding: const EdgeInsets.all(16), child: Text('${s['error']}')))];
    }
    final prob = (((s['dna_probability'] ?? 0) as num) * 100).toStringAsFixed(0);
    final tier = '${s['risk_tier']}';
    return [
      if (summary != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            _metric('${summary['overbookable']}', 'Overbookable'),
            _metric('${summary['total_expected_waste_minutes']} min',
                'Expected waste'),
            _metric('${summary['potential_recovery_percent']}%',
                'Recovery potential'),
          ]),
        ),
      Card(
        color: NHSTheme.riskBgColor(tier),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.warning_amber, color: NHSTheme.riskColor(tier)),
              const SizedBox(width: 8),
              Text('$prob% DNA risk · $tier',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: NHSTheme.riskColor(tier))),
            ]),
            const SizedBox(height: 10),
            Text('Can overbook: ${s['can_overbook'] == true ? 'Yes' : 'No'}'),
            Text('Expected wasted minutes: ${s['expected_waste_minutes']}'),
            const SizedBox(height: 10),
            Text('${s['recommendation']}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ];
  }

  Widget _num(TextEditingController c, String label) => Expanded(
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
