import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';

class NudgeScreen extends StatefulWidget {
  const NudgeScreen({super.key});

  @override
  State<NudgeScreen> createState() => _NudgeScreenState();
}

class _NudgeScreenState extends State<NudgeScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController(text: '78');
  final _lead = TextEditingController(text: '21');
  final _prior = TextEditingController(text: '4');
  final _imd = TextEditingController(text: '2');
  int _gender = 0;
  int _sms = 0;
  int _disability = 1;
  String _language = 'en';

  Map<String, dynamic>? _result;
  String? _error;
  bool _loading = false;

  static const _languages = {
    'en': 'English',
    'cy': 'Welsh',
    'ur': 'Urdu',
    'pl': 'Polish',
  };

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final res = await ApiService.patientNudge(
        patient: {
          'Age': int.tryParse(_age.text) ?? 0,
          'Gender': _gender,
          'AppointmentLeadTimeDays': int.tryParse(_lead.text) ?? 0,
          'SMSReceived': _sms,
          'PriorDNACount': int.tryParse(_prior.text) ?? 0,
          'IMDDecile': int.tryParse(_imd.text) ?? 1,
          'Disability': _disability,
        },
        language: _language,
        patientName: _name.text.trim(),
      );
      setState(() => _result = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(t.nudgeTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(t.nudgeSubtitle,
            style: const TextStyle(color: NHSTheme.darkGrey)),
        const SizedBox(height: 16),
        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: t.nudgeName),
            ),
            const SizedBox(height: 10),
            Row(children: [
              _num(_age, t.nudgeAge),
              const SizedBox(width: 10),
              _num(_imd, t.nudgeImd),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _num(_lead, t.nudgeLeadDays),
              const SizedBox(width: 10),
              _num(_prior, t.nudgePriorDnas),
            ]),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: InputDecoration(labelText: t.language),
              items: _languages.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _language = v ?? 'en'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.disability),
              value: _disability == 1,
              onChanged: (v) => setState(() => _disability = v ? 1 : 0),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.nudgeSmsSent),
              value: _sms == 1,
              onChanged: (v) => setState(() => _sms = v ? 1 : 0),
            ),
            const SizedBox(height: 6),
            ElevatedButton.icon(
              onPressed: _loading ? null : _run,
              icon: const Icon(Icons.message),
              label: Text(_loading ? t.nudgeGenerating : t.nudgeGenerate),
            ),
          ]),
        )),
        if (_error != null)
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: const TextStyle(color: NHSTheme.riskHigh)))),
        if (_result != null) _buildResult(),
      ],
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final tier = '${r['risk_tier']}';
    return Card(
      color: NHSTheme.riskBgColor(tier),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Chip(
              label: Text('${r['nudge_type']}'.toUpperCase(),
                  style: const TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor: NHSTheme.blue,
            ),
            const Spacer(),
            Text('${r['risk_probability']}% · $tier',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: NHSTheme.riskColor(tier))),
          ]),
          const SizedBox(height: 12),
          Text('${r['message']}', style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: ((r['personalisation_factors'] as List?) ?? [])
                .map<Widget>((f) => Chip(
                      label: Text('$f', style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ]),
      ),
    );
  }

  Widget _num(TextEditingController c, String label) => Expanded(
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
