import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clock_face.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  Future<void> _showCustomDrinkDialog(
      BuildContext context, WaterProvider provider) async {
    final controller = TextEditingController(
        text: '${provider.settings.mlPerSession}');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24,
          MediaQuery.viewInsetsOf(ctx).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Custom amount',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                suffixText: 'ml',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final val = int.tryParse(controller.text);
                      if (val != null && val > 0) {
                        provider.logDrankCustom(val);
                      }
                      Navigator.pop(ctx);
                    },
                    child: const Text('Log'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResetConfirm(
      BuildContext context, WaterProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset today?'),
        content:
            const Text("This will delete all of today's water logs."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.resetToday();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WaterProvider>();
    final stats = provider.todayStats;
    final settings = provider.settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hydro',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Stay hydrated today 💧',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  // Enable/disable toggle
                  GestureDetector(
                    onTap: provider.toggleEnabled,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: settings.isEnabled
                            ? AppColors.primary.withOpacity(0.12)
                            : Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            settings.isEnabled
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            size: 16,
                            color: settings.isEnabled
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            settings.isEnabled ? 'On' : 'Off',
                            style: TextStyle(
                              color: settings.isEnabled
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Clock
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.72,
                child: ClockFace(
                  time: _now,
                  waterProgress: stats.progress,
                ),
              ),

              const SizedBox(height: 28),

              // Water amount display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.water_drop,
                      color: stats.goalReached
                          ? AppColors.success
                          : AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '${stats.totalMlDrank}',
                          style: TextStyle(
                            color: stats.goalReached
                                ? AppColors.success
                                : AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${settings.dailyGoalMl} ml',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ]),
                    ),
                    if (stats.goalReached) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 20),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Sessions info
              Text(
                stats.goalReached
                    ? 'Goal reached!'
                    : '${stats.sessionsRemaining} sessions left  •  every ${settings.intervalMinutes} min',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Main action buttons
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Drank',
                      icon: Icons.water_drop,
                      color: AppColors.primary,
                      onTap: provider.logDrank,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: 'Skip',
                      icon: Icons.close,
                      color: AppColors.textSecondary,
                      filled: false,
                      onTap: provider.logSkip,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Secondary action buttons
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: '+ Custom',
                      icon: Icons.add,
                      color: AppColors.primary,
                      filled: false,
                      onTap: () => _showCustomDrinkDialog(context, provider),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: 'Undo',
                      icon: Icons.undo,
                      color: AppColors.textSecondary,
                      filled: false,
                      onTap: provider.undoLast,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _showResetConfirm(context, provider),
                child: const Text(
                  'Reset today',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 4),
                FilledButton.tonal(
                  onPressed: () =>
                      NotificationService.instance.scheduleTest(settings),
                  child: const Text('[DEV] Test Alarm (15s)',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: filled ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: filled ? null : Border.all(color: AppColors.ringTrack, width: 1.5),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20, color: filled ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
