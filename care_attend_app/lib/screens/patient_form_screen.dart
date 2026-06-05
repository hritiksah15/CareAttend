import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';

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

  @override
  Widget build(BuildContext context) {
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
                  const Text('Patient Risk Assessment',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: NHSTheme.blue)),
                  const SizedBox(height: 4),
                  const Text(
                      'Enter patient details to generate a DNA risk prediction with explainable AI outputs.',
                      style:
                          TextStyle(fontSize: 14, color: NHSTheme.darkGrey)),
                  const SizedBox(height: 20),

                  // DEMOGRAPHICS
                  _sectionLabel('DEMOGRAPHICS'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Age (0-120) *'),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 0 || n > 120)
                              return '0-120';
                            return null;
                          },
                          onChanged: (_) => _updateAgeGroup(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _gender == -1 ? null : _gender,
                          decoration:
                              const InputDecoration(labelText: 'Gender *'),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Female')),
                            DropdownMenuItem(value: 1, child: Text('Male')),
                          ],
                          onChanged: (v) => setState(() => _gender = v ?? -1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // APPOINTMENT DETAILS
                  _sectionLabel('APPOINTMENT DETAILS'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _leadTimeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Lead Time (days) *'),
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
                          decoration: const InputDecoration(
                              labelText: 'Prior DNA Count *'),
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
                  _buildCheckTile('SMS Reminder Received', _smsReceived,
                      (v) => setState(() => _smsReceived = v)),
                  const SizedBox(height: 20),

                  // CLINICAL FLAGS
                  _sectionLabel('CLINICAL FLAGS'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildCheckTile('Hypertension', _hypertension,
                          (v) => setState(() => _hypertension = v)),
                      _buildCheckTile('Diabetes', _diabetes,
                          (v) => setState(() => _diabetes = v)),
                      _buildCheckTile('Alcoholism', _alcoholism,
                          (v) => setState(() => _alcoholism = v)),
                      _buildCheckTile('Disability', _disability,
                          (v) => setState(() => _disability = v)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // SOCIAL CONTEXT
                  _sectionLabel('SOCIAL CONTEXT'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _imdCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'IMD Decile (1-10) *'),
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
                      child: Text('Age Group: $_ageGroup (auto-calculated)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, color: NHSTheme.darkGrey)),
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
                        : const Text('ASSESS RISK'),
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About This Tool',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: NHSTheme.blue)),
                  SizedBox(height: 6),
                  Text(
                      'Care Attend uses machine learning to predict DNA risk. Predictions explained via SHAP. System monitors for demographic bias.',
                      style:
                          TextStyle(fontSize: 13, color: NHSTheme.darkGrey)),
                  SizedBox(height: 6),
                  Text(
                      'Data Handling: No patient data stored. Session-scoped only. GDPR Art 5(1)(c) compliant.',
                      style: TextStyle(
                          fontSize: 13,
                          color: NHSTheme.darkGrey,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) => Container(
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
    super.dispose();
  }
}
