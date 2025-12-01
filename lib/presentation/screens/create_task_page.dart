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

/// CreateTaskPage - Screen for creating and editing tasks
/// Can be used for both creating new tasks and editing existing ones
class CreateTaskPage extends StatefulWidget {
  final Task? task;
  final int? taskId; // For editing existing task
  final int workspaceId;

  const CreateTaskPage({super.key, this.task, this.taskId, required this.workspaceId});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  late DateTime _selectedDueDate;
  late TimeOfDay _selectedTime;
  TaskPriority _selectedPriority = TaskPriority.medium;
  List<int> _selectedTagIds = []; // Выбранные теги

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool get _isEditMode => widget.task != null || widget.taskId != null;

  // Quick templates for fast task creation
  final List<TaskTemplate> _quickTemplates = [
    TaskTemplate(
      title: 'create_task.quick_task'.tr(),
      description: 'create_task.quick_task_desc'.tr(),
      priority: TaskPriority.low,
      dueDate: Duration(minutes: 15),
    ),
    TaskTemplate(
      title: 'create_task.important_task'.tr(),
      description: 'create_task.important_task_desc'.tr(),
      priority: TaskPriority.high,
      dueDate: Duration(hours: 1),
    ),
    TaskTemplate(
      title: 'create_task.study'.tr(),
      description: 'create_task.study_desc'.tr(),
      priority: TaskPriority.medium,
      dueDate: Duration(hours: 2),
    ),
    TaskTemplate(
      title: 'create_task.meeting'.tr(),
      description: 'create_task.meeting_desc'.tr(),
      priority: TaskPriority.medium,
      dueDate: Duration(hours: 1),
    ),
    TaskTemplate(
      title: 'create_task.workout'.tr(),
      description: 'create_task.workout_desc'.tr(),
      priority: TaskPriority.low,
      dueDate: Duration(hours: 1),
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
    _initializeFields();
    
    // Загружаем теги при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TagBloc>().add(LoadTagsEvent());
    });
  }

  void _initializeFields() {
    if (_isEditMode) {
      if (widget.task != null) {
        // Direct task object provided
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _categoryController.text = widget.task!.category ?? '';
      _selectedDueDate = widget.task!.dueDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.task!.dueDate);
      _selectedPriority = widget.task!.priority;
      _selectedTagIds = widget.task!.tagIds ?? [];
      } else if (widget.taskId != null) {
        // Load task from TaskBloc
        _loadTaskData();
      }
    } else {
      _selectedDueDate = DateTime.now().add(const Duration(hours: 1));
      _selectedTime = TimeOfDay.fromDateTime(_selectedDueDate);
    }
  }

  void _loadTaskData() {
    // Load task data from TaskBloc
    final taskBloc = context.read<TaskBloc>();
    if (taskBloc.state is TaskLoaded) {
      final tasks = (taskBloc.state as TaskLoaded).tasks;
      final task = tasks.firstWhere(
        (t) => t.id == widget.taskId,
        orElse: () => throw Exception('Task not found'),
      );
      
      setState(() {
        _titleController.text = task.title;
        _descriptionController.text = task.description ?? '';
        _categoryController.text = task.category ?? '';
        _selectedDueDate = task.dueDate;
        _selectedTime = TimeOfDay.fromDateTime(task.dueDate);
        _selectedPriority = task.priority;
        _selectedTagIds = task.tagIds ?? [];
      });
    } else {
      // If tasks are not loaded, trigger loading
      taskBloc.add(const LoadTasksEvent());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top App Bar
            _buildTopAppBar(theme, isDark),
            const SizedBox(height: 20),
            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Quick Templates Section
                          if (!_isEditMode) ...[
                            _buildQuickTemplatesSection(theme, isDark),
                            const SizedBox(height: 32),
                          ],
                          // Task Title Section
                          _buildTitleSection(theme, isDark),
                          const SizedBox(height: 24),
                          // Description Section
                          _buildDescriptionSection(theme, isDark),
                          const SizedBox(height: 24),
                          // Priority Section
                          _buildPrioritySection(theme, isDark),
                          const SizedBox(height: 24),
                          // Due Date Section
                          _buildDueDateSection(theme, isDark),
                          const SizedBox(height: 24),
                          // Category Section
                          _buildCategorySection(theme, isDark),
                          const SizedBox(height: 24),
                          // Tags Section
                          _buildTagsSection(theme, isDark),
                          const SizedBox(height: 40),
                          // Action Buttons
                          _buildActionButtons(theme, isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEditMode ? 'create_task.edit_title'.tr() : 'create_task.title'.tr(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditMode ? 'create_task.edit_subtitle'.tr() : 'create_task.subtitle'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTemplatesSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Color(0xFF137FEC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'create_task.quick_templates'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'create_task.select_template'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
            ),
              ),
              const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickTemplates.map((template) {
              return GestureDetector(
                onTap: () => _applyTemplate(template),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF6F7F8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E7),
                    ),
                  ),
                  child: Text(
                    template.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.title,
                  color: Color(0xFF137FEC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'create_task.task_name'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                  ),
                ),
              ),
            ],
              ),
              const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'create_task.enter_task_name'.tr(),
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF6F7F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF137FEC),
                  width: 2,
                ),
              ),
            ),
            style: TextStyle(
              color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
              fontSize: 16,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'create_task.name_required'.tr();
              }
              if (value.trim().length < 3) {
                return 'create_task.name_min_length'.tr();
              }
              return null;
            },
            textCapitalization: TextCapitalization.sentences,
            autofocus: !_isEditMode,
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
              Row(
                children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.flag,
                  color: Color(0xFF137FEC),
                  size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                child: Text(
                  'create_task.priority'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 16),
          Row(
                children: TaskPriority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPriority = priority;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? _getPriorityColor(priority).withValues(alpha: 0.2)
                          : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF6F7F8)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? _getPriorityColor(priority)
                            : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E7)),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPriorityIcon(priority),
                          color: isSelected 
                              ? _getPriorityColor(priority)
                              : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93)),
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPriorityText(priority),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          color: isSelected
                                ? _getPriorityColor(priority)
                                : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93)),
                          ),
                        ),
                      ],
                    ),
                  ),
                    ),
                  );
                }).toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildDueDateSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Color(0xFF137FEC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'create_task.due_date_label'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick date presets
              Wrap(
                spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('create_task.today'.tr(), () => _setPresetDate(0), isDark),
              _buildPresetChip('create_task.tomorrow'.tr(), () => _setPresetDate(1), isDark),
              _buildPresetChip('create_task.next_week'.tr(), () => _setPresetDate(7), isDark),
              _buildPresetChip('create_task.next_month'.tr(), () => _setPresetDate(30), isDark),
            ],
          ),
          const SizedBox(height: 16),
          // Date and time selectors
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E7),
                      ),
                    ),
                    child: Row(
                children: [
                        Icon(
                          Icons.calendar_today,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd.MM.yyyy').format(_selectedDueDate),
                          style: TextStyle(
                            color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _selectTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E7),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedTime.format(context),
                          style: TextStyle(
                            color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'create_task.tags_label'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<TagBloc, TagState>(
          builder: (context, state) {
            if (state is TagLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TagLoaded) {
              return _buildTagsList(state.tags, isDark);
            } else if (state is TagEmpty) {
              return _buildEmptyTagsState(isDark);
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }

  Widget _buildTagsList(List<Tag> tags, bool isDark) {
    if (tags.isEmpty) {
      return _buildEmptyTagsState(isDark);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) => _buildTagChip(tag, isDark)).toList(),
    );
  }

  Widget _buildTagChip(Tag tag, bool isDark) {
    final isSelected = _selectedTagIds.contains(tag.id);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTagIds.remove(tag.id);
          } else {
            _selectedTagIds.add(tag.id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? tag.color.withValues(alpha: 0.2)
              : (isDark ? const Color(0xFF2A2D3A) : const Color(0xFFF8F9FA)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? tag.color
                : (isDark ? const Color(0xFF3A3D4A) : const Color(0xFFE5E7EB)),
            width: isSelected ? 2 : 1,
          ),
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
              ),
            ),
            const SizedBox(width: 6),
            Text(
              tag.name,
              style: TextStyle(
                color: isSelected 
                    ? tag.color
                    : (isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333)),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check,
                size: 16,
                color: tag.color,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTagsState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D29) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.label_outline,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'create_task.no_tags_available'.tr(),
            style: TextStyle(
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'create_task.create_tags_in_settings'.tr(),
            style: TextStyle(
              color: isDark ? const Color(0xFF6D6D70) : const Color(0xFF8E8E93),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.category,
                  color: Color(0xFF137FEC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'create_task.category_optional'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _categoryController,
            decoration: InputDecoration(
              hintText: 'create_task.category_placeholder'.tr(),
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF6F7F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF137FEC),
                  width: 2,
                ),
              ),
            ),
            style: TextStyle(
              color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
              fontSize: 16,
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.description,
                  color: Color(0xFF137FEC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'create_task.description_optional'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'create_task.description_placeholder'.tr(),
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF6F7F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF137FEC),
                  width: 2,
                ),
              ),
            ),
            style: TextStyle(
              color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
              fontSize: 16,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
      style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
              side: BorderSide(
                color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E7),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('create_task.cancel'.tr()),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF137FEC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: const Color(0xFF137FEC).withValues(alpha: 0.3),
            ),
            child: Text(_isEditMode ? 'create_task.save'.tr() : 'create_task.create_button'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onPressed, bool isDark) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
          ),
        ),
      ),
    );
  }

  void _applyTemplate(TaskTemplate template) {
    setState(() {
      _titleController.text = template.title;
      _descriptionController.text = template.description;
      _selectedPriority = template.priority;
      _selectedDueDate = DateTime.now().add(template.dueDate);
      _selectedTime = TimeOfDay.fromDateTime(_selectedDueDate);
    });
  }

  void _setPresetDate(int days) {
    setState(() {
      _selectedDueDate = DateTime.now().add(Duration(days: days));
      _selectedTime = TimeOfDay.fromDateTime(_selectedDueDate);
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDueDate = DateTime(
          _selectedDueDate.year,
          _selectedDueDate.month,
          _selectedDueDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final taskBloc = context.read<TaskBloc>();

      if (_isEditMode) {
        // Update existing task
        Task taskToUpdate;
        if (widget.task != null) {
            taskToUpdate = widget.task!.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            dueDate: _selectedDueDate,
            priority: _selectedPriority,
            category: _categoryController.text.trim().isEmpty
                ? null
                : _categoryController.text.trim(),
            tagIds: _selectedTagIds.isNotEmpty ? _selectedTagIds : null,
          );
        } else {
          // Load task from TaskBloc and update
          final taskBlocState = context.read<TaskBloc>().state;
          if (taskBlocState is TaskLoaded) {
            final tasks = taskBlocState.tasks;
            final existingTask = tasks.firstWhere(
              (t) => t.id == widget.taskId,
              orElse: () => throw Exception('Task not found'),
            );
            taskToUpdate = existingTask.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          dueDate: _selectedDueDate,
          priority: _selectedPriority,
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          tagIds: _selectedTagIds.isNotEmpty ? _selectedTagIds : null,
        );
          } else {
            throw Exception('Task not loaded');
          }
        }

        taskBloc.add(UpdateTaskEvent(taskToUpdate));
      } else {
        // Create new task
        taskBloc.add(
          CreateTaskEvent(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            dueDate: _selectedDueDate,
            priority: _selectedPriority,
            category: _categoryController.text.trim().isEmpty
                ? null
                : _categoryController.text.trim(),
            workspaceId: widget.workspaceId,
            tagIds: _selectedTagIds.isNotEmpty ? _selectedTagIds : null,
          ),
        );
      }

      // Update workspace statistics
      context.read<WorkspaceBloc>().add(const LoadWorkspacesEvent());

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'create_task.task_updated_success'.tr() : 'create_task.task_created_success'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );

      // Go back to workspace
      context.pop();
    }
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.keyboard_arrow_up;
      case TaskPriority.urgent:
        return Icons.priority_high;
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'create_task.priority_low'.tr();
      case TaskPriority.medium:
        return 'create_task.priority_medium'.tr();
      case TaskPriority.high:
        return 'create_task.priority_high'.tr();
      case TaskPriority.urgent:
        return 'create_task.priority_urgent'.tr();
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
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
}

class TaskTemplate {
  final String title;
  final String description;
  final TaskPriority priority;
  final Duration dueDate;

  TaskTemplate({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
  });
}