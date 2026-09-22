import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'bible_service.dart';

class DailyVerseNotificationService {
  DailyVerseNotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'neno_la_leo_channel';
  static const String _channelName = 'Neno la Leo';
  static const String _channelDescription = 'Arifa ya kila siku ya Neno la Leo';

  /// Initialize local notifications.
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestNotificationPermission();
  }

  /// Ask for notification permission on supported Android versions.
  static Future<void> _requestNotificationPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
  }

  /// Called when the user taps the Neno la Leo notification.
  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    // For now, tapping the notification opens the application.
    // We can later make this navigate directly to the verse.
  }

  /// Schedule Neno la Leo notifications for upcoming days.
  ///
  /// Each date is calculated independently through BibleService, so the
  /// notification contains exactly the same Neno la Leo as the app.
  static Future<void> scheduleDailyVerseNotifications({
    int hour = 7,
    int minute = 0,
    int daysToSchedule = 30,
  }) async {
    // Remove previously scheduled Neno la Leo notifications before
    // rebuilding the schedule.
    await cancelScheduledDailyVerseNotifications();

    final DateTime now = DateTime.now();

    for (int i = 0; i < daysToSchedule; i++) {
      final DateTime date = DateTime(now.year, now.month, now.day + i);

      final DateTime scheduledDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );

      // Do not schedule a notification for a time that has already passed.
      if (scheduledDateTime.isBefore(now)) {
        continue;
      }

      final DailyBibleVerse verse = await BibleService.getVerseOfTheDay(
        date: date,
      );

      final tz.TZDateTime scheduledTime = tz.TZDateTime.from(
        scheduledDateTime,
        tz.local,
      );

      await _notifications.zonedSchedule(
        _notificationIdForDate(date),
        'Neno la Leo 📖',
        '${verse.verseText}\n\n${verse.reference}',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload:
            '${verse.bookName}|${verse.chapterNumber}|${verse.verseNumber}',
      );
    }
  }

  /// Cancel only the notification IDs reserved for Neno la Leo.
  static Future<void> cancelScheduledDailyVerseNotifications() async {
    final DateTime today = DateTime.now();

    // Clear a wide date range reserved by this feature.
    for (int i = -1; i <= 60; i++) {
      final DateTime date = DateTime(today.year, today.month, today.day + i);

      await _notifications.cancel(_notificationIdForDate(date));
    }
  }

  static int _notificationIdForDate(DateTime date) {
    // Example:
    // 2026-09-22 -> 260922
    return ((date.year % 100) * 10000) + (date.month * 100) + date.day;
  }
}
