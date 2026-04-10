class DndPeriod {
  final String id;
  final String label;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const DndPeriod({
    required this.id,
    required this.label,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  bool containsTime(int hour, int minute) {
    final t = hour * 60 + minute;
    final s = startHour * 60 + startMinute;
    final e = endHour * 60 + endMinute;
    return s <= e ? (t >= s && t <= e) : (t >= s || t <= e);
  }

  String get displayTime =>
      '${_fmt(startHour)}:${_fmt(startMinute)} – ${_fmt(endHour)}:${_fmt(endMinute)}';

  String _fmt(int v) => v.toString().padLeft(2, '0');

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      };

  factory DndPeriod.fromJson(Map<String, dynamic> j) => DndPeriod(
        id: j['id'] as String,
        label: j['label'] as String,
        startHour: j['startHour'] as int,
        startMinute: j['startMinute'] as int,
        endHour: j['endHour'] as int,
        endMinute: j['endMinute'] as int,
      );
}
