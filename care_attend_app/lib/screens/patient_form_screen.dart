import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../theme/design_tokens.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../widgets/ui.dart';

class PatientFormScreen extends StatefulWidget {
  final void Function(Map<String, dynamic>) onResult;
  const PatientFormScreen({super.key, required this.onResult});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final _ageCtrl = TextEditingController();
  final _leadTimeCtrl = TextEditingController();
  final _priorDNACtrl = TextEditingController();
  final _imdCtrl = TextEditingController();
  final _nhsCtrl = TextEditingController();
  bool _ehrLoading = false;

  int _gender = -1;
  bool _smsReceived = false;
  bool _hypertension = false;
  bool _diabetes = false;
  bool _alcoholism = false;
  bool _disability = false;

  String? _ageGroup;

  void _updateAgeGroup() {
    final age = int.tryParse(_ageCtrl.text);
    if (age != null && age >= 0 && age <= 120) {
      setState(() => _ageGroup = NHSTheme.ageGroup(age));
    } else {
      setState(() => _ageGroup = null);
    }
  }

  Future<void> _autofillEhr() async {
    final nhs = _nhsCtrl.text.trim();
    if (nhs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an NHS number (e.g. NHS001)')),
      );
      return;
    }
    setState(() => _ehrLoading = true);
    try {
      final res = await ApiService.ehrLookup(nhs);
      final p = (res['patient'] as Map?) ?? {};
      setState(() {
        if (p['Age'] != null) _ageCtrl.text = '${p['Age']}';
        if (p['Gender'] != null) _gender = p['Gender'] as int;
        if (p['IMDDecile'] != null) _imdCtrl.text = '${p['IMDDecile']}';
        if (p['PriorDNACount'] != null) {
          _priorDNACtrl.text = '${p['PriorDNACount']}';
        }
        _hypertension = (p['Hypertension'] ?? 0) == 1;
        _diabetes = (p['Diabetes'] ?? 0) == 1;
        _disability = (p['Disability'] ?? 0) == 1;
      });
      _updateAgeGroup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded ${p['name'] ?? nhs} from mock EHR')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('EHR lookup failed')),
      );
    } finally {
      if (mounted) setState(() => _ehrLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a gender')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiService.predict(
        age: int.parse(_ageCtrl.text),
        gender: _gender,
        leadTimeDays: int.parse(_leadTimeCtrl.text),
        smsReceived: _smsReceived ? 1 : 0,
        priorDNACount: int.parse(_priorDNACtrl.text),
        hypertension: _hypertension ? 1 : 0,
        diabetes: _diabetes ? 1 : 0,
        alcoholism: _alcoholism ? 1 : 0,
        disability: _disability ? 1 : 0,
        imdDecile: int.parse(_imdCtrl.text),
      );
      // Append to the session risk trajectory (FR-09).
      ApiService.riskHistory.add({
        'percentage': result['percentage'],
        'risk_tier': result['risk_tier'],
      });
      // Stash raw inputs so the Nudge screen can prefill from this assessment.
      ApiService.lastPatient = {
        'Age': int.parse(_ageCtrl.text),
        'Gender': _gender,
        'AppointmentLeadTimeDays': int.parse(_leadTimeCtrl.text),
        'SMSReceived': _smsReceived ? 1 : 0,
        'PriorDNACount': int.parse(_priorDNACtrl.text),
        'IMDDecile': int.parse(_imdCtrl.text),
        'Hypertension': _hypertension ? 1 : 0,
        'Diabetes': _diabetes ? 1 : 0,
        'Alcoholism': _alcoholism ? 1 : 0,
        'Disability': _disability ? 1 : 0,
      };
      widget.onResult(result);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _carerProxyDialog() async {
    final name = TextEditingController();
    final contact = TextEditingController();
    final patientId = TextEditingController();
    final reason = TextEditingController();
    String relationship = 'family';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Carer / Family Proxy'),
          insetPadding: const EdgeInsets.all(AppSpace.xl),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                      controller: name,
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(labelText: 'Carer name')),
                  const SizedBox(height: AppSpace.lg),
                  DropdownButtonFormField<String>(
                    initialValue: relationship,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Relationship'),
                    items: const [
                      DropdownMenuItem(value: 'family', child: Text('Family')),
                      DropdownMenuItem(
                          value: 'carer', child: Text('Registered carer')),
                      DropdownMenuItem(
                          value: 'social_worker',
                          child: Text('Social worker')),
                      DropdownMenuItem(
                          value: 'neighbour', child: Text('Neighbour')),
                      DropdownMenuItem(
                          value: 'volunteer', child: Text('Volunteer')),
                    ],
                    onChanged: (v) =>
                        setLocal(() => relationship = v ?? 'family'),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  TextField(
                      controller: patientId,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          labelText: 'Patient identifier')),
                  const SizedBox(height: AppSpace.lg),
                  TextField(
                      controller: contact,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          labelText: 'Carer contact (optional)')),
                  const SizedBox(height: AppSpace.lg),
                  TextField(
                      controller: reason,
                      maxLines: 2,
                      decoration:
                          const InputDecoration(labelText: 'Reason (optional)')),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
              AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 48)),
              onPressed: () async {
                if (name.text.trim().isEmpty ||
                    patientId.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Carer name and patient identifier required')));
                  return;
                }
                try {
                  await ApiService.createCarerProxy({
                    'carerName': name.text.trim(),
                    'relationship': relationship,
                    'patientIdentifier': patientId.text.trim(),
                    'carerContact': contact.text.trim(),
                    'reason': reason.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Carer proxy registered')));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.patientAssessment,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: NHSTheme.blue)),
                  const SizedBox(height: 4),
                  Text(t.assessmentIntro,
                      style: TextStyle(
                          fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),

                  // EHR AUTO-FILL
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NHSTheme.paleGrey,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: NHSTheme.lightBlue, width: 1),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _nhsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'NHS Number (e.g. NHS001)',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 44)),
                        onPressed: _ehrLoading ? null : _autofillEhr,
                        child: _ehrLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(t.autofill),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _carerProxyDialog,
                      icon: const Icon(Icons.people_outline, size: 18),
                      label: Text(t.carerProxy),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DEMOGRAPHICS
                  _sectionLabel(t.demographics),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(labelText: '${t.age} *'),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 0 || n > 120) {
                              return '0-120';
                            }
                            return null;
                          },
                          onChanged: (_) => _updateAgeGroup(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _gender == -1 ? null : _gender,
                          decoration:
                              InputDecoration(labelText: '${t.gender} *'),
                          items: [
                            DropdownMenuItem(value: 0, child: Text(t.female)),
                            DropdownMenuItem(value: 1, child: Text(t.male)),
                          ],
                          onChanged: (v) => setState(() => _gender = v ?? -1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // APPOINTMENT DETAILS
                  _sectionLabel(t.appointmentDetails),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _leadTimeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: '${t.leadTime} *'),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 0) return 'Required';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _priorDNACtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: '${t.priorDNA} *'),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 0) return 'Required';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCheckTile(t.smsReceived, _smsReceived,
                      (v) => setState(() => _smsReceived = v)),
                  const SizedBox(height: 20),

                  // CLINICAL FLAGS
                  _sectionLabel(t.clinicalFlags),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildCheckTile(t.hypertension, _hypertension,
                          (v) => setState(() => _hypertension = v)),
                      _buildCheckTile(t.diabetes, _diabetes,
                          (v) => setState(() => _diabetes = v)),
                      _buildCheckTile(t.alcoholism, _alcoholism,
                          (v) => setState(() => _alcoholism = v)),
                      _buildCheckTile(t.disability, _disability,
                          (v) => setState(() => _disability = v)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // SOCIAL CONTEXT
                  _sectionLabel(t.socialContext),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _imdCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        InputDecoration(labelText: '${t.imdDecile} *'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1 || n > 10) return '1-10';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Age group auto-display
                  if (_ageGroup != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: NHSTheme.paleGrey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(t.ageGroupLine(_ageGroup!),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                  const SizedBox(height: 16),

                  // Submit
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(t.assessRisk),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(8),
                border:
                    const Border(left: BorderSide(color: NHSTheme.lightBlue, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.aboutTool,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: NHSTheme.blue)),
                  const SizedBox(height: 6),
                  Text(t.aboutToolDesc,
                      style: TextStyle(
                          fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text(t.dataHandling,
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) =>
      AppCard(padding: const EdgeInsets.all(20), child: child);

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: NHSTheme.blue,
          letterSpacing: 0.5,
        ),
      );

  Widget _buildCheckTile(String label, bool value, ValueChanged<bool> onChanged) =>
      InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: NHSTheme.paleGrey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  activeColor: NHSTheme.blue,
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    _ageCtrl.dispose();
    _leadTimeCtrl.dispose();
    _priorDNACtrl.dispose();
    _imdCtrl.dispose();
    _nhsCtrl.dispose();
    super.dispose();
  }
}
