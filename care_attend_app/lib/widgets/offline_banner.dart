import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../nhs_theme.dart';
import '../services/api_service.dart';

/// App-wide connectivity indicator. Shows only while [ApiService.offline] is
/// true (set when a request fails for connectivity reasons, cleared on the next
/// successful request). Passive by design — per-screen pull-to-refresh and
/// re-tapping an action are the retry affordances.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: ApiService.offline,
      builder: (context, off, _) {
        if (!off) return const SizedBox.shrink();
        return Material(
          color: NHSTheme.riskHigh,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t.offlineBanner,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
