import 'package:flutter/material.dart';
import 'package:hopenglish/src/services/app_settings_service.dart';
import 'package:hopenglish/src/theme/app_theme.dart';

class LessonSettingsSheet extends StatefulWidget {
  final int selectedCount;
  final ValueChanged<int> onChanged;

  const LessonSettingsSheet({
    required this.selectedCount,
    required this.onChanged,
    super.key,
  });

  @override
  State<LessonSettingsSheet> createState() => _LessonSettingsSheetState();
}

class _LessonSettingsSheetState extends State<LessonSettingsSheet> {
  late int _selected;

  static const _minutes = {5: 2, 6: 3, 8: 5};

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCount;
  }

  Future<void> _select(int value) async {
    setState(() => _selected = value);
    widget.onChanged(value);
    await AppSettingsService.instance.setLessonWordCount(value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.textHint,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            const Text('每课学习几个单词', style: AppTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text('选择适合孩子的学习节奏', style: AppTheme.bodyMedium),
            const SizedBox(height: 20),
            Row(
              children: AppSettingsService.lessonWordCountOptions.map((count) {
                final selected = count == _selected;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: count ==
                              AppSettingsService.lessonWordCountOptions.last
                          ? 0
                          : 10,
                    ),
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label: '$count 个单词，约 ${_minutes[count]} 分钟',
                      child: InkWell(
                        onTap: () => _select(count),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        child: AnimatedContainer(
                          duration: AppTheme.durationFast,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primary.withValues(alpha: 0.14)
                                : AppTheme.background,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.textHint,
                              width: selected ? 3 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$count',
                                style: AppTheme.displayMedium.copyWith(
                                  color: selected
                                      ? AppTheme.primary
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              Text('个单词', style: AppTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                '约 ${_minutes[count]} 分钟',
                                style: AppTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
