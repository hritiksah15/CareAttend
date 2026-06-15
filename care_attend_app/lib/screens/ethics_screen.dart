import 'package:flutter/material.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';

class EthicsScreen extends StatefulWidget {
  const EthicsScreen({super.key});

  @override
  State<EthicsScreen> createState() => _EthicsScreenState();
}

class _EthicsScreenState extends State<EthicsScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = false;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.ethicsFramework();
      setState(() => _data = data);
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

  Color _statusColor(String status) {
    if (status.toLowerCase().startsWith('addressed')) return NHSTheme.riskLow;
    if (status.toLowerCase().startsWith('partial')) return NHSTheme.riskMedium;
    return NHSTheme.grey;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('Ethics Framework',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('NHS England (2024) six-principle mapping with evidence.',
              style: TextStyle(color: NHSTheme.darkGrey)),
          const SizedBox(height: 16),
          if (_loading) const Center(child: Padding(
              padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          if (_error != null)
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: NHSTheme.riskHigh)))),
          if (_data != null)
            ...((_data!['principles'] as List?) ?? []).map((p) => Card(
                  child: ExpansionTile(
                    leading: Icon(Icons.verified_user,
                        color: _statusColor('${p['status']}')),
                    title: Text('${p['principle']}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${p['status']}',
                        style: TextStyle(color: _statusColor('${p['status']}'))),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: ((p['evidence'] as List?) ?? [])
                              .map<Widget>((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('•  '),
                                        Expanded(child: Text('$e')),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
