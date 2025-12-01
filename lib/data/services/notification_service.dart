import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../domain/entities/task.dart';

/// Service for managing local notifications
/// Handles task reminders and notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Function(String?)? _onNotificationTapped;

  /// Initialize the notification service
  Future<void> initialize({Function(String?)? onNotificationTapped}) async {
    if (_initialized) return;

    _onNotificationTapped = onNotificationTapped;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // macOS initialization settings
    const macosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macosSettings,
    );

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTapped,
    );

    // Request permissions for iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _requestIOSPermissions();
    }

    // Request permissions for macOS
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      await _requestMacOSPermissions();
    }

    // Request permissions for Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _requestAndroidPermissions();
    }

    _initialized = true;
    debugPrint('NotificationService: Initialized successfully');
  }

  /// Request iOS notification permissions
  Future<void> _requestIOSPermissions() async {
    debugPrint('NotificationService: Requesting iOS permissions...');
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    debugPrint('NotificationService: iOS permissions requested');
  }

  /// Request macOS notification permissions
  Future<void> _requestMacOSPermissions() async {
    debugPrint('NotificationService: Requesting macOS permissions...');
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    debugPrint('NotificationService: macOS permissions requested');
  }

  /// Request Android notification permissions (Android 13+)
  Future<void> _requestAndroidPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.requestNotificationsPermission();
  }

  /// Handle notification tap
  void _handleNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    _onNotificationTapped?.call(response.payload);
  }

  /// Schedule a notification for a task
  Future<void> scheduleTaskReminder({
    required Task task,
    Duration? beforeDueDate,
  }) async {
    debugPrint('NotificationService: Scheduling reminder for task "${task.title}"');
    
    if (!_initialized) {
      debugPrint('NotificationService: Not initialized, skipping notification');
      return;
    }

    try {
      // Calculate notification time
      final reminderTime = beforeDueDate != null
          ? task.dueDate.subtract(beforeDueDate)
          : task.dueDate.subtract(const Duration(hours: 1));

      debugPrint('NotificationService: Task due: ${task.dueDate}');
      debugPrint('NotificationService: Reminder time: $reminderTime');

      // Don't schedule if the time has passed
      if (reminderTime.isBefore(DateTime.now())) {
        debugPrint('NotificationService: Reminder time has passed, skipping');
        return;
      }

      // Convert to timezone-aware datetime
      final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

      // Notification details
      final androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for upcoming tasks',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_launcher',
        enableLights: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification
      await _notificationsPlugin.zonedSchedule(
        task.id, // Use task ID as notification ID
        'Task Reminder: ${task.title}',
        task.description ?? 'Due soon',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'task_${task.id}',
      );

      debugPrint(
        'NotificationService: Scheduled reminder for task ${task.id} at $scheduledDate',
      );
    } catch (e) {
      debugPrint('NotificationService: Error scheduling reminder: $e');
    }
  }

  /// Schedule multiple reminders for a task (e.g., 1 day before, 1 hour before)
  Future<void> scheduleMultipleReminders({
    required Task task,
    List<Duration>? reminderDurations,
  }) async {
    debugPrint('NotificationService: Scheduling multiple reminders for task "${task.title}"');
    
    if (!_initialized) {
      debugPrint('NotificationService: Not initialized, skipping multiple reminders');
      return;
    }

    final durations =
        reminderDurations ??
        [
          const Duration(days: 1),
          const Duration(hours: 3),
          const Duration(hours: 1),
        ];

    debugPrint('NotificationService: Will schedule ${durations.length} reminders');

    for (int i = 0; i < durations.length; i++) {
      // Use unique ID for each reminder
      final notificationId = task.id * 100 + i;
      final reminderTime = task.dueDate.subtract(durations[i]);

      debugPrint('NotificationService: Reminder $i: ${durations[i].inHours}h before due date');
      debugPrint('NotificationService: Reminder time: $reminderTime');

      if (reminderTime.isBefore(DateTime.now())) {
        debugPrint('NotificationService: Reminder $i time has passed, skipping');
        continue;
      }

      try {
        final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

        final androidDetails = AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Notifications for upcoming tasks',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_launcher',
        );

        const iosDetails = DarwinNotificationDetails();

        final notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        String timeDescription;
        if (durations[i].inDays > 0) {
          timeDescription = '${durations[i].inDays} day(s) before';
        } else if (durations[i].inHours > 0) {
          timeDescription = '${durations[i].inHours} hour(s) before';
        } else {
          timeDescription = '${durations[i].inMinutes} minute(s) before';
        }

        await _notificationsPlugin.zonedSchedule(
          notificationId,
          'Task Reminder: ${task.title}',
          'Due in $timeDescription',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'task_${task.id}',
        );

        debugPrint('NotificationService: Successfully scheduled reminder $i for task "${task.title}" at $scheduledDate');
      } catch (e) {
        debugPrint('NotificationService: Error scheduling reminder $i: $e');
      }
    }
  }

  /// Show immediate notification for overdue task
  Future<void> showOverdueTaskNotification(Task task) async {
    if (!_initialized) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        'overdue_tasks',
        'Overdue Tasks',
        channelDescription: 'Notifications for overdue tasks',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@drawable/ic_launcher',
        enableLights: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        task.id + 10000, // Offset ID for overdue notifications
        '⚠️ Task Overdue: ${task.title}',
        'This task is past its due date',
        notificationDetails,
        payload: 'task_${task.id}',
      );

      debugPrint(
        'NotificationService: Showed overdue notification for task ${task.id}',
      );
    } catch (e) {
      debugPrint('NotificationService: Error showing overdue notification: $e');
    }
  }

  /// Show immediate notification
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'instant_notifications',
        'Instant Notifications',
        channelDescription: 'Immediate notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails();

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('NotificationService: Error showing instant notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      debugPrint('NotificationService: Cancelled notification $id');
    } catch (e) {
      debugPrint('NotificationService: Error cancelling notification: $e');
    }
  }

  /// Cancel all reminders for a task
  Future<void> cancelTaskReminders(int taskId) async {
    try {
      // Cancel main reminder
      await _notificationsPlugin.cancel(taskId);

      // Cancel multiple reminders (up to 10)
      for (int i = 0; i < 10; i++) {
        await _notificationsPlugin.cancel(taskId * 100 + i);
      }

      // Cancel overdue notification
      await _notificationsPlugin.cancel(taskId + 10000);

      debugPrint(
        'NotificationService: Cancelled all reminders for task $taskId',
      );
    } catch (e) {
      debugPrint('NotificationService: Error cancelling task reminders: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('NotificationService: Cancelled all notifications');
    } catch (e) {
      debugPrint('NotificationService: Error cancelling all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint(
        'NotificationService: Error getting pending notifications: $e',
      );
      return [];
    }
  }

  /// Show daily task summary notification
  Future<void> showDailySummary({
    required int totalTasks,
    required int completedTasks,
    required int pendingTasks,
  }) async {
    if (!_initialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'daily_summary',
        'Daily Summary',
        channelDescription: 'Daily task summary notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@drawable/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails();

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        999999, // Unique ID for daily summary
        'Daily Task Summary',
        '$completedTasks/$totalTasks tasks completed. $pendingTasks pending.',
        notificationDetails,
        payload: 'daily_summary',
      );
    } catch (e) {
      debugPrint('NotificationService: Error showing daily summary: $e');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    }
    return true; // iOS handles this through system settings
  }

  /// Dispose resources
  void dispose() {
    _initialized = false;
    debugPrint('NotificationService: Disposed');
  }
}
