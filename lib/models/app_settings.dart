import 'dnd_period.dart';

class AppSettings {
  final int dailyGoalMl;
  final int intervalMinutes;
  final int activeStartHour;
  final int activeStartMinute;
  final int activeEndHour;
  final int activeEndMinute;
  final List<DndPeriod> dndPeriods;
  final bool isEnabled;
  final int? mlPerSessionOverride;
  final bool alarmStyle;

  const AppSettings({
    this.dailyGoalMl = 2000,
    this.intervalMinutes = 60,
    this.activeStartHour = 7,
    this.activeStartMinute = 0,
    this.activeEndHour = 22,
    this.activeEndMinute = 0,
    this.dndPeriods = const [],
    this.isEnabled = true,
    this.mlPerSessionOverride,
    this.alarmStyle = false,
  });

  int get activeMinutes {
    final s = activeStartHour * 60 + activeStartMinute;
    final e = activeEndHour * 60 + activeEndMinute;
    return e > s ? e - s : (24 * 60 - s) + e;
  }

  int get sessionsPerDay => (activeMinutes / intervalMinutes).floor().clamp(1, 999);

  int get mlPerSession =>
      mlPerSessionOverride ?? (dailyGoalMl / sessionsPerDay).round();

  bool isInDnd(int hour, int minute) =>
      dndPeriods.any((d) => d.containsTime(hour, minute));

  bool isInActiveHours(int hour, int minute) {
    final t = hour * 60 + minute;
    final s = activeStartHour * 60 + activeStartMinute;
    final e = activeEndHour * 60 + activeEndMinute;
    return s <= e ? (t >= s && t <= e) : (t >= s || t <= e);
  }

  AppSettings copyWith({
    int? dailyGoalMl,
    int? intervalMinutes,
    int? activeStartHour,
    int? activeStartMinute,
    int? activeEndHour,
    int? activeEndMinute,
    List<DndPeriod>? dndPeriods,
    bool? isEnabled,
    Object? mlPerSessionOverride = _sentinel,
    bool? alarmStyle,
  }) =>
      AppSettings(
        dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
        intervalMinutes: intervalMinutes ?? this.intervalMinutes,
        activeStartHour: activeStartHour ?? this.activeStartHour,
        activeStartMinute: activeStartMinute ?? this.activeStartMinute,
        activeEndHour: activeEndHour ?? this.activeEndHour,
        activeEndMinute: activeEndMinute ?? this.activeEndMinute,
        dndPeriods: dndPeriods ?? this.dndPeriods,
        isEnabled: isEnabled ?? this.isEnabled,
        mlPerSessionOverride: mlPerSessionOverride == _sentinel
            ? this.mlPerSessionOverride
            : mlPerSessionOverride as int?,
        alarmStyle: alarmStyle ?? this.alarmStyle,
      );
}

const Object _sentinel = Object();
