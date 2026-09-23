import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'bible_service.dart';

class DailyVerseNotificationTarget {
  const DailyVerseNotificationTarget({
    required this.bookName,
    required this.chapterNumber,
    required this.chapterCount,
    required this.verseNumber,
  });

  final String bookName;
  final int chapterNumber;
  final int chapterCount;
  final int verseNumber;
}

class DailyVerseNotificationService {
  DailyVerseNotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static void Function(DailyVerseNotificationTarget target)? onNotificationTap;
  static DailyVerseNotificationTarget? _pendingTarget;

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

    final NotificationAppLaunchDetails? launchDetails = await _notifications
        .getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _storeOrOpenPayload(launchDetails?.notificationResponse?.payload);
    }

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
    _storeOrOpenPayload(notificationResponse.payload);
  }

  static void _storeOrOpenPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return;
    }

    final List<String> parts = payload.split('|');

    // Current payload format:
    // bookName|chapterNumber|chapterCount|verseNumber
    if (parts.length != 4) {
      return;
    }

    final int? chapterNumber = int.tryParse(parts[1]);
    final int? chapterCount = int.tryParse(parts[2]);
    final int? verseNumber = int.tryParse(parts[3]);

    if (chapterNumber == null || chapterCount == null || verseNumber == null) {
      return;
    }

    final DailyVerseNotificationTarget target = DailyVerseNotificationTarget(
      bookName: parts[0],
      chapterNumber: chapterNumber,
      chapterCount: chapterCount,
      verseNumber: verseNumber,
    );

    final handler = onNotificationTap;

    if (handler != null) {
      handler(target);
    } else {
      _pendingTarget = target;
    }
  }

  /// Opens a notification that launched the app once normal app navigation
  /// is ready (after the splash screen has opened HomeScreen).
  static void openPendingNotification() {
    final DailyVerseNotificationTarget? target = _pendingTarget;
    final handler = onNotificationTap;

    if (target == null || handler == null) {
      return;
    }

    _pendingTarget = null;
    handler(target);
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
            '${verse.bookName}|${verse.chapterNumber}|${verse.chapterCount}|${verse.verseNumber}',
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
