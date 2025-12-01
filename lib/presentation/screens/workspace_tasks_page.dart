import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/entities/task.dart';
import '../blocs/task_bloc.dart';
import '../blocs/task_event.dart';
import '../blocs/task_state.dart';
import '../blocs/tag_bloc.dart';
import '../blocs/tag_event.dart';
import '../blocs/tag_state.dart';
import '../../domain/entities/tag.dart';

class WorkspaceTasksPage extends StatefulWidget {
  final Workspace workspace;

  const WorkspaceTasksPage({
    super.key,
    required this.workspace,
  });

  @override
  State<WorkspaceTasksPage> createState() => _WorkspaceTasksPageState();
}

class _WorkspaceTasksPageState extends State<WorkspaceTasksPage>
    with TickerProviderStateMixin {
  TaskFilter _currentFilter = TaskFilter.all;
  late AnimationController _fabAnimationController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false;
  List<Task>? _cachedTasks;
  TaskFilter? _cachedFilter;
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedTagId; // Выбранный тег для фильтрации

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Load tasks for this workspace efficiently
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        context.read<TaskBloc>().add(LoadTasksByWorkspaceEvent(widget.workspace.id));
        context.read<TagBloc>().add(LoadTagsEvent());
        _isInitialized = true;
      }
    });
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fabAnimationController.forward();
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar
          _buildModernAppBar(isDark),
          
          // Workspace Header with integrated search
          _buildWorkspaceHeader(theme, isDark),
          
          // Filter Chips
          _buildFilterChips(theme, isDark),
          
          // Tasks List
          BlocListener<TaskBloc, TaskState>(
            listener: (context, state) {
              if (state is TaskOperationSuccess) {
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is TaskError) {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
              if (state is TaskLoading || state is TaskOperationInProgress) {
                return _buildLoadingState(isDark);
              } else if (state is TaskLoaded) {
                // Clear cache when tasks change
                _cachedTasks = null;
                _cachedFilter = null;
                // Apply filter to already loaded workspace tasks
                final filteredTasks = _applyFilter(state.tasks, _currentFilter);
                if (filteredTasks.isEmpty) {
                  return _buildEmptyState(theme, isDark);
                }
                return _buildTasksSections(filteredTasks, theme, isDark);
              } else if (state is TaskOperationSuccess) {
                // Clear cache when tasks change
                _cachedTasks = null;
                _cachedFilter = null;
                // Handle successful task operations
                final filteredTasks = _applyFilter(state.tasks, _currentFilter);
                if (filteredTasks.isEmpty) {
                  return _buildEmptyState(theme, isDark);
                }
                return _buildTasksSections(filteredTasks, theme, isDark);
              } else if (state is TaskEmpty) {
                return _buildEmptyState(theme, isDark);
              } else if (state is TaskError) {
                return _buildErrorState(state.message, isDark);
              }
              return _buildLoadingState(isDark);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(theme, isDark),
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
          color: isDark ? const Color(0xFF1A1D29) : Colors.white,
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
        widget.workspace.name,
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
                ? [const Color(0xFF0A0A0A), const Color(0xFF1A1D29)]
                : [const Color(0xFFFAFAFA), const Color(0xFFF0F0F0)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceHeader(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [const Color(0xFF1A1D29), const Color(0xFF2A2D3A)]
                  : [Colors.white, const Color(0xFFF8F9FA)],
              ),
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
              children: [
                Row(
                  children: [
                    // Workspace Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(int.parse('0xFF${widget.workspace.colorHex.replaceAll('#', '')}')),
                            Color(int.parse('0xFF${widget.workspace.colorHex.replaceAll('#', '')}')).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Color(int.parse('0xFF${widget.workspace.colorHex.replaceAll('#', '')}')).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIconData(widget.workspace.iconName),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Workspace Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.workspace.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (widget.workspace.description != null && widget.workspace.description!.isNotEmpty)
                            Text(
                              widget.workspace.description!,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white70 : Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          const SizedBox(height: 12),
                          BlocBuilder<TaskBloc, TaskState>(
                            builder: (context, state) {
                              int totalTasks = 0;
                              int completedTasks = 0;
                              
                              if (state is TaskLoaded) {
                                final workspaceTasks = state.tasks
                                    .where((task) => task.workspaceId == widget.workspace.id)
                                    .toList();
                                totalTasks = workspaceTasks.length;
                                completedTasks = workspaceTasks.where((task) => task.isCompleted).length;
                              } else if (state is TaskOperationSuccess) {
                                final workspaceTasks = state.tasks
                                    .where((task) => task.workspaceId == widget.workspace.id)
                                    .toList();
                                totalTasks = workspaceTasks.length;
                                completedTasks = workspaceTasks.where((task) => task.isCompleted).length;
                              }
                              
                              return Row(
                                children: [
                                  _buildStatChip(
                                    Icons.task_alt_rounded,
                                    '$totalTasks',
                                    'tasks',
                                    Colors.blue,
                                    isDark,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatChip(
                                    Icons.check_circle_rounded,
                                    '$completedTasks',
                                    'completed',
                                    Colors.green,
                                    isDark,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Search Bar with Tag Filter (always visible)
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF3A3D4A) : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'workspace_tasks.search_tasks'.tr(),
                            hintStyle: TextStyle(
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: TextStyle(
                            color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
                          ),
                          onChanged: (query) {
                            setState(() {
                              _searchQuery = query;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tag Filter Button
                    GestureDetector(
                      onTap: () => _showTagFilterMenu(context, isDark),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedTagId != null 
                              ? (isDark ? const Color(0xFF137FEC) : const Color(0xFF137FEC))
                              : (isDark ? const Color(0xFF2A2D3A) : const Color(0xFFF8F9FA)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedTagId != null
                                ? const Color(0xFF137FEC)
                                : (isDark ? const Color(0xFF3A3D4A) : const Color(0xFFE5E7EB)),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.filter_list,
                          color: _selectedTagId != null 
                              ? Colors.white
                              : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B)),
                          size: 20,
                        ),
                      ),
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

  Widget _buildStatChip(IconData icon, String count, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFilterChips(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TaskFilter.values.map((filter) {
              final isSelected = _currentFilter == filter;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _onFilterChanged(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [const Color(0xFF137FEC), const Color(0xFF8B5CF6)],
                          )
                        : null,
                      color: isSelected ? null : (isDark ? const Color(0xFF2A2D3A) : const Color(0xFFF8F9FA)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                          ? Colors.transparent 
                          : (isDark ? const Color(0xFF3A3D4A) : const Color(0xFFE5E7EB)),
                        width: 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: const Color(0xFF137FEC).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Text(
                      _getFilterText(filter),
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTasksSections(List<Task> tasks, ThemeData theme, bool isDark) {
    // Разделяем задачи на выполненные и невыполненные
    final pendingTasks = tasks.where((task) => !task.isCompleted).toList();
    final completedTasks = tasks.where((task) => task.isCompleted).toList();
    
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Блок "Задачи" (невыполненные)
          if (pendingTasks.isNotEmpty) ...[
            _buildSectionHeader('tasks.pending', pendingTasks.length, theme, isDark),
            const SizedBox(height: 16),
            ...pendingTasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _fadeController,
                    curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
                  )),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: _buildBeautifulTaskCard(task, theme, isDark),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
          ],
          
          // Блок "Выполненные"
          if (completedTasks.isNotEmpty) ...[
            _buildSectionHeader('tasks.completed', completedTasks.length, theme, isDark),
            const SizedBox(height: 16),
            ...completedTasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _fadeController,
                    curve: Interval((pendingTasks.length + index) * 0.1, 1.0, curve: Curves.easeOut),
                  )),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: _buildBeautifulTaskCard(task, theme, isDark),
                  ),
                ),
              );
            }),
          ],
          
          // Отступ снизу для кнопки FAB
          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(String titleKey, int count, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Text(
            titleKey.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeautifulTaskCard(Task task, ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF0A0A0A)
          : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openTask(task),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Task Header
                Row(
                  children: [
                    // Priority Indicator
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _getPriorityColor(task.priority),
                            _getPriorityColor(task.priority).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Task Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.2,
                            ),
                          ),
                          if (task.description != null && task.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                task.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: task.isCompleted 
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: task.isCompleted 
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            task.isCompleted ? Icons.check_circle : Icons.schedule,
                            color: task.isCompleted ? Colors.green : Colors.orange,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.isCompleted ? 'Completed' : 'Pending',
                            style: TextStyle(
                              color: task.isCompleted ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Task Details
                Row(
                  children: [
                    // Priority
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPriorityIcon(task.priority),
                            color: _getPriorityColor(task.priority),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getPriorityText(task.priority),
                            style: TextStyle(
                              color: _getPriorityColor(task.priority),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Due Date
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: Colors.blue,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(task.dueDate),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Progress
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF137FEC).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${((task.progress ?? 0.0) * 100).toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFF137FEC),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Progress Bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.progress == 1.0 ? Colors.green : const Color(0xFF137FEC),
                      ),
                    ),
                  ),
                ),
                
                // Tags section
                if (task.tagIds != null && task.tagIds!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  BlocBuilder<TagBloc, TagState>(
                    builder: (context, state) {
                      if (state is TagLoaded) {
                        final taskTags = state.tags
                            .where((tag) => task.tagIds!.contains(tag.id))
                            .toList();
                        
                        if (taskTags.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.label,
                                    size: 14,
                                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                        Text(
                          'tags.title'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                          ),
                        ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: taskTags.map((tag) => _buildTagChip(tag, isDark)).toList(),
                              ),
                            ],
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme, bool isDark) {
    return ScaleTransition(
      scale: _fabAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF137FEC), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF137FEC).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _navigateToCreateTask,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: Text(
            'home.new_task'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF137FEC) : const Color(0xFF137FEC),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading tasks...',
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

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF1A1D29), const Color(0xFF2A2D3A)]
              : [Colors.white, const Color(0xFFF8F9FA)],
          ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF137FEC).withValues(alpha: 0.1),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.task_alt_rounded,
                color: isDark ? Colors.white54 : Colors.black54,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'messages.no_tasks'.tr(),
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first task to get started!',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black38,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D29) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading tasks',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _onFilterChanged(TaskFilter filter) {
    if (_currentFilter != filter) {
      setState(() {
        _currentFilter = filter;
      });
      // No need to reload tasks, filtering will be handled in the UI
    }
  }

  void _navigateToCreateTask() {
    context.push('/create-task?workspaceId=${widget.workspace.id}');
  }

  /// Apply filter to tasks locally with caching
  List<Task> _applyFilter(List<Task> tasks, TaskFilter filter) {
    // Check if we can use cached result
    if (_cachedTasks != null && _cachedFilter == filter && _cachedTasks!.length == tasks.length) {
      // Also check if tag filter hasn't changed
      return _cachedTasks!;
    }
    
    List<Task> filteredTasks;
    
    switch (filter) {
      case TaskFilter.all:
        filteredTasks = tasks;
        break;
    }
    
    // Apply search filter if there's a search query
    if (_searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (task.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               (task.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }
    
    // Apply tag filter if a tag is selected
    if (_selectedTagId != null) {
      filteredTasks = filteredTasks.where((task) {
        return task.tagIds?.contains(_selectedTagId!) ?? false;
      }).toList();
    }
    
    // Cache the result
    _cachedTasks = filteredTasks;
    _cachedFilter = filter;
    
    return filteredTasks;
  }

  void _openTask(Task task) {
    context.push('/task/${task.id}');
  }

  void _showTagFilterMenu(BuildContext context, bool isDark) {
    // Check if modal is already open
    if (ModalRoute.of(context)?.isCurrent != true) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D29) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A3D4A) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'workspace_tasks.filter_by_tags'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  if (_selectedTagId != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedTagId = null;
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        'workspace_tasks.clear'.tr(),
                        style: TextStyle(
                          color: const Color(0xFF137FEC),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tags list
            BlocBuilder<TagBloc, TagState>(
              builder: (context, state) {
                if (state is TagLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                } else if (state is TagLoaded) {
                  if (state.tags.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.label_outline,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'workspace_tasks.no_tags_available'.tr(),
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'workspace_tasks.create_tags_in_settings'.tr(),
                            style: TextStyle(
                              color: isDark ? const Color(0xFF6D6D70) : const Color(0xFF8E8E93),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: state.tags.length,
                    itemBuilder: (context, index) {
                      final tag = state.tags[index];
                      final isSelected = _selectedTagId == tag.id;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTagId = isSelected ? null : tag.id;
                              });
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? tag.color.withValues(alpha: 0.15)
                                    : (isDark ? const Color(0xFF2A2D3A) : const Color(0xFFF8F9FA)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected 
                                      ? tag.color
                                      : (isDark ? const Color(0xFF3A3D4A) : const Color(0xFFE5E7EB)),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: tag.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tag.name,
                                      style: TextStyle(
                                        color: isSelected 
                                            ? tag.color
                                            : (isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333)),
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check,
                                      color: tag.color,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  String _getFilterText(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'home.all_tasks'.tr();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'date.today'.tr();
    } else if (difference == 1) {
      return 'date.tomorrow'.tr();
    } else if (difference == -1) {
      return 'date.yesterday'.tr();
    } else if (difference > 0) {
      return 'In $difference days';
    } else {
      return '${-difference} days ago';
    }
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

  IconData _getIconData(String iconName) {
    // Handle empty or null iconName
    if (iconName.isEmpty) {
      return Icons.workspace_premium;
    }
    
    try {
      switch (iconName.toLowerCase()) {
      case 'check':
        return Icons.check_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'lightbulb':
        return Icons.lightbulb_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'book':
        return Icons.book_rounded;
      case 'person':
        return Icons.person_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'shopping':
        return Icons.shopping_cart_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'health':
        return Icons.health_and_safety_rounded;
      case 'finance':
        return Icons.account_balance_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'social':
        return Icons.people_rounded;
      default:
        return Icons.workspace_premium;
      }
    } catch (e) {
      // If any error occurs, return default icon
      return Icons.workspace_premium;
    }
  }

  /// Build tag chip for task card
  Widget _buildTagChip(Tag tag, bool isDark) {
    return GestureDetector(
      onTap: () => _showTagDetails(tag, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: tag.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: tag.color.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: tag.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              tag.name,
              style: TextStyle(
                color: tag.color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: tag.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tag.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.label,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            // Tag name
            Text(
              tag.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 6),
            // Tag usage count
            Text(
              '${'tags.usage_count'.tr()}: ${tag.usageCount}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
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
}