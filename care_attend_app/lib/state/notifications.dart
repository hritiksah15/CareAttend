import 'package:flutter/material.dart';

/// Kind of notification — drives icon/colour and lets the UI distinguish a
/// security alert from a routine activity update.
enum NotifKind { info, activity, security }

class AppNotification {
  final String title;
  final String body;
  final NotifKind kind;
  final DateTime time;
  AppNotification(this.title, this.body, this.kind) : time = DateTime.now();

  IconData get icon {
    switch (kind) {
      case NotifKind.security:
        return Icons.shield_outlined;
      case NotifKind.activity:
        return Icons.assignment_turned_in_outlined;
      case NotifKind.info:
        return Icons.info_outline;
    }
  }
}

/// Session-scoped, in-memory notification feed. Cleared on logout/app close —
/// no persistence (matches the app's "no patient data stored" posture).
class Notifications {
  Notifications._();

  static final ValueNotifier<List<AppNotification>> items =
      ValueNotifier<List<AppNotification>>([]);

  /// Push newest-first; cap to avoid unbounded growth in a long session.
  static void push(String title, String body, NotifKind kind) {
    final next = [AppNotification(title, body, kind), ...items.value];
    if (next.length > 30) next.removeRange(30, next.length);
    items.value = next;
  }

  static void clear() => items.value = [];
}
