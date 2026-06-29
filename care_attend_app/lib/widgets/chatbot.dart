import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';

/// Floating role-aware assistant for Care Attend workflows.
///
/// The web assistant uses the same feature catalogue and wording style. Keep
/// this widget deterministic: it is a product guide, not a clinical chatbot.
class ChatbotOverlay extends StatefulWidget {
  const ChatbotOverlay({super.key});

  @override
  State<ChatbotOverlay> createState() => _ChatbotOverlayState();
}

class _FeatureGuide {
  final String id;
  final String title;
  final IconData icon;
  final List<String> roles;
  final String summary;
  final List<String> steps;
  final List<String> fixes;
  final List<String> terms;

  const _FeatureGuide({
    required this.id,
    required this.title,
    required this.icon,
    required this.roles,
    required this.summary,
    required this.steps,
    required this.fixes,
    required this.terms,
  });
}

class _GuideCard {
  final IconData icon;
  final String title;
  final String label;
  final String summary;
  final List<String> points;
  final bool locked;

  const _GuideCard({
    required this.icon,
    required this.title,
    required this.label,
    required this.summary,
    required this.points,
    this.locked = false,
  });
}

class _BotReply {
  final String text;
  final List<_GuideCard> cards;
  final List<String> chips;

  const _BotReply(this.text,
      {this.cards = const <_GuideCard>[], this.chips = const <String>[]});
}

class _Msg {
  final String text;
  final bool fromUser;
  final List<_GuideCard> cards;
  final List<String> chips;

  const _Msg(this.text, this.fromUser,
      {this.cards = const <_GuideCard>[], this.chips = const <String>[]});
}

class _ChatbotOverlayState extends State<ChatbotOverlay> {
  static const _allRoles = ['user', 'staff', 'admin'];
  static const _features = <_FeatureGuide>[
    _FeatureGuide(
      id: 'assessment',
      title: 'Patient Assessment',
      icon: Icons.assignment_outlined,
      roles: _allRoles,
      summary:
          'Enter appointment, demographic, access and clinical flags, then run the DNA risk model.',
      steps: [
        'Open Patient Assessment.',
        'Complete age, gender, lead time, SMS, prior DNA count, IMD and clinical flags.',
        'Use Carer Proxy when a family member or carer enters data for a digitally excluded patient.',
        'Tap Assess Risk to generate risk tier, SHAP drivers, outreach priority and interventions.',
      ],
      fixes: [
        'If the button will not submit, check every required input and numeric range.',
        'If the server cannot be reached, restart the stack and check the backend.',
      ],
      terms: [
        'assess',
        'assessment',
        'predict',
        'prediction',
        'risk',
        'carer',
        'proxy'
      ],
    ),
    _FeatureGuide(
      id: 'results',
      title: 'Risk Results',
      icon: Icons.monitor_heart_outlined,
      roles: _allRoles,
      summary:
          'Shows DNA probability, risk tier, outreach priority, SHAP drivers, interventions and exports.',
      steps: [
        'Run an assessment first.',
        'Read the risk gauge and tier.',
        'Review Outreach Priority: P1 urgent contact, P2 targeted reminder, P3 routine reminder.',
        'Use SHAP bars to explain strongest drivers without treating them as a diagnosis.',
        'Staff and admins can export CSV, JSON, PDF and summary reports.',
      ],
      fixes: [
        'If no result appears, return to Assessment and run a prediction.',
        'If export is hidden, your role does not have export permission.',
      ],
      terms: [
        'result',
        'results',
        'shap',
        'explain',
        'driver',
        'intervention',
        'export',
        'pdf'
      ],
    ),
    _FeatureGuide(
      id: 'dashboard',
      title: 'Practice Dashboard',
      icon: Icons.dashboard_outlined,
      roles: ['staff', 'admin'],
      summary:
          'Operational view of recent assessments, risk mix and quick entry into clinic workflows.',
      steps: [
        'Open Dashboard.',
        'Refresh current practice metrics.',
        'Use recent assessments to move into clinic or nudge workflows.',
      ],
      fixes: ['If it is hidden, ask an admin for staff or admin access.'],
      terms: ['dashboard', 'metrics', 'recent assessment'],
    ),
    _FeatureGuide(
      id: 'clinic',
      title: 'Clinic List',
      icon: Icons.event_note_outlined,
      roles: ['staff', 'admin'],
      summary:
          'Create, import and manage clinic appointments with risk-aware reminder actions.',
      steps: [
        'Open Clinic List.',
        'Choose date and clinic, then add or import appointments.',
        'Review risk badges, update attendance status, and trigger reminders or calls.',
      ],
      fixes: [
        'If rows do not load, check the date and clinic filter.',
        'Use valid JSON for import and keep patient IDs unique.',
      ],
      terms: ['clinic', 'appointment', 'attendance', 'reminder', 'call'],
    ),
    _FeatureGuide(
      id: 'batch',
      title: 'Batch Upload',
      icon: Icons.upload_file_outlined,
      roles: ['staff', 'admin'],
      summary:
          'Score up to 100 patients from a CSV and export triage-ready results.',
      steps: [
        'Open Batch Upload.',
        'Download the template or use a Batch CSV export from a completed assessment.',
        'Required columns: Age, Gender, AppointmentLeadTimeDays, SMSReceived, PriorDNACount, IMDDecile.',
        'Optional columns: Hypertension, Diabetes, Alcoholism and Disability.',
      ],
      fixes: [
        'Do not upload the PDF/report CSV; use the batch template format.',
        'Check header spelling and keep the file below 100 rows.',
      ],
      terms: ['batch', 'csv', 'upload', 'template'],
    ),
    _FeatureGuide(
      id: 'slots',
      title: 'Slot Optimisation',
      icon: Icons.calendar_month_outlined,
      roles: ['staff', 'admin'],
      summary:
          'Flags slots with 40%+ DNA probability as overbook candidates to reduce wasted capacity.',
      steps: [
        'Open Slots.',
        'Paste appointment JSON.',
        'Run analysis and review overbook candidates with expected waste.',
      ],
      fixes: [
        'Use valid JSON and include slot duration and DNA probability inputs.'
      ],
      terms: ['slot', 'slots', 'overbook', 'capacity', 'waste'],
    ),
    _FeatureGuide(
      id: 'nudge',
      title: 'Patient Nudge',
      icon: Icons.sms_outlined,
      roles: ['staff', 'admin'],
      summary:
          'Generates personalised, non-stigmatising reminders in English, Welsh, Urdu or Polish.',
      steps: [
        'Fill an assessment first so patient context is available.',
        'Open Patient Nudge.',
        'Pick language and generate a message.',
        'Copy the message into the approved clinic communication channel.',
      ],
      fixes: [
        'If context is missing, return to Assessment and run the patient first.'
      ],
      terms: [
        'nudge',
        'message',
        'sms',
        'patient comms',
        'language',
        'welsh',
        'urdu',
        'polish'
      ],
    ),
    _FeatureGuide(
      id: 'bias',
      title: 'Bias Monitor',
      icon: Icons.balance_outlined,
      roles: ['admin'],
      summary:
          'Runs fairness checks across age, gender and IMD using demographic parity and equalised odds.',
      steps: [
        'Open Bias Monitor.',
        'Run the audit across age, gender or IMD.',
        'Review amber/red groups and export governance evidence.',
      ],
      fixes: ['If it is hidden, the signed-in account is not an admin.'],
      terms: [
        'bias',
        'fair',
        'fairness',
        'demographic parity',
        'equalised odds'
      ],
    ),
    _FeatureGuide(
      id: 'ethics',
      title: 'Ethics Framework',
      icon: Icons.verified_user_outlined,
      roles: ['admin'],
      summary:
          'Maps the product to NHS AI ethics, safety, transparency, privacy and accountability controls.',
      steps: [
        'Open Ethics.',
        'Load the framework mapping.',
        'Use evidence cards for governance and AT2 write-up alignment.',
      ],
      fixes: ['If it is hidden, admin access is required.'],
      terms: ['ethics', 'governance', 'framework', 'nhsx', 'safety'],
    ),
    _FeatureGuide(
      id: 'admin',
      title: 'Admin Console',
      icon: Icons.admin_panel_settings_outlined,
      roles: ['admin'],
      summary: 'Manage users, approvals, roles and session audit logs.',
      steps: [
        'Open Admin.',
        'Approve pending users and set the least-privilege role.',
        'Review session logs for login/logout and account activity.',
      ],
      fixes: [
        'Only admins can operate this area; backend enforcement still applies.'
      ],
      terms: [
        'admin',
        'approve',
        'role',
        'user management',
        'session log',
        'audit log'
      ],
    ),
    _FeatureGuide(
      id: 'profile',
      title: 'Account Centre',
      icon: Icons.person_outline,
      roles: _allRoles,
      summary:
          'Update profile details, avatar and security settings including TOTP 2FA.',
      steps: [
        'Open Personal Account from the top bar.',
        'Edit profile details or avatar.',
        'Use Security to enable or disable 2FA.',
      ],
      fixes: [
        'If 2FA setup fails, confirm the 6-digit TOTP code before it expires.'
      ],
      terms: [
        'profile',
        'account',
        '2fa',
        'two-factor',
        'authenticator',
        'password',
        'avatar'
      ],
    ),
    _FeatureGuide(
      id: 'guidelines',
      title: 'Clinical Use Guidelines',
      icon: Icons.menu_book_outlined,
      roles: _allRoles,
      summary:
          'Care Attend is decision support. It prioritises outreach; it does not replace clinical judgement.',
      steps: [
        'Use risk and priority to decide who needs proactive contact first.',
        'Do not describe patients as unreliable; use non-stigmatising language.',
        'Check age group and active disease flags together.',
        'Keep patient data minimised and session-scoped.',
      ],
      fixes: [
        'If model output conflicts with known clinical context, escalate to staff judgement and document why.',
      ],
      terms: [
        'guideline',
        'guidelines',
        'how it works',
        'workflow',
        'safe use',
        'clinical judgement'
      ],
    ),
  ];

  bool _open = false;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.add(_Msg(_welcomeText(), false, chips: const [
      'What can I do?',
      'How do I assess a patient?',
      'Explain outreach priority',
      'Fix a problem',
    ]));
  }

  String get _role => ApiService.role;

  String get _roleLabel {
    switch (_role) {
      case 'admin':
        return 'administrator';
      case 'staff':
        return 'clinic staff';
      default:
        return 'patient-facing user';
    }
  }

  bool _canUse(_FeatureGuide feature) => feature.roles.contains(_role);

  String _rolesText(List<String> roles) {
    if (roles.length == 3) return 'all roles';
    return roles.join(' / ');
  }

  List<_FeatureGuide> get _visibleFeatures =>
      _features.where(_canUse).toList(growable: false);

  _FeatureGuide? _findFeature(String q) {
    for (final feature in _features) {
      if (feature.terms.any(q.contains)) return feature;
    }
    return null;
  }

  bool _hasAny(String q, List<String> terms) => terms.any(q.contains);

  String _welcomeText() =>
      'Hi! I am your Care Attend assistant for the $_roleLabel role. '
      'Ask about features, icons, cards, results, outreach priority, guidelines, or fixing a workflow problem.';

  _GuideCard _cardFromFeature(_FeatureGuide feature,
      {bool locked = false, bool fixes = false}) {
    return _GuideCard(
      icon: feature.icon,
      title: feature.title,
      label: locked
          ? 'Locked for $_roleLabel'
          : 'Available to ${_rolesText(feature.roles)}',
      summary: feature.summary,
      points: fixes ? feature.fixes : feature.steps,
      locked: locked,
    );
  }

  _BotReply _overviewReply() {
    return _BotReply(
      'You are signed in as $_roleLabel. I will show the workflows your role can operate and explain locked tools clearly.',
      cards: _visibleFeatures
          .where((f) => f.id != 'guidelines')
          .map(_cardFromFeature)
          .toList(growable: false),
      chips: const [
        'How do I assess a patient?',
        'Explain outreach priority',
        'Fix a problem',
        'What can admins do?',
      ],
    );
  }

  _BotReply _featureReply(_FeatureGuide feature) {
    if (!_canUse(feature)) {
      return _BotReply(
        '${feature.title} is available to ${_rolesText(feature.roles)}. '
        'Your current role is $_roleLabel.',
        cards: [_cardFromFeature(feature, locked: true)],
        chips: const ['What can I do?', 'Role permissions'],
      );
    }
    return _BotReply(feature.summary, cards: [_cardFromFeature(feature)]);
  }

  _BotReply _priorityReply() {
    return const _BotReply(
      'Best priority method: use disease and age group together, plus DNA risk and access barriers. Disease-only misses age vulnerability; age-only misses clinical complexity.',
      cards: [
        _GuideCard(
          icon: Icons.notification_important_outlined,
          title: 'Outreach Priority',
          label: 'Risk + disease + age group',
          summary:
              'Priority ranks outreach urgency. It supports clinical workflow; it does not replace judgement.',
          points: [
            'P1: highest priority. Proactive contact, call-first workflow, transport/access support where relevant.',
            'P2: targeted reminder. Use language-aware nudge and check practical barriers.',
            'P3: routine reminder. Standard SMS or normal clinic pathway.',
            'Drivers can include predicted DNA risk, active disease flags, age vulnerability, prior DNA history, disability and access barriers.',
          ],
        ),
      ],
      chips: ['Explain SHAP', 'Clinical guidelines'],
    );
  }

  _BotReply _privacyReply() {
    return const _BotReply(
      'Care Attend keeps patient prediction data session-scoped and minimised.',
      cards: [
        _GuideCard(
          icon: Icons.lock_outline,
          title: 'Privacy and Security',
          label: 'GDPR and account safety',
          summary: 'Account data is separate from patient risk input.',
          points: [
            'Passwords are hashed with bcrypt.',
            'Sessions expire after inactivity.',
            '2FA uses TOTP from Personal Account > Security.',
            'No third-party analytics are used.',
            'Only staff/admin roles can export patient result data.',
          ],
        ),
      ],
    );
  }

  _BotReply _roleReply() {
    return _BotReply(
      'Your current role is $_roleLabel. Hidden tabs are intentional, and the backend enforces the same permissions.',
      cards: const [
        _GuideCard(
          icon: Icons.people_alt_outlined,
          title: 'Role Permissions',
          label: 'Least privilege',
          summary: 'Each role sees the tools needed for its workflow.',
          points: [
            'User: Assessment, Results, Personal Account, 2FA and guided help.',
            'Staff: User tools plus Dashboard, Clinic List, Batch Upload, Slots and Patient Nudge.',
            'Admin: Staff tools plus Bias Monitor, Ethics, Admin Console and session audit logs.',
          ],
        ),
      ],
    );
  }

  _BotReply _guidelinesReply() {
    final cards = ['guidelines', 'assessment', 'results', 'nudge']
        .map((id) => _features.firstWhere((f) => f.id == id))
        .map((feature) => _cardFromFeature(feature, locked: !_canUse(feature)))
        .toList(growable: false);
    return _BotReply(
      'How it works: collect minimum necessary appointment and vulnerability signals, score DNA risk, explain drivers with SHAP, then prioritise outreach using risk + disease + age group + access barriers.',
      cards: cards,
      chips: const ['Explain outreach priority', 'Fix a problem'],
    );
  }

  _BotReply _troubleshootingReply(String q) {
    final cards = <_GuideCard>[
      const _GuideCard(
        icon: Icons.wifi_off_outlined,
        title: 'App or API not responding',
        label: 'Problem-solving',
        summary:
            'Restart the local stack and verify the three expected services.',
        points: [
          'Run ./start_all.sh.',
          'Backend/website should answer on 127.0.0.1:5000.',
          'pgweb should answer on localhost:8081.',
          'Flutter web should answer on localhost:8090.',
          'Hard refresh if the browser kept an old cached bundle.',
        ],
      ),
      const _GuideCard(
        icon: Icons.fact_check_outlined,
        title: 'Assessment result missing',
        label: 'Problem-solving',
        summary: 'The Results view needs a successful assessment first.',
        points: [
          'Return to Patient Assessment.',
          'Check required values and valid ranges.',
          'Run Assess Risk again.',
          'If risk appears but exports are hidden, your role is user; staff/admin export only.',
        ],
      ),
      const _GuideCard(
        icon: Icons.file_present_outlined,
        title: 'Batch CSV rejected',
        label: 'Problem-solving',
        summary:
            'Batch upload accepts the template schema, not a PDF/report export.',
        points: [
          'Download the batch template.',
          'Required headers: Age, Gender, AppointmentLeadTimeDays, SMSReceived, PriorDNACount, IMDDecile.',
          'Keep rows at 100 or fewer.',
          'Use 0/1 values for binary flags.',
        ],
      ),
      const _GuideCard(
        icon: Icons.shield_outlined,
        title: 'Feature hidden or locked',
        label: 'Role-based access',
        summary: 'Role-based access hides tools that are outside your role.',
        points: [
          'User: assessment and results.',
          'Staff: clinic operations, dashboard, batch, slots and nudge.',
          'Admin: governance, bias, ethics, user management and audit logs.',
          'Ask an admin for the least-privilege role needed for your work.',
        ],
      ),
    ];
    if (_hasAny(q, ['slow', 'jank', 'blank'])) {
      cards.insert(
        0,
        const _GuideCard(
          icon: Icons.speed_outlined,
          title: 'Slow or blank UI',
          label: 'Runtime triage',
          summary:
              'Most runtime slowness comes from stale servers, disabled browser graphics acceleration, or old cached bundles.',
          points: [
            'Restart with ./start_all.sh.',
            'Hard refresh the browser.',
            'Enable browser graphics acceleration for CanvasKit.',
            'Check the console for layout or permission errors.',
          ],
        ),
      );
    }
    return _BotReply('Here is the fastest triage path for the issue.',
        cards: cards, chips: const ['What can I do?', 'Role permissions']);
  }

  _BotReply _reply(String query) {
    final q = query.toLowerCase();
    if (_hasAny(q, [
      'problem',
      'fix',
      'issue',
      'error',
      'not working',
      'blank',
      'slow',
      'stuck',
      'fail',
      'cannot',
      'can not',
    ])) {
      return _troubleshootingReply(q);
    }
    if (_hasAny(q, [
      'priority',
      'p1',
      'p2',
      'p3',
      'disease',
      'age group',
      'age-group',
      'outreach',
    ])) {
      return _priorityReply();
    }
    if (_hasAny(q, [
      'privacy',
      'gdpr',
      'data',
      'security',
      '2fa',
      'two-factor',
      'authenticator'
    ])) {
      return _privacyReply();
    }
    if (_hasAny(q, [
      'role',
      'permission',
      'access',
      'locked',
      'what can admins do',
      'what can staff do',
      'what can users do',
    ])) {
      return _roleReply();
    }
    if (_hasAny(q, [
      'how it works',
      'guideline',
      'guidelines',
      'workflow',
      'safe use',
      'clinical judgement',
      'help',
    ])) {
      return _guidelinesReply();
    }
    if (_hasAny(q, [
      'what can i do',
      'features',
      'functions',
      'menu',
      'everything',
      'cards',
      'icons'
    ])) {
      return _overviewReply();
    }

    final feature = _findFeature(q);
    if (feature != null) return _featureReply(feature);

    if (_hasAny(q, ['hello', 'hi', 'hey'])) {
      return _BotReply(_welcomeText(), chips: const [
        'What can I do?',
        'Explain outreach priority',
        'Fix a problem',
      ]);
    }
    return _overviewReply();
  }

  void _sendText(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final reply = _reply(clean);
    setState(() {
      _messages.add(_Msg(clean, true));
      _messages
          .add(_Msg(reply.text, false, cards: reply.cards, chips: reply.chips));
      _input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _send() => _sendText(_input.text);

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_open) _panel(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FloatingActionButton(
            heroTag: 'chatbot',
            backgroundColor: NHSTheme.blue,
            tooltip: t.chatbotAssistant,
            onPressed: () => setState(() => _open = !_open),
            child: Icon(_open ? Icons.close : Icons.smart_toy,
                color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _panel() {
    final size = MediaQuery.sizeOf(context);
    final panelWidth = (size.width - 32).clamp(240.0, 360.0).toDouble();
    final panelHeight = (size.height - 140).clamp(300.0, 480.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 84, left: 16),
      child: Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: panelWidth,
          height: panelHeight,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: NHSTheme.blue,
              child: Row(children: [
                const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).chatbotTitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      Text(_roleLabel,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _message(_messages[i], panelWidth),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    onSubmitted: (_) => _send(),
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).chatbotHint,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send,
                      color: Theme.of(context).colorScheme.primary),
                  tooltip: AppLocalizations.of(context).chatbotSend,
                  onPressed: _send,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _message(_Msg message, double panelWidth) {
    final maxWidth = message.fromUser ? panelWidth * 0.78 : panelWidth - 20;
    final bubbleColor = message.fromUser
        ? NHSTheme.blue
        : NHSTheme.calloutBg(context, NHSTheme.paleGrey);
    final textColor = message.fromUser
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment:
          message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: message.fromUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(message.text,
                style: TextStyle(fontSize: 13, height: 1.35, color: textColor)),
            for (final card in message.cards) _guideCard(card),
            if (message.chips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final chip in message.chips)
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(chip, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _sendText(chip),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _guideCard(_GuideCard card) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = card.locked ? colorScheme.outline : colorScheme.primary;
    final surface = Theme.of(context).brightness == Brightness.dark
        ? colorScheme.surfaceContainerHigh
        : Colors.white;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(card.icon, size: 17, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(card.title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary)),
              Text(card.label,
                  style: TextStyle(
                      fontSize: 11, color: colorScheme.onSurfaceVariant)),
            ]),
          ),
        ]),
        const SizedBox(height: 7),
        Text(card.summary,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface)),
        const SizedBox(height: 6),
        for (final point in card.points)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('- ',
                  style: TextStyle(fontSize: 12, color: colorScheme.primary)),
              Expanded(
                child: Text(point,
                    style:
                        TextStyle(fontSize: 12, color: colorScheme.onSurface)),
              ),
            ]),
          ),
      ]),
    );
  }
}
