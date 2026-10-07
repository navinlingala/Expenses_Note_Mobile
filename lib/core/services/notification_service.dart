import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._init();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz_data.initializeTimeZones();
      // Set India Standard Time (IST) as default location for reliable calculations
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        // Fallback to local default if Asia/Kolkata is missing
      }
    } catch (_) {}

    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      _isInitialized = true;
      return;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click
      },
    );

    // Create high-importance notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'money_reminder_channel_v2',
      'Payment & EMI Reminders',
      description: 'Channel for timely EMI and money payment alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      await requestPermissions();
    }

    _isInitialized = true;
  }

  /// Request permissions on Android 13+ and iOS
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final notifGranted = await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
        return notifGranted ?? false;
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return false;
  }

  /// Trigger instant notification (e.g. Test notification button)
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      debugPrint('[NotificationService Web]: $title - $body');
      return;
    }

    await initialize();
    await requestPermissions();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'money_reminder_channel_v2',
      'Payment & EMI Reminders',
      channelDescription: 'Immediate alerts for EMI and transactions',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.reminder,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('showInstantNotification error: $e');
    }
  }

  /// Schedule notification for a future time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    if (scheduledDate.isBefore(DateTime.now())) return;

    await initialize();

    try {
      final tzLocation = tz.local;
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tzLocation);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'money_reminder_channel_v2',
        'Payment & EMI Reminders',
        channelDescription: 'Alerts for upcoming EMIs and loan payments',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzScheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (_) {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzScheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Notification scheduling error bypassed safely: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }
}
