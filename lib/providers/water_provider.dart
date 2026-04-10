import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/dnd_period.dart';
import '../models/water_log.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

class DayStats {
  final List<WaterLog> logs;
  final int goalMl;
  final int mlPerSession;

  const DayStats({
    required this.logs,
    required this.goalMl,
    required this.mlPerSession,
  });

  int get drankCount => logs.where((l) => l.type == LogType.drank).length;
  int get skippedCount => logs.where((l) => l.type == LogType.skipped).length;
  int get totalMlDrank => logs
      .where((l) => l.type == LogType.drank)
      .fold(0, (sum, l) => sum + l.amountMl);
  double get progress => goalMl > 0 ? (totalMlDrank / goalMl).clamp(0.0, 1.0) : 0.0;
  bool get goalReached => totalMlDrank >= goalMl;

  int get sessionsRemaining {
    final remaining = (goalMl - totalMlDrank).clamp(0, goalMl);
    if (remaining == 0 || mlPerSession <= 0) return 0;
    return (remaining / mlPerSession).ceil();
  }
}

class WaterProvider extends ChangeNotifier {
  AppSettings _settings = const AppSettings();
  List<WaterLog> _todayLogs = [];
  List<WaterLog> _yesterdayLogs = [];
  bool _loading = true;

  AppSettings get settings => _settings;
  List<WaterLog> get todayLogs => _todayLogs;
  List<WaterLog> get yesterdayLogs => _yesterdayLogs;
  bool get loading => _loading;

  DayStats get todayStats => DayStats(
        logs: _todayLogs,
        goalMl: _settings.dailyGoalMl,
        mlPerSession: _settings.mlPerSession,
      );

  DayStats get yesterdayStats => DayStats(
        logs: _yesterdayLogs,
        goalMl: _settings.dailyGoalMl,
        mlPerSession: _settings.mlPerSession,
      );

  Future<void> init() async {
    _settings = await SettingsService.instance.load();
    await _refreshLogs();
    _loading = false;
    notifyListeners();
  }

  Future<void> _refreshLogs() async {
    final now = DateTime.now();
    _todayLogs = await DatabaseService.instance.getLogsForDay(now);
    _yesterdayLogs = await DatabaseService.instance
        .getLogsForDay(now.subtract(const Duration(days: 1)));
  }

  Future<void> logDrank() async {
    await DatabaseService.instance.insertLog(WaterLog(
      timestamp: DateTime.now(),
      type: LogType.drank,
      amountMl: _settings.mlPerSession,
    ));
    await _refreshLogs();
    notifyListeners();
  }

  Future<void> logSkip() async {
    await DatabaseService.instance.insertLog(WaterLog(
      timestamp: DateTime.now(),
      type: LogType.skipped,
      amountMl: _settings.mlPerSession,
    ));
    await _refreshLogs();
    notifyListeners();
  }

  Future<void> logDrankCustom(int ml) async {
    await DatabaseService.instance.insertLog(WaterLog(
      timestamp: DateTime.now(),
      type: LogType.drank,
      amountMl: ml,
    ));
    await _refreshLogs();
    notifyListeners();
  }

  Future<void> undoLast() async {
    if (_todayLogs.isEmpty) return;
    final last = _todayLogs.first; // ordered DESC — first = most recent
    if (last.id == null) return;
    await DatabaseService.instance.deleteLog(last.id!);
    await _refreshLogs();
    notifyListeners();
  }

  Future<void> resetToday() async {
    await DatabaseService.instance.deleteLogsForDay(DateTime.now());
    await _refreshLogs();
    notifyListeners();
  }

  Future<void> saveSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await SettingsService.instance.save(newSettings);
    if (newSettings.isEnabled) {
      await NotificationService.instance.scheduleNext(newSettings);
    } else {
      await NotificationService.instance.cancel();
    }
    await _refreshLogs();
    notifyListeners();
  }

  Future<void> toggleEnabled() =>
      saveSettings(_settings.copyWith(isEnabled: !_settings.isEnabled));

  Future<void> addDndPeriod(DndPeriod p) =>
      saveSettings(_settings.copyWith(
          dndPeriods: [..._settings.dndPeriods, p]));

  Future<void> removeDndPeriod(String id) =>
      saveSettings(_settings.copyWith(
          dndPeriods: _settings.dndPeriods.where((d) => d.id != id).toList()));
}
