import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';

class ClinicScreen extends StatefulWidget {
  const ClinicScreen({super.key});

  @override
  State<ClinicScreen> createState() => _ClinicScreenState();
}

class _ClinicScreenState extends State<ClinicScreen> {
  static const _statuses = [
    'scheduled',
    'confirmed',
    'attended',
    'dna',
    'cancelled',
    'rescheduled',
  ];

  final _patientId = TextEditingController(text: 'NHS001');
  final _time = TextEditingController(text: '09:00');
  final _clinic = TextEditingController(text: 'Diabetes Review');
  final _bulkJson = TextEditingController(
    text:
        '[{"patient_id":"NHS001","appointment_date":"2026-07-01","appointment_time":"09:00","clinic":"Diabetes Review"}]',
  );

  late DateTime _date;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    _load();
  }

  @override
  void dispose() {
    _patientId.dispose();
    _time.dispose();
    _clinic.dispose();
    _bulkJson.dispose();
    super.dispose();
  }

  String get _dateText {
    final m = _date.month.toString().padLeft(2, '0');
    final d = _date.day.toString().padLeft(2, '0');
    return '${_date.year}-$m-$d';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (!mounted) return;
    if (picked == null) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.clinicList(_dateText);
      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addAppointment() async {
    final patientId = _patientId.text.trim();
    if (patientId.isEmpty) {
      _toast(AppLocalizations.of(context).clinicEnterPatientId);
      return;
    }
    await _postAppointments({
      'patient_id': patientId,
      'appointment_date': _dateText,
      'appointment_time': _time.text.trim(),
      'clinic': _clinic.text.trim(),
    });
  }

  Future<void> _importJson() async {
    final t = AppLocalizations.of(context);
    try {
      final parsed = jsonDecode(_bulkJson.text);
      final payload = parsed is List
          ? {'appointments': parsed}
          : Map<String, dynamic>.from(parsed as Map);
      await _postAppointments(payload);
    } catch (_) {
      _toast(t.clinicJsonInvalid);
    }
  }

  Future<void> _postAppointments(Map<String, dynamic> payload) async {
    final t = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.createAppointments(payload);
      if (!mounted) return;
      _toast(t.clinicImported('${res['created']}'));
      _patientId.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String appointmentId, String status) async {
    final t = AppLocalizations.of(context);
    try {
      await ApiService.updateAppointmentStatus(appointmentId, status);
      if (!mounted) return;
      _toast(t.clinicStatusUpdated);
      await _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _scheduleReminder(Map<String, dynamic> appt) async {
    final t = AppLocalizations.of(context);
    try {
      await ApiService.scheduleNotification(
        patientId: '${appt['patient_id']}',
        riskTier: '${appt['risk_tier']}',
        appointmentDate: '${appt['appointment_date']}',
      );
      if (!mounted) return;
      _toast(t.clinicReminderScheduled);
      await _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _recordCall(Map<String, dynamic> appt) async {
    final t = AppLocalizations.of(context);
    try {
      await ApiService.createOutreachAction({
        'patient_id': appt['patient_id'],
        'risk_tier': appt['risk_tier'],
        'appointment_date': appt['appointment_date'],
        'action_type': 'call',
        'status': 'completed',
        'outcome': 'left_message',
        'notes': 'Recorded from mobile clinic list.',
      });
      if (!mounted) return;
      _toast(t.clinicCallRecorded);
      await _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final appointments = ((_data?['appointments'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final summary = (_data?['summary'] as Map<String, dynamic>?) ?? {};

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        // Extra bottom padding so the last card's action buttons (Reminder/Call)
        // clear the floating chatbot button in the bottom-right corner.
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        children: [
          Text(t.clinicTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(t.clinicSubtitle,
              style: const TextStyle(color: NHSTheme.darkGrey)),
          const SizedBox(height: 16),
          _buildImportCard(),
          if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!,
                    style: const TextStyle(color: NHSTheme.riskHigh)),
              ),
            ),
          _buildSummary(summary),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (appointments.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(t.clinicNoAppointments),
              ),
            )
          else
            for (final appt in appointments) _buildAppointmentCard(appt),
        ],
      ),
    );
  }

  Widget _buildImportCard() {
    final t = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(_dateText),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: t.clinicRefresh,
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _patientId,
            decoration: InputDecoration(labelText: t.clinicPatientId),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _time,
                decoration: InputDecoration(labelText: t.clinicTime),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _clinic,
                decoration: InputDecoration(labelText: t.clinicClinic),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loading ? null : _addAppointment,
            icon: const Icon(Icons.calendar_today),
            label: Text(_loading ? t.clinicWorking : t.clinicAddAppointment),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(t.clinicBulkImport,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            children: [
              TextField(
                controller: _bulkJson,
                minLines: 4,
                maxLines: 8,
                decoration:
                    InputDecoration(labelText: t.clinicApptsJson),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _loading ? null : _importJson,
                icon: const Icon(Icons.upload_file),
                label: Text(t.clinicImportJson),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildSummary(Map<String, dynamic> s) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _metric('${s['total'] ?? 0}', t.clinicApptsLabel, NHSTheme.blue),
          _metric('${s['high_risk'] ?? 0}', t.statHigh, NHSTheme.riskHigh),
          _metric('${s['medium_risk'] ?? 0}', t.statMedium, NHSTheme.riskMedium),
          _metric('${s['actioned'] ?? 0}', t.clinicActioned, NHSTheme.riskLow),
          _metric('${s['needs_action'] ?? 0}', t.clinicNeedsAction, NHSTheme.darkGrey),
        ],
      ),
    );
  }

  Widget _metric(String value, String label, Color color) {
    return SizedBox(
      width: 112,
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
                    color: color, fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 11, color: NHSTheme.darkGrey)),
          ]),
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations t, String status) {
    switch (status) {
      case 'confirmed':
        return t.clinicStConfirmed;
      case 'attended':
        return t.clinicStAttended;
      case 'dna':
        return t.clinicStDna;
      case 'cancelled':
        return t.clinicStCancelled;
      case 'rescheduled':
        return t.clinicStRescheduled;
      default:
        return t.clinicStScheduled;
    }
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final t = AppLocalizations.of(context);
    final tier = '${appt['risk_tier'] ?? 'Low'}';
    final prob = appt['probability'] is num
        ? '${((appt['probability'] as num) * 100).toStringAsFixed(1)}%'
        : '--';
    final status = _statuses.contains(appt['status']) ? '${appt['status']}' : 'scheduled';
    final canNotify = tier == 'High' || tier == 'Medium';

    return Card(
      color: NHSTheme.riskBgColor(tier),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${appt['appointment_time'] ?? '--'} · ${appt['patient_id']}',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${appt['clinic'] ?? ''}',
                        style: const TextStyle(color: NHSTheme.darkGrey)),
                  ]),
            ),
            Chip(
              backgroundColor: NHSTheme.riskColor(tier),
              label: Text('$tier · $prob',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: status,
                decoration: InputDecoration(labelText: t.clinicStatus),
                items: _statuses
                    .map((s) => DropdownMenuItem(
                        value: s, child: Text(_statusLabel(t, s))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _updateStatus('${appt['id']}', v);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${t.clinicActionsCount('${appt['action_count'] ?? 0}')}\n'
                '${t.clinicRemindersCount('${appt['notification_count'] ?? 0}')}',
                style: const TextStyle(
                    color: NHSTheme.darkGrey, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          if (appt['needs_action'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(t.clinicNeedsOutreach,
                  style: const TextStyle(
                      color: NHSTheme.riskHigh, fontWeight: FontWeight.w800)),
            ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canNotify ? () => _scheduleReminder(appt) : null,
                icon: const Icon(Icons.notifications_active),
                label: Text(t.clinicReminder),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _recordCall(appt),
                icon: const Icon(Icons.call),
                label: Text(t.clinicCall),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
