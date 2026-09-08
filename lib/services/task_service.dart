import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../utils/task_date_utils.dart';

class TaskService {
  TaskService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _logTag = 'TASK_NOTIF';
  // NOTE: Android caches a channel's sound/importance settings the first time it
  // is created and ignores later edits to the same channel id. Bump the id when
  // those settings change so the new config applies on already-installed apps.
  static const List<String> _legacyNotificationChannelIds = <String>[
    'task_reminders',
    'task_reminders_v2',
    'task_reminders_v3',
    'task_reminders_v4',
  ];
  static const String _notificationChannelId = 'task_reminders_v5';
  static const String _notificationChannelName = 'Task Reminders';
  // Fixed id for the immediate "reminder set" confirmation notification.
  static const int _reminderSetConfirmationId = 2147480000;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _notificationsReady = false;
  static Future<void>? _initFuture;

  /// Stable positive notification id derived from the Firestore task document id.
  static int notificationIdForTask(String taskId) =>
      taskId.hashCode & 0x7fffffff;

  static void _log(String message) {
    debugPrint('[$_logTag] $message');
  }

  /// Initializes notifications once for the whole app (safe to call repeatedly).
  static Future<void> ensureNotificationsInitialized() {
    _initFuture ??= _initializeNotifications();
    return _initFuture!;
  }

  Future<void> initializeNotifications() => ensureNotificationsInitialized();

  static Future<void> _initializeNotifications() async {
    if (_notificationsReady) {
      _log('initialize skipped — already ready');
      return;
    }

    _log('initialize START');
    // Each step is guarded so that one failing step can never reject this
    // future — otherwise the rejected future gets cached by
    // ensureNotificationsInitialized() and every later schedule call dies.
    try {
      tz_data.initializeTimeZones();

      // Ask the native layer (Android: TimeZone.getDefault().getID()) for the
      // IANA timezone string so tz.local is set correctly for every device
      // without having to iterate the full timezone database.
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          const sysChannel = MethodChannel('com.sayitloveforkid/system');
          final tzId =
              await sysChannel.invokeMethod<String>('getLocalTimezone');
          if (tzId != null && tzId.isNotEmpty) {
            try {
              tz.setLocalLocation(tz.getLocation(tzId));
              _log('timezone set from native: $tzId');
            } catch (_) {
              _log('timezone "$tzId" not in database, defaulting to UTC');
            }
          } else {
            _log('native timezone returned empty, defaulting to UTC');
          }
        }
      } catch (e) {
        _log('timezone detection failed, defaulting to UTC: $e');
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final initialized = await _notifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: (response) {
          _log(
            'notification tapped id=${response.id} payload=${response.payload}',
          );
        },
      );
      _log('plugin initialize result=$initialized');

      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      try {
        // Remove any older channels so the current standard-notification
        // channel (with reminder_sound on the notification stream) is used.
        for (final legacyId in _legacyNotificationChannelIds) {
          await androidPlugin?.deleteNotificationChannel(legacyId);
        }

        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _notificationChannelId,
            _notificationChannelName,
            description: 'Reminders for your tasks',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        _log('notification channel created id=$_notificationChannelId');
      } catch (e) {
        _log('channel setup FAILED (continuing): $e');
      }

      try {
        final notificationsGranted =
            await androidPlugin?.requestNotificationsPermission();
        _log('POST_NOTIFICATIONS granted=$notificationsGranted');
      } catch (e) {
        _log('POST_NOTIFICATIONS request FAILED (continuing): $e');
      }

      try {
        final exactAlarmsGranted =
            await androidPlugin?.requestExactAlarmsPermission();
        _log('SCHEDULE_EXACT_ALARM granted=$exactAlarmsGranted');
      } catch (e) {
        _log('SCHEDULE_EXACT_ALARM request FAILED (continuing): $e');
      }

      // Ask the OS to exempt this app from battery optimization so that
      // AlarmManager alarms are not silently cancelled on devices with
      // aggressive battery management (Xiaomi / OPPO / Huawei / etc.).
      try {
        if (Platform.isAndroid) {
          const sysChannel = MethodChannel('com.sayitloveforkid/system');
          final isIgnoring =
              await sysChannel.invokeMethod<bool>(
                  'isIgnoringBatteryOptimizations') ??
              false;
          _log('isIgnoringBatteryOptimizations=$isIgnoring');
          if (!isIgnoring) {
            _log('requesting battery optimization exemption...');
            await sysChannel
                .invokeMethod('requestIgnoreBatteryOptimizations');
          }
        }
      } catch (e) {
        _log('battery optimization exemption FAILED (continuing): $e');
      }

      try {
        final areEnabled = await androidPlugin?.areNotificationsEnabled();
        _log('areNotificationsEnabled=$areEnabled');
      } catch (e) {
        _log('areNotificationsEnabled check FAILED (continuing): $e');
      }
    } catch (e, stack) {
      _log('initialize ERROR (continuing so scheduling still works): $e');
      _log('initialize stack=$stack');
    } finally {
      _notificationsReady = true;
      _log('initialize END');
    }
  }

  // Get user's tasks
  Stream<List<TaskModel>> getUserTasks() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TaskModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Add new task
  Future<String?> addTask({
    required String title,
    required String description,
    required TaskCategory category,
    required DateTime dueDate,
    required TaskPriority priority,
    int? reminderMinutes,
    List<String>? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final task = TaskModel(
        id: '',
        title: title,
        description: description,
        category: category,
        dueDate: dueDate,
        priority: priority,
        isCompleted: false,
        createdAt: DateTime.now(),
        userId: user.uid,
        reminderMinutes: reminderMinutes,
        tags: tags ?? [],
        completedAt: null,
        streakDays: 0,
        rewards: 0,
      );

      _log(
        'addTask title="$title" dueDate=$dueDate '
        'reminderMinutes=$reminderMinutes',
      );

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .add(task.toMap());

      _log('addTask saved taskId=${docRef.id}');

      if (reminderMinutes != null && reminderMinutes > 0) {
        final scheduled = await _scheduleReminder(
            docRef.id, title, dueDate, reminderMinutes);
        // Only show the confirmation when the alarm was actually queued.
        // Previously this fired even when the trigger time was already past,
        // making the user believe a reminder was set when it was silently skipped.
        if (scheduled) {
          await _showReminderSetConfirmation(title, reminderMinutes);
        } else {
          _log('addTask reminder skipped (time in past) — no confirmation shown');
        }
      } else {
        _log('addTask no reminder selected for taskId=${docRef.id}');
      }

      await _logPendingNotifications('after addTask');

      return docRef.id;
    } catch (e) {
      print('Error adding task: $e');
      return null;
    }
  }

  // Update task
  Future<bool> updateTask({
    required String taskId,
    String? title,
    String? description,
    TaskCategory? category,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? isCompleted,
    int? reminderMinutes,
    bool syncReminder = false,
    List<String>? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final Map<String, dynamic> updates = {};

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category.name;
      if (dueDate != null) updates['dueDate'] = Timestamp.fromDate(dueDate);
      if (priority != null) updates['priority'] = priority.name;
      if (isCompleted != null) {
        updates['isCompleted'] = isCompleted;
        if (isCompleted) {
          updates['completedAt'] = FieldValue.serverTimestamp();
          updates['rewards'] = FieldValue.increment(10);
        }
      }
      if (syncReminder) {
        updates['reminderMinutes'] = reminderMinutes;
      } else if (reminderMinutes != null) {
        updates['reminderMinutes'] = reminderMinutes;
      }
      if (tags != null) updates['tags'] = tags;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(taskId)
          .update(updates);

      await _syncTaskReminder(taskId);

      return true;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  // Delete task
  Future<bool> deleteTask(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(taskId)
          .delete();

      await _cancelReminder(taskId);
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  // Get task statistics
  Future<TaskStats> getTaskStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return TaskStats.empty();

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .get();

      int total = snapshot.docs.length;
      int completed = 0;
      int overdue = 0;
      int totalRewards = 0;
      int currentStreak = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final task = TaskModel.fromMap(data, doc.id);

        if (task.isCompleted) {
          completed++;
        } else if (task.dueDate.isBefore(DateTime.now())) {
          overdue++;
        }

        totalRewards += task.rewards;
        if (task.streakDays > currentStreak) {
          currentStreak = task.streakDays;
        }
      }

      return TaskStats(
        totalTasks: total,
        completedTasks: completed,
        overdueTasks: overdue,
        pendingTasks: total - completed,
        totalRewards: totalRewards,
        currentStreak: currentStreak,
        completionRate: total > 0 ? (completed / total * 100) : 0,
      );
    } catch (e) {
      print('Error getting task stats: $e');
      return TaskStats.empty();
    }
  }

  /// Re-reads the task from Firestore and schedules or cancels its reminder.
  Future<void> _syncTaskReminder(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(taskId)
          .get();

      if (!doc.exists) {
        await _cancelReminder(taskId);
        return;
      }

      final task = TaskModel.fromMap(doc.data()!, doc.id);
      _log('syncReminder START taskId=$taskId');
      await _cancelReminder(taskId);

      if (task.isCompleted) {
        _log('syncReminder SKIP — task completed taskId=$taskId');
        return;
      }

      final minutes = task.reminderMinutes;
      if (minutes != null && minutes > 0) {
        await _scheduleReminder(task.id, task.title, task.dueDate, minutes);
      } else {
        _log('syncReminder SKIP — no reminder configured taskId=$taskId');
      }
    } catch (e) {
      _log('syncReminder ERROR taskId=$taskId error=$e');
    }
  }

  static String reminderLeadLabel(int minutesBefore) {
    if (minutesBefore >= 1440 && minutesBefore % 1440 == 0) {
      final days = minutesBefore ~/ 1440;
      return days == 1 ? '1 day' : '$days days';
    }
    if (minutesBefore >= 60 && minutesBefore % 60 == 0) {
      final hours = minutesBefore ~/ 60;
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    return minutesBefore == 1 ? '1 minute' : '$minutesBefore minutes';
  }

  static String reminderNotificationBody(String title, int minutesBefore) =>
      "Your task '$title' is due in ${reminderLeadLabel(minutesBefore)}.";

  static tz.TZDateTime _toScheduledTz(DateTime localDateTime) {
    // Compute how far in the future the target is and add that duration to
    // the current TZDateTime. This is the canonical flutter_local_notifications
    // approach — avoids any ambiguity around DST / wall-clock representation.
    final duration = localDateTime.difference(DateTime.now());
    return tz.TZDateTime.now(tz.local).add(duration);
  }

  static Future<void> _logPendingNotifications(String context) async {
    final pending = await _notifications.pendingNotificationRequests();
    _log('pending notifications ($context) count=${pending.length}');
    for (final request in pending) {
      _log(
        '  pending id=${request.id} title="${request.title}" body="${request.body}"',
      );
    }
  }

  static const NotificationDetails _kNotificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: 'Reminders for your tasks',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// Immediate notification confirming a reminder was set. Uses the same
  /// channel + sound as the scheduled reminder, so it also verifies that
  /// notifications and sound work on the device right away.
  Future<void> _showReminderSetConfirmation(
    String title,
    int minutesBefore,
  ) async {
    try {
      await ensureNotificationsInitialized();
      await _notifications.show(
        _reminderSetConfirmationId,
        'Reminder set',
        "You'll be reminded ${reminderLeadLabel(minutesBefore)} "
            "before \"$title\".",
        _kNotificationDetails,
      );
      _log('confirmation notification shown for "$title"');
    } catch (e) {
      _log('confirmation notification FAILED: $e');
    }
  }

  // Schedule reminder notification. Returns true if alarm was actually scheduled,
  // false if the trigger time was already in the past (alarm skipped).
  Future<bool> _scheduleReminder(
    String taskId,
    String title,
    DateTime dueDate,
    int minutesBefore,
  ) async {
    try {
      await ensureNotificationsInitialized();

      final now = DateTime.now();
      final scheduledDate = dueDate.subtract(Duration(minutes: minutesBefore));
      final notificationId = notificationIdForTask(taskId);
      final tzScheduled = _toScheduledTz(scheduledDate);

      _log(
        'schedule START taskId=$taskId notificationId=$notificationId '
        'title="$title" dueDate=$dueDate reminderMinutes=$minutesBefore',
      );
      _log('schedule now=$now calculatedTrigger=$scheduledDate tz=$tzScheduled');

      if (!scheduledDate.isAfter(now)) {
        _log(
          'schedule SKIPPED — trigger already passed '
          '(${now.difference(scheduledDate).inSeconds}s ago)',
        );
        return false;
      }

      final body = reminderNotificationBody(title, minutesBefore);
      final details = _kNotificationDetails;

      // alarmClock mode uses AlarmManager.setAlarmClock() which the Android OS
      // treats as a user-visible alarm — it cannot be deferred or cancelled by
      // battery optimization, Doze, or manufacturer task killers (Xiaomi/OPPO/etc).
      await _notifications.zonedSchedule(
        notificationId,
        'Task Reminder',
        body,
        tzScheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('schedule SUCCESS mode=alarmClock');

      await _logPendingNotifications('after schedule taskId=$taskId');
      return true;
    } catch (e, stack) {
      _log('schedule ERROR taskId=$taskId error=$e');
      _log('schedule stack=$stack');
      return false;
    }
  }

  // Cancel reminder
  Future<void> _cancelReminder(String taskId) async {
    try {
      final notificationId = notificationIdForTask(taskId);
      await _notifications.cancel(notificationId);
      _log('cancel notificationId=$notificationId taskId=$taskId');
      await _logPendingNotifications('after cancel taskId=$taskId');
    } catch (e) {
      _log('cancel ERROR taskId=$taskId error=$e');
    }
  }

  // Get tasks by category
  Stream<List<TaskModel>> getTasksByCategory(TaskCategory category) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('category', isEqualTo: category.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TaskModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Get tasks by priority
  Stream<List<TaskModel>> getTasksByPriority(TaskPriority priority) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('priority', isEqualTo: priority.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TaskModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Mark daily tasks as completed for streak tracking
  Future<void> updateDailyTaskStreak(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(taskId)
          .update({
        'streakDays': FieldValue.increment(1),
        'lastCompletedDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating streak: $e');
    }
  }
}

// Task Model
class TaskModel {
  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final DateTime dueDate;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final String userId;
  final int? reminderMinutes;
  final List<String> tags;
  final DateTime? completedAt;
  final int streakDays;
  final int rewards;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
    required this.createdAt,
    required this.userId,
    this.reminderMinutes,
    required this.tags,
    this.completedAt,
    required this.streakDays,
    required this.rewards,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority.name,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'reminderMinutes': reminderMinutes,
      'tags': tags,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'streakDays': streakDays,
      'rewards': rewards,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: TaskCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TaskCategory.other,
      ),
      dueDate: TaskDateUtils.parseDueDate(map['dueDate']),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      isCompleted: map['isCompleted'] ?? false,
      createdAt: TaskDateUtils.parseDueDate(map['createdAt']),
      userId: map['userId'] ?? '',
      reminderMinutes: map['reminderMinutes'],
      tags: List<String>.from(map['tags'] ?? []),
      completedAt: TaskDateUtils.parseOptionalTimestamp(map['completedAt']),
      streakDays: map['streakDays'] ?? 0,
      rewards: map['rewards'] ?? 0,
    );
  }
}

// Enums
enum TaskCategory {
  homework,
  chores,
  reading,
  exercise,
  creativity,
  learning,
  family,
  other,
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

// Task Statistics
class TaskStats {
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final int pendingTasks;
  final int totalRewards;
  final int currentStreak;
  final double completionRate;

  TaskStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.pendingTasks,
    required this.totalRewards,
    required this.currentStreak,
    required this.completionRate,
  });

  factory TaskStats.empty() {
    return TaskStats(
      totalTasks: 0,
      completedTasks: 0,
      overdueTasks: 0,
      pendingTasks: 0,
      totalRewards: 0,
      currentStreak: 0,
      completionRate: 0,
    );
  }
} 