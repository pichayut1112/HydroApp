import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/water_log.dart';
import '../theme/app_theme.dart';

class LogEntryTile extends StatelessWidget {
  final WaterLog log;

  const LogEntryTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final isDrank = log.type == LogType.drank;
    final timeStr = DateFormat('HH:mm').format(log.timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDrank
            ? AppColors.primary.withOpacity(0.06)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDrank
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDrank ? Icons.water_drop : Icons.water_drop_outlined,
              size: 18,
              color: isDrank ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDrank ? 'Drank water' : 'Skipped',
                  style: TextStyle(
                    color:
                        isDrank ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  isDrank ? '+${log.amountMl} ml' : 'Reminder skipped',
                  style: TextStyle(
                    color: isDrank ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
