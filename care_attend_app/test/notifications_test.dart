import 'package:flutter_test/flutter_test.dart';
import 'package:care_attend_app/state/notifications.dart';

/// Unit tests for the session notification feed.
void main() {
  setUp(Notifications.clear);

  test('push adds newest-first', () {
    Notifications.push('A', 'a', NotifKind.info);
    Notifications.push('B', 'b', NotifKind.activity);
    expect(Notifications.items.value.first.title, 'B');
    expect(Notifications.items.value.length, 2);
  });

  test('clear empties the feed', () {
    Notifications.push('A', 'a', NotifKind.security);
    Notifications.clear();
    expect(Notifications.items.value, isEmpty);
  });

  test('feed is capped at 30', () {
    for (var i = 0; i < 40; i++) {
      Notifications.push('n$i', 'b', NotifKind.info);
    }
    expect(Notifications.items.value.length, 30);
    // newest retained, oldest dropped
    expect(Notifications.items.value.first.title, 'n39');
  });

  test('kind drives a distinct icon', () {
    final security = AppNotification('s', 'b', NotifKind.security);
    final activity = AppNotification('a', 'b', NotifKind.activity);
    expect(security.icon == activity.icon, isFalse);
  });
}
