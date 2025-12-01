import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/tag.dart';
import '../blocs/tag_bloc.dart';
import '../blocs/tag_state.dart';
import '../utils/accessibility_helper.dart';

/// Виджет TaskCard
/// Отображает одну задачу со всей её информацией
/// Поддерживает нажатие, переключение завершения и удаление
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        task.dueDate.isBefore(DateTime.now()) && !task.isCompleted;
    final theme = Theme.of(context);

    return Semantics(
      label: AccessibilityHelper.taskCardSemanticLabel(
        title: task.title,
        isCompleted: task.isCompleted,
        priority: task.priority.name,
        dueDate: task.dueDate,
        category: task.category,
      ),
      button: true,
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: task.isCompleted ? 0 : 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Строка с заголовком и чекбоксом
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Чекбокс
                  Semantics(
                    label: task.isCompleted 
                        ? 'task_card.uncheck_task'.tr(namedArgs: {'title': task.title})
                        : 'task_card.check_task'.tr(namedArgs: {'title': task.title}),
                    button: true,
                    onTap: onToggle,
                    child: Checkbox(
                      value: task.isCompleted,
                      onChanged: (_) => onToggle?.call(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Содержимое задачи
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Заголовок
                        Text(
                          task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            task.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: task.isCompleted
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Кнопка удаления
                  Semantics(
                    label: 'task_card.delete_task'.tr(namedArgs: {'title': task.title}),
                    button: true,
                    onTap: onDelete,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      color: theme.colorScheme.error,
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
              // Индикатор прогресса (если у задачи есть прогресс)
              if (task.progress != null && task.progress! > 0) ...[
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(task.progress! * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.isCompleted 
                            ? Colors.green 
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Строка с метаданными задачи
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Чип даты дедлайна
                  _buildChip(
                    context: context,
                    icon: isOverdue ? Icons.warning : Icons.calendar_today,
                    label: _formatDueDate(task.dueDate),
                    color: isOverdue
                        ? theme.colorScheme.error
                        : _getDueDateColor(context, task.dueDate),
                  ),
                  // Чип приоритета
                  _buildChip(
                    context: context,
                    icon: _getPriorityIcon(task.priority),
                    label: task.priority.displayName,
                    color: _getPriorityColor(context, task.priority),
                  ),
                  // Чип категории
                  if (task.category != null && task.category!.isNotEmpty)
                    _buildChip(
                      context: context,
                      icon: Icons.label,
                      label: task.category!,
                      color: theme.colorScheme.tertiary,
                    ),
                  // Блок тегов
                  if (task.tagIds != null && task.tagIds!.isNotEmpty)
                    BlocBuilder<TagBloc, TagState>(
                      builder: (context, state) {
                        if (state is TagLoaded) {
                          final taskTags = state.tags
                              .where((tag) => task.tagIds!.contains(tag.id))
                              .toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.label,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'task_card.tags'.tr(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: taskTags.map((tag) => _buildTagChip(
                                  context: context,
                                  tag: tag,
                                )).toList(),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  /// Построить чип для метаданных
  Widget _buildChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Форматирует дату дедлайна в читаемую строку
  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today ${DateFormat.Hm().format(date)}';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow ${DateFormat.Hm().format(date)}';
    } else if (taskDate.isBefore(today)) {
      final diff = today.difference(taskDate).inDays;
      return '$diff day${diff > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(date);
    }
  }

  /// Получает цвет для даты дедлайна в зависимости от близости срока
  Color _getDueDateColor(BuildContext context, DateTime dueDate) {
    final now = DateTime.now();
    final diff = dueDate.difference(now);

    if (diff.inHours < 24) {
      return Colors.orange;
    } else if (diff.inDays < 3) {
      return Colors.amber;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  /// Получает иконку для приоритета
  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.arrow_downward;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.arrow_upward;
      case TaskPriority.urgent:
        return Icons.priority_high;
    }
  }

  /// Получает цвет для приоритета
  Color _getPriorityColor(BuildContext context, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.blue;
      case TaskPriority.medium:
        return Colors.green;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  /// Построить чип тега
  Widget _buildTagChip({
    required BuildContext context,
    required Tag tag,
  }) {
    return GestureDetector(
      onTap: () => _showTagDetails(context, tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tag.color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tag.color.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: tag.color.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tag.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tag.color.withValues(alpha: 0.3),
                    blurRadius: 2,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              tag.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tag.color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Показать всплывающее окно с деталями тега
  void _showTagDetails(BuildContext context, Tag tag) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1D29) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Индикатор цвета тега
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: tag.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tag.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.label,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            // Название тега
            Text(
              tag.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            // Количество использований тега
            Text(
              'task_card.used_count'.tr(namedArgs: {'count': tag.usageCount.toString()}),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            // Дата создания
            Text(
              'task_card.created'.tr(namedArgs: {'date': _formatDate(tag.createdAt)}),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF6D6D70) : const Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'task_card.close'.tr(),
              style: TextStyle(
                color: const Color(0xFF137FEC),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Форматирует дату для отображения
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'task_card.today'.tr();
    } else if (difference == 1) {
      return 'task_card.yesterday'.tr();
    } else if (difference < 7) {
      return '$difference дней назад';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return 'task_card.weeks_ago'.tr(namedArgs: {'weeks': weeks.toString()});
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
