// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Αρχικοποίηση timezones
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      linux: LinuxInitializationSettings(defaultActionName: 'Open notification'),
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
    );

    // 2. Αίτημα άδειας για Android 13+
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      // Αίτημα για Exact Alarms αν απαιτείται στο Android 13+
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // Άμεση ειδοποίηση (π.χ. δοκιμή)
  Future<void> showWateringNotification({
    required int id,
    required String plantName,
    required String message,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'plant_watering_channel',
      'Υπενθυμίσεις Ποτίσματος',
      channelDescription: 'Ειδοποιήσεις όταν κάποιο φυτό χρειάζεται πότισμα',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: 'Ώρα για Πότισμα! 💧',
      body: '$plantName: $message',
      notificationDetails: details,
    );
  }

  // Προγραμματισμένη ειδοποίηση σε συγκεκριμένη μελλοντική ημερομηνία/ώρα
  Future<void> schedulePlantWatering({
    required int notificationId,
    required String plantName,
    required DateTime scheduledDate,
  }) async {
    // Αν η ημερομηνία έχει ήδη παρέλθει, δεν προγραμματίζουμε
    if (scheduledDate.isBefore(DateTime.now())) return;

    final tz.TZDateTime tzScheduledDate =
    tz.TZDateTime.from(scheduledDate, tz.local);

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'plant_scheduled_channel',
      'Προγραμματισμένα Ποτίσματα',
      channelDescription: 'Αυτόματες υπενθυμίσεις βάσει συχνότητας ποτίσματος',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id: notificationId,
      title: 'Ώρα για Πότισμα! 💧',
      body: 'Το φυτό "$plantName" χρειάζεται νερό σήμερα.',
      scheduledDate: tzScheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Ακύρωση προγραμματισμένης ειδοποίησης (π.χ. σε διαγραφή ή πότισμα)
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
}