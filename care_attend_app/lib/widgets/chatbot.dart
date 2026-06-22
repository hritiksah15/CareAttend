import 'package:flutter/material.dart';
import '../nhs_theme.dart';

/// Floating AI assistant — keyword Q&A ported from the website's
/// getChatbotResponse (HTML stripped to plain text).
class ChatbotOverlay extends StatefulWidget {
  const ChatbotOverlay({super.key});

  @override
  State<ChatbotOverlay> createState() => _ChatbotOverlayState();
}

class _Msg {
  final String text;
  final bool fromUser;
  _Msg(this.text, this.fromUser);
}

class _ChatbotOverlayState extends State<ChatbotOverlay> {
  bool _open = false;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [
    _Msg('Hi! I am the Care Attend assistant. Ask me about assessment, SHAP, '
        'bias, batch upload, slots, nudge, 2FA, carer proxy, and more.', false),
  ];

  String _reply(String query) {
    final q = query.toLowerCase();
    if (q.contains('assess') || q.contains('predict') || q.contains('risk')) {
      return 'To assess a patient, open the Assessment tab. Fill in demographics, '
          'appointment details, clinical flags and IMD decile, then tap Assess Risk '
          'for a DNA prediction with SHAP explanations and interventions.';
    } else if (q.contains('shap') || q.contains('explain')) {
      return 'SHAP shows which factors drove the prediction. Green reduces risk, '
          'red increases it — a personalised explanation, not a black box.';
    } else if (q.contains('bias') || q.contains('fair')) {
      return 'The Bias Monitor audits fairness across age, gender and IMD using '
          'demographic parity and equalised odds at a 0.10 threshold (admin only).';
    } else if (q.contains('privacy') || q.contains('gdpr') || q.contains('data')) {
      return 'Care Attend is GDPR Article 5(1)(c) compliant. No patient data is '
          'stored — predictions are session-scoped. Passwords use bcrypt.';
    } else if (q.contains('batch') || q.contains('csv') || q.contains('upload')) {
      return 'The Batch Upload tab scores a CSV of up to 100 patients. Columns: '
          'Age, Gender, AppointmentLeadTimeDays, SMSReceived, PriorDNACount, IMDDecile.';
    } else if (q.contains('slot') || q.contains('overbook')) {
      return 'Slot Optimisation flags appointments with 40%+ DNA risk as '
          'overbookable so a no-show does not waste a slot.';
    } else if (q.contains('nudge') || q.contains('message')) {
      return 'Patient Nudge generates personalised, non-stigmatising messages in '
          'English, Welsh, Urdu or Polish based on the risk profile.';
    } else if (q.contains('2fa') || q.contains('two-factor') || q.contains('authenticator')) {
      return 'Enable 2FA in Personal Account. It uses TOTP — Google Authenticator, '
          'Authy or any TOTP app. You then need the 6-digit code to log in.';
    } else if (q.contains('proxy') || q.contains('carer')) {
      return 'Carer Proxy lets a family member or carer enter data for digitally '
          'excluded patients, from the Assessment tab.';
    } else if (q.contains('tour') || q.contains('guide') || q.contains('help')) {
      return 'Tap the help (?) icon in the top bar to start the guided tour of the '
          'features available to your role.';
    }
    return 'I can help with: assessment, SHAP, bias, batch upload, slots, nudge, '
        '2FA, carer proxy and more. What would you like to know?';
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text, true));
      _messages.add(_Msg(_reply(text), false));
      _input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_open) _panel(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FloatingActionButton(
            heroTag: 'chatbot',
            backgroundColor: NHSTheme.blue,
            onPressed: () => setState(() => _open = !_open),
            child: Icon(_open ? Icons.close : Icons.smart_toy,
                color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _panel() {
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 84),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 320,
          height: 420,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: NHSTheme.blue,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(children: const [
                Icon(Icons.smart_toy, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Care Attend AI',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i];
                  return Align(
                    alignment: m.fromUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(maxWidth: 240),
                      decoration: BoxDecoration(
                        color: m.fromUser
                            ? NHSTheme.blue
                            : NHSTheme.paleGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(m.text,
                          style: TextStyle(
                              fontSize: 13,
                              color: m.fromUser
                                  ? Colors.white
                                  : NHSTheme.black)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: NHSTheme.blue),
                  onPressed: _send,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
