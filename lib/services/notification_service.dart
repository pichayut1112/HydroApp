import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/app_settings.dart';
import 'settings_service.dart';

const _kPermChannel = MethodChannel('com.example.hydro_app/permissions');
const _kBaseNotifId = 42;
const _kMaxPreScheduled = 3; // schedule ล่วงหน้า 3 อัน

/// Top-level handler called when user taps a notification in the background.
@pragma('vm:entry-point')
void onNotificationActionBackground(NotificationResponse res) async {
  final settings = await SettingsService.instance.load();
  await NotificationService.instance.scheduleNext(settings);
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _onAction,
      onDidReceiveBackgroundNotificationResponse:
          onNotificationActionBackground,
    );

    await ensurePermissions();
  }

  Future<void> ensurePermissions() async {
    final notifGranted = await _android?.areNotificationsEnabled() ?? false;
    final exactGranted =
        await _android?.canScheduleExactNotifications() ?? false;
    final fsiGranted = await _canUseFullScreenIntent();

    if (!notifGranted) await _android?.requestNotificationsPermission();
    if (!exactGranted) await _android?.requestExactAlarmsPermission();
    if (!fsiGranted) await _android?.requestFullScreenIntentPermission();

    if (kDebugMode) {
      final n = await _android?.areNotificationsEnabled() ?? false;
      final e = await _android?.canScheduleExactNotifications() ?? false;
      final f = await _canUseFullScreenIntent();
      debugPrint('[Hydro][Permission] notifications:    $n');
      debugPrint('[Hydro][Permission] exactAlarm:       $e');
      debugPrint('[Hydro][Permission] fullScreenIntent: $f');
    }
  }

  Future<bool> _canUseFullScreenIntent() async {
    try {
      return await _kPermChannel.invokeMethod<bool>('canUseFullScreenIntent') ??
          false;
    } catch (_) {
      return false;
    }
  }

  void _onAction(NotificationResponse res) async {
    final settings = await SettingsService.instance.load();
    await scheduleNext(settings);
  }

  // ── Shared helper ─────────────────────────────────────────────────────────
  AndroidNotificationDetails _buildDetails(AppSettings settings) {
    if (settings.alarmStyle) {
      return const AndroidNotificationDetails(
        'hydro_alarm_channel_v2',
        'Water Alarm',
        channelDescription: 'Alarm-style water reminders',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        enableVibration: true,
        playSound: true,
        autoCancel: false,
        ongoing: false,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );
    }
    return const AndroidNotificationDetails(
      'hydro_channel',
      'Water Reminders',
      channelDescription: 'Reminders to drink water',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: false,
    );
  }

  // ── Schedule next N real reminders ───────────────────────────────────────
  Future<void> scheduleNext(AppSettings settings) async {
    // ยกเลิก slot ที่ pre-scheduled ไว้ก่อน
    for (var i = 0; i < _kMaxPreScheduled; i++) {
      await _plugin.cancel(_kBaseNotifId + i);
    }
    if (!settings.isEnabled) return;

    final slots = _findNextSlots(settings, count: _kMaxPreScheduled);
    if (slots.isEmpty) return;

    for (var i = 0; i < slots.length; i++) {
      await _plugin.zonedSchedule(
        _kBaseNotifId + i,
        'Time to Hydrate! 💧',
        'Stay healthy — drink a glass of water now.',
        tz.TZDateTime.from(slots[i], tz.local),
        NotificationDetails(android: _buildDetails(settings)),
        androidScheduleMode: settings.alarmStyle
            ? AndroidScheduleMode.alarmClock
            : AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    if (kDebugMode) {
      debugPrint('[Hydro] Scheduled ${slots.length} notification(s):');
      for (var s in slots) {
        final diff = s.difference(DateTime.now());
        final m = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
        final sec = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
        debugPrint('[Hydro]   → in $m:$sec  (${s.hour.toString().padLeft(2,'0')}:${s.minute.toString().padLeft(2,'0')})');
      }
      startDevCountdown(slots.first);
    }
  }

  // ── Debug: fire test notification in N seconds (ignores active hours) ─────
  Future<void> scheduleTest(AppSettings settings, {int seconds = 15}) async {
    if (!kDebugMode) return;
    // ใช้ ID แยกต่างหาก ไม่ overwrite real schedule
    const testId = _kBaseNotifId + 10;
    await _plugin.cancel(testId);

    final testTime = DateTime.now().add(Duration(seconds: seconds));
    await _plugin.zonedSchedule(
      testId,
      '[TEST] Time to Hydrate! 💧',
      'Test alarm — fires in $seconds s.',
      tz.TZDateTime.from(testTime, tz.local),
      NotificationDetails(android: _buildDetails(settings)),
      androidScheduleMode: settings.alarmStyle
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('[Hydro][TEST] Scheduled in $seconds seconds.');
    _startTestCountdown(testTime);
  }

  // ── Find next N valid time slots ─────────────────────────────────────────
  List<DateTime> _findNextSlots(AppSettings settings, {required int count}) {
    final result = <DateTime>[];
    var candidate = DateTime.now();
    var skipped = 0;

    for (var i = 0; i < 500 && result.length < count; i++) {
      candidate = candidate.add(Duration(minutes: settings.intervalMinutes));
      final h = candidate.hour;
      final m = candidate.minute;
      final inActive = settings.isInActiveHours(h, m);
      final inDnd = settings.isInDnd(h, m);

      if (inActive && !inDnd) {
        result.add(candidate);
      } else {
        skipped++;
      }
    }

    if (kDebugMode && skipped > 0) {
      debugPrint('[Hydro] Skipped $skipped slot(s) (outside active hours or DND)');
    }
    return result;
  }

  Future<void> cancel() async {
    for (var i = 0; i < _kMaxPreScheduled; i++) {
      await _plugin.cancel(_kBaseNotifId + i);
    }
  }

  // ── Dev countdowns ────────────────────────────────────────────────────────
  Timer? _devCountdown;
  Timer? _testCountdown;

  void startDevCountdown(DateTime nextTime) {
    if (!kDebugMode) return;
    _devCountdown?.cancel();
    _devCountdown = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = nextTime.difference(DateTime.now());
      if (remaining.isNegative) {
        debugPrint('[Hydro] Next notification fired!');
        _devCountdown?.cancel();
      } else {
        final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
        final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
        debugPrint('[Hydro] Next real notification in $m:$s');
      }
    });
  }

  void _startTestCountdown(DateTime testTime) {
    _testCountdown?.cancel();
    _testCountdown = Timer.periodic(const Duration(seconds: 1), (t) {
      final remaining = testTime.difference(DateTime.now());
      if (remaining.isNegative) {
        debugPrint('[Hydro][TEST] Fired!');
        t.cancel();
      } else {
        final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
        final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
        debugPrint('[Hydro][TEST] Test notification in $m:$s');
      }
    });
  }

  void stopDevCountdown() {
    _devCountdown?.cancel();
    _testCountdown?.cancel();
  }
}
