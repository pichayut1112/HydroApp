import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/dnd_period.dart';

class SettingsService {
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();
  SettingsService._();

  static const _kGoal = 'daily_goal_ml';
  static const _kInterval = 'interval_minutes';
  static const _kStartH = 'active_start_hour';
  static const _kStartM = 'active_start_minute';
  static const _kEndH = 'active_end_hour';
  static const _kEndM = 'active_end_minute';
  static const _kDnd = 'dnd_periods';
  static const _kEnabled = 'is_enabled';
  static const _kMlOverride = 'ml_per_session_override';
  static const _kAlarmStyle = 'alarm_style';

  Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    final dndJson = p.getString(_kDnd) ?? '[]';
    final dndList = (jsonDecode(dndJson) as List)
        .map((e) => DndPeriod.fromJson(e as Map<String, dynamic>))
        .toList();

    return AppSettings(
      dailyGoalMl: p.getInt(_kGoal) ?? 2000,
      intervalMinutes: p.getInt(_kInterval) ?? 60,
      activeStartHour: p.getInt(_kStartH) ?? 7,
      activeStartMinute: p.getInt(_kStartM) ?? 0,
      activeEndHour: p.getInt(_kEndH) ?? 22,
      activeEndMinute: p.getInt(_kEndM) ?? 0,
      dndPeriods: dndList,
      isEnabled: p.getBool(_kEnabled) ?? true,
      mlPerSessionOverride: p.getInt(_kMlOverride),
      alarmStyle: p.getBool(_kAlarmStyle) ?? false,
    );
  }

  Future<void> save(AppSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kGoal, s.dailyGoalMl);
    await p.setInt(_kInterval, s.intervalMinutes);
    await p.setInt(_kStartH, s.activeStartHour);
    await p.setInt(_kStartM, s.activeStartMinute);
    await p.setInt(_kEndH, s.activeEndHour);
    await p.setInt(_kEndM, s.activeEndMinute);
    await p.setString(_kDnd, jsonEncode(s.dndPeriods.map((d) => d.toJson()).toList()));
    await p.setBool(_kEnabled, s.isEnabled);
    if (s.mlPerSessionOverride != null) {
      await p.setInt(_kMlOverride, s.mlPerSessionOverride!);
    } else {
      await p.remove(_kMlOverride);
    }
    await p.setBool(_kAlarmStyle, s.alarmStyle);
  }
}
