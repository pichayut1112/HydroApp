enum LogType { drank, skipped }

class WaterLog {
  final int? id;
  final DateTime timestamp;
  final LogType type;
  final int amountMl;

  const WaterLog({
    this.id,
    required this.timestamp,
    required this.type,
    required this.amountMl,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'type': type.name,
        'amount_ml': amountMl,
      };

  factory WaterLog.fromMap(Map<String, dynamic> map) => WaterLog(
        id: map['id'] as int?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        type: LogType.values.byName(map['type'] as String),
        amountMl: map['amount_ml'] as int,
      );
}
