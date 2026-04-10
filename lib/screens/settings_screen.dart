import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/dnd_period.dart';
import '../providers/water_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dnd_period_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _draft;
  late int _mlPerDrink;
  bool _initialized = false;
  Timer? _saveTimer;
  bool _savedIndicator = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _draft = context.read<WaterProvider>().settings;
      _mlPerDrink = _draft.mlPerSession.clamp(50, 500);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () async {
      await context.read<WaterProvider>().saveSettings(_draft);
      if (mounted) {
        setState(() => _savedIndicator = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _savedIndicator = false);
        });
      }
    });
  }

  void _updateDraft(AppSettings newDraft) {
    setState(() => _draft = newDraft);
    _scheduleSave();
  }

  @override
  Widget build(BuildContext context) {
    // Keep draft in sync if provider updates from outside
    final providerSettings = context.watch<WaterProvider>().settings;
    if (!_initialized) {
      _draft = providerSettings;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                  AnimatedOpacity(
                    opacity: _savedIndicator ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 16, color: AppColors.success),
                        SizedBox(width: 4),
                        Text('Saved',
                            style: TextStyle(
                                color: AppColors.success, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Daily goal
                  _Section(
                    title: 'DAILY GOAL',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Target intake',
                                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                            Text(
                              '${_draft.dailyGoalMl} ml',
                              style:
                                  const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ],
                        ),
                        Slider(
                          value: _draft.dailyGoalMl.toDouble(),
                          min: 500,
                          max: 5000,
                          divisions: 45,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.ringTrack,
                          onChanged: (v) {
                            setState(() {
                              _draft = _draft.copyWith(dailyGoalMl: v.round());
                              if (_draft.mlPerSessionOverride == null) {
                                _mlPerDrink = _draft.mlPerSession.clamp(50, 500);
                              }
                            });
                            _scheduleSave();
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('500 ml', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            Text(
                              '${(_draft.dailyGoalMl / _mlPerDrink).ceil()} sessions to goal',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const Text('5000 ml', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Amount per drink',
                                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                            Row(
                              children: [
                                Text(
                                  '$_mlPerDrink ml',
                                  style: const TextStyle(
                                      color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                if (_draft.mlPerSessionOverride != null) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _draft = _draft.copyWith(mlPerSessionOverride: null);
                                        _mlPerDrink = _draft.mlPerSession.clamp(50, 500);
                                      });
                                      _scheduleSave();
                                    },
                                    child: const Icon(Icons.refresh, size: 16, color: AppColors.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        Slider(
                          value: _mlPerDrink.toDouble(),
                          min: 50,
                          max: 500,
                          divisions: 18,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.ringTrack,
                          onChanged: (v) {
                            setState(() {
                              _mlPerDrink = v.round();
                              _draft = _draft.copyWith(mlPerSessionOverride: _mlPerDrink);
                            });
                            _scheduleSave();
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('50 ml', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            if (_draft.mlPerSessionOverride == null)
                              const Text(
                                'Auto from goal',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            const Text('500 ml', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Reminder interval
                  _Section(
                    title: 'REMINDER INTERVAL',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Remind every',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...[15, 20, 30, 45, 60, 90, 120].map((min) => _ChipOption(
                                  label: _minLabel(min),
                                  selected: _draft.intervalMinutes == min,
                                  onTap: () => _updateDraft(_draft.copyWith(intervalMinutes: min)),
                                )),
                            _ChipOption(
                              label: _isCustomInterval ? '${_draft.intervalMinutes}m' : 'Custom',
                              selected: _isCustomInterval,
                              onTap: () => _showCustomIntervalDialog(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Active hours
                  _Section(
                    title: 'ACTIVE HOURS',
                    child: Column(
                      children: [
                        _TimePicker(
                          label: 'Start',
                          hour: _draft.activeStartHour,
                          minute: _draft.activeStartMinute,
                          onChanged: (h, m) =>
                              _updateDraft(_draft.copyWith(activeStartHour: h, activeStartMinute: m)),
                        ),
                        const SizedBox(height: 8),
                        _TimePicker(
                          label: 'End',
                          hour: _draft.activeEndHour,
                          minute: _draft.activeEndMinute,
                          onChanged: (h, m) =>
                              _updateDraft(_draft.copyWith(activeEndHour: h, activeEndMinute: m)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Alarm style
                  _Section(
                    title: 'NOTIFICATION STYLE',
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Alarm mode',
                                    style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500)),
                                SizedBox(height: 2),
                                Text('แจ้งเตือนแบบนาฬิกาปลุก',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                            Switch(
                              value: _draft.alarmStyle,
                              activeColor: AppColors.primary,
                              onChanged: (v) => _updateDraft(_draft.copyWith(alarmStyle: v)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // DND periods
                  _Section(
                    title: 'DO NOT DISTURB',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No reminders during these hours',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ..._draft.dndPeriods.map((p) => DndPeriodTile(
                              period: p,
                              onDelete: () => _updateDraft(_draft.copyWith(
                                  dndPeriods: _draft.dndPeriods.where((d) => d.id != p.id).toList())),
                            )),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showAddDndDialog(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add period'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isCustomInterval => ![15, 20, 30, 45, 60, 90, 120].contains(_draft.intervalMinutes);

  String _minLabel(int min) => min >= 60 ? '${min ~/ 60}h' : '${min}m';

  Future<void> _showCustomIntervalDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: _isCustomInterval ? '${_draft.intervalMinutes}' : '',
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Custom interval'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Minutes (1 – 480)',
            border: OutlineInputBorder(),
            suffixText: 'min',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 1 && val <= 480) {
                _updateDraft(_draft.copyWith(intervalMinutes: val));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDndDialog(BuildContext context) async {
    String label = 'Sleep';
    int startH = 22, startM = 0, endH = 7, endM = 0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add DND Period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Label (e.g. Sleep)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => label = v,
                controller: TextEditingController(text: label),
              ),
              const SizedBox(height: 16),
              _DialogTimePicker(
                label: 'Start',
                hour: startH,
                minute: startM,
                onChanged: (h, m) => setD(() {
                  startH = h;
                  startM = m;
                }),
              ),
              const SizedBox(height: 8),
              _DialogTimePicker(
                label: 'End',
                hour: endH,
                minute: endM,
                onChanged: (h, m) => setD(() {
                  endH = h;
                  endM = m;
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final period = DndPeriod(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  label: label,
                  startHour: startH,
                  startMinute: startM,
                  endHour: endH,
                  endMinute: endM,
                );
                _updateDraft(_draft.copyWith(dndPeriods: [..._draft.dndPeriods, period]));
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Local widgets ----

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChipOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.ringTrack,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final int hour;
  final int minute;
  final void Function(int, int) onChanged;

  const _TimePicker({
    required this.label,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          builder: (ctx, child) =>
              MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child!),
        );
        if (picked != null) onChanged(picked.hour, picked.minute);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            Text(
              timeStr,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogTimePicker extends StatelessWidget {
  final String label;
  final int hour;
  final int minute;
  final void Function(int, int) onChanged;

  const _DialogTimePicker({
    required this.label,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          builder: (ctx, child) =>
              MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child!),
        );
        if (picked != null) onChanged(picked.hour, picked.minute);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label time:', style: const TextStyle(color: AppColors.textSecondary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
