import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/task.dart';
import '../blocs/task_bloc.dart';
import '../blocs/task_event.dart';
import '../blocs/task_state.dart';
import '../blocs/workspace_bloc.dart';
import '../blocs/workspace_event.dart';
import '../blocs/tag_bloc.dart';
import '../blocs/tag_event.dart';
import '../blocs/tag_state.dart';
import '../../domain/entities/tag.dart';

/// TaskDetailsPage - Beautiful and functional task details screen
class TaskDetailsPage extends StatefulWidget {
  final int taskId;

  const TaskDetailsPage({super.key, required this.taskId});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage>
    with TickerProviderStateMixin {
  Task? _currentTask;
  final TextEditingController _noteController = TextEditingController();
  
  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  // Animations
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTaskData();
    // Load tags for display
    context.read<TagBloc>().add(LoadTagsEvent());
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _loadTaskData() {
    final taskBloc = context.read<TaskBloc>();
    if (taskBloc.state is TaskLoaded) {
      final tasks = (taskBloc.state as TaskLoaded).tasks;
      final task = tasks.firstWhere(
        (t) => t.id == widget.taskId,
        orElse: () => throw Exception('Task not found'),
      );
      setState(() {
        _currentTask = task;
      });
      _progressController.animateTo(task.progress ?? 0.0);
    } else {
      taskBloc.add(const LoadTasksEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_currentTask == null) {
    return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
        body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
          children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFF137FEC) : const Color(0xFF137FEC),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading...',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          _buildModernAppBar(isDark),
          
          // Main Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      // Task Header Card
                      _buildTaskHeaderCard(theme, isDark),
                    const SizedBox(height: 24),
                    
                      // Progress Section
                    _buildProgressSection(theme, isDark),
                    const SizedBox(height: 24),
                    
                      // Task Information
                      _buildTaskInfoSection(theme, isDark),
                    const SizedBox(height: 24),
                    
                    
                    // Action Buttons
                    _buildActionButtons(theme, isDark),
                      const SizedBox(height: 100), // Space for bottom navigation
                  ],
                ),
              ),
            ),
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
        ),
      ),
      title: Text(
        'task_details.task_info'.tr(),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF0A0A0A), const Color(0xFF0A0A0A)]
                : [const Color(0xFFFAFAFA), const Color(0xFFF0F0F0)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskHeaderCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF0A0A0A)
          : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Task Title
          Text(
            _currentTask!.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          
          // Task Description
          if (_currentTask!.description != null && _currentTask!.description!.isNotEmpty)
        Text(
              _currentTask!.description!,
          style: TextStyle(
            fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Priority and Status Row
          Row(
            children: [
              // Priority Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getPriorityColor(_currentTask!.priority).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getPriorityColor(_currentTask!.priority).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
      children: [
                    Icon(
                      _getPriorityIcon(_currentTask!.priority),
                      color: _getPriorityColor(_currentTask!.priority),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
        Text(
                      _getPriorityText(_currentTask!.priority),
          style: TextStyle(
                        color: _getPriorityColor(_currentTask!.priority),
            fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Completion Status
        Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
                  color: _currentTask!.isCompleted 
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
            border: Border.all(
                    color: _currentTask!.isCompleted 
                      ? Colors.green.withValues(alpha: 0.4)
                      : Colors.orange.withValues(alpha: 0.4),
                    width: 1,
            ),
          ),
          child: Row(
                  mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                      _currentTask!.isCompleted ? Icons.check_circle : Icons.schedule,
                      color: _currentTask!.isCompleted ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
              Text(
                      _currentTask!.isCompleted ? 'Completed' : 'Pending',
                style: TextStyle(
                        color: _currentTask!.isCompleted ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF137FEC),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                      'task_details.progress'.tr(),
                style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF0A0A0A),
                      ),
                    ),
                    Text(
                      '${((_currentTask!.progress ?? 0.0) * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Animated Progress Bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
            height: 12,
            decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(6),
            ),
                child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_currentTask!.progress ?? 0.0) * _progressAnimation.value,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _currentTask!.progress == 1.0 ? Colors.green : const Color(0xFF137FEC),
                    ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          
          // Quick Progress Actions
          Text(
            'task_details.quick_progress'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildProgressButton('task_details.mark_25'.tr(), 0.25, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressButton('task_details.mark_50'.tr(), 0.5, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressButton('task_details.mark_75'.tr(), 0.75, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressButton('task_details.mark_100'.tr(), 1.0, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInfoSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'task_details.task_info'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF0A0A0A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Task Details
          _buildInfoRow(
            Icons.schedule_rounded,
            'task_details.due_date'.tr(),
            DateFormat('MMM dd, yyyy • HH:mm').format(_currentTask!.dueDate),
            Colors.blue,
            isDark,
          ),
          const SizedBox(height: 16),
          
          if (_currentTask!.category != null && _currentTask!.category!.isNotEmpty)
            _buildInfoRow(
              Icons.category_rounded,
              'task_details.category'.tr(),
              _currentTask!.category!,
              Colors.green,
              isDark,
            ),
          
          const SizedBox(height: 16),
          
          // Tags section
          if (_currentTask!.tagIds != null && _currentTask!.tagIds!.isNotEmpty)
            _buildTagsSection(isDark),
          
          const SizedBox(height: 16),
          
          _buildInfoRow(
            Icons.access_time_rounded,
            'task_details.created_at'.tr(),
            DateFormat('MMM dd, yyyy').format(_currentTask!.createdAt),
            Colors.orange,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
                const SizedBox(height: 4),
          Text(
                  value,
            style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
            ),
          ),
      ],
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildActionButtons(ThemeData theme, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Complete Task Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _currentTask!.isCompleted ? _uncompleteTask : _completeTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentTask!.isCompleted 
                  ? Colors.green 
                  : const Color(0xFF137FEC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 12,
              shadowColor: (_currentTask!.isCompleted ? Colors.green : const Color(0xFF137FEC)).withValues(alpha: 0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _currentTask!.isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  _currentTask!.isCompleted ? 'task_details.uncomplete_task'.tr() : 'task_details.complete_task'.tr(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Secondary Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _editTask,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF0A0A0A),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text('task_details.edit_task'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: _deleteTask,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delete_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text('task_details.delete_task'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressButton(String label, double progress, bool isDark) {
    return GestureDetector(
      onTap: () => _updateProgress(progress),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: (_currentTask!.progress ?? 0.0) >= progress 
            ? const Color(0xFF137FEC).withValues(alpha: 0.12)
            : isDark ? const Color(0xFF2A2D3A) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (_currentTask!.progress ?? 0.0) >= progress 
              ? const Color(0xFF137FEC)
              : isDark ? const Color(0xFF3A3D4A) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: (_currentTask!.progress ?? 0.0) >= progress 
              ? const Color(0xFF137FEC)
              : isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }


  void _updateProgress(double progress) {
    if (_currentTask != null) {
      // Если прогресс достиг 100%, автоматически отмечаем задачу как выполненную
      final isCompleted = progress >= 1.0;
      final updatedTask = _currentTask!.copyWith(
        progress: progress,
        isCompleted: isCompleted,
      );
      
      context.read<TaskBloc>().add(UpdateTaskEvent(updatedTask));
      
      setState(() {
        _currentTask = updatedTask;
      });
      
      _progressController.animateTo(progress);
      
      // Показываем сообщение только если задача завершена
      if (isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'task_details.task_completed'.tr()} 🎉'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        // Обновляем статистику workspace
        context.read<WorkspaceBloc>().add(const LoadWorkspacesEvent());
      }
    }
  }

  void _completeTask() {
    final updatedTask = _currentTask!.copyWith(progress: 1.0, isCompleted: true);
    context.read<TaskBloc>().add(UpdateTaskEvent(updatedTask));
    
    setState(() {
      _currentTask = updatedTask;
    });
    
    _progressController.animateTo(1.0);
    context.read<WorkspaceBloc>().add(const LoadWorkspacesEvent());
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${'task_details.task_completed'.tr()} 🎉'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _uncompleteTask() {
    final updatedTask = _currentTask!.copyWith(progress: 0.0, isCompleted: false);
    context.read<TaskBloc>().add(UpdateTaskEvent(updatedTask));
    
    setState(() {
      _currentTask = updatedTask;
    });
    
    _progressController.animateTo(0.0);
    context.read<WorkspaceBloc>().add(const LoadWorkspacesEvent());
  }

  void _editTask() {
    context.push('/edit-task/${_currentTask!.id}?workspaceId=${_currentTask!.workspaceId}');
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'task_details.delete_task'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('task_details.confirm_delete'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('buttons.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TaskBloc>().add(DeleteTaskEvent(_currentTask!.id));
              context.pop();
            },
            child: Text('buttons.delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.keyboard_arrow_down_rounded;
      case TaskPriority.medium:
        return Icons.remove_rounded;
      case TaskPriority.high:
        return Icons.keyboard_arrow_up_rounded;
      case TaskPriority.urgent:
        return Icons.priority_high_rounded;
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'priority.low'.tr();
      case TaskPriority.medium:
        return 'priority.medium'.tr();
      case TaskPriority.high:
        return 'priority.high'.tr();
      case TaskPriority.urgent:
        return 'priority.urgent'.tr();
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.blue;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  /// Build tags section for task details
  Widget _buildTagsSection(bool isDark) {
    return BlocBuilder<TagBloc, TagState>(
      builder: (context, state) {
        if (state is TagLoaded) {
          final taskTags = state.tags
              .where((tag) => _currentTask!.tagIds!.contains(tag.id))
              .toList();
          
          if (taskTags.isNotEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.purple.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.label_rounded,
                          color: Colors.purple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'task_details.tags'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: taskTags.map((tag) => _buildTagChip(tag, isDark)).toList(),
                  ),
                ],
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Build tag chip for task details
  Widget _buildTagChip(Tag tag, bool isDark) {
    return GestureDetector(
      onTap: () => _showTagDetails(tag, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tag.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tag.color.withValues(alpha: 0.4),
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
              style: TextStyle(
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

  /// Show tag details popup
  void _showTagDetails(Tag tag, bool isDark) {
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
            // Tag color indicator
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
            // Tag name
            Text(
              tag.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            // Tag usage count
            Text(
              '${'tags.usage_count'.tr()}: ${tag.usageCount}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            // Created date
            Text(
              'task_details.created'.tr(namedArgs: {'date': _formatDate(tag.createdAt)}),
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
              'tags.close'.tr(),
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

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'task_details.today'.tr();
    } else if (difference == 1) {
      return 'task_details.tomorrow'.tr();
    } else if (difference == -1) {
      return 'task_details.yesterday'.tr();
    } else if (difference > 0) {
      return 'task_details.in_days'.tr(namedArgs: {'days': difference.toString()});
    } else {
      return '${difference.abs()} дней назад';
    }
  }
}