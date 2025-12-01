import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../blocs/workspace_bloc.dart';
import '../blocs/workspace_event.dart';
import '../blocs/workspace_state.dart';

/// Create Workspace Screen
/// Allows users to create a new workspace with name, icon, and color
class CreateWorkspaceScreen extends StatefulWidget {
  final int? workspaceId; // For editing existing workspace
  
  const CreateWorkspaceScreen({super.key, this.workspaceId});

  @override
  State<CreateWorkspaceScreen> createState() => _CreateWorkspaceScreenState();
}

class _CreateWorkspaceScreenState extends State<CreateWorkspaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedIcon = 'check';
  String _selectedColor = '#137fec';
  
  bool get _isEditing => widget.workspaceId != null;

  // Available icons
  final List<IconOption> _availableIcons = [
    IconOption(name: 'check', icon: Icons.check_rounded),
    IconOption(name: 'work', icon: Icons.work_rounded),
    IconOption(name: 'lightbulb', icon: Icons.lightbulb_rounded),
    IconOption(name: 'fitness_center', icon: Icons.fitness_center_rounded),
    IconOption(name: 'favorite', icon: Icons.favorite_rounded),
    IconOption(name: 'star', icon: Icons.star_rounded),
    IconOption(name: 'book', icon: Icons.book_rounded),
  ];

  // Available colors
  final List<ColorOption> _availableColors = [
    ColorOption(name: 'Orange', hex: '#fdba74'),
    ColorOption(name: 'Green', hex: '#6ee7b7'),
    ColorOption(name: 'Blue', hex: '#93c5fd'),
    ColorOption(name: 'Red', hex: '#fca5a5'),
    ColorOption(name: 'Purple', hex: '#c4b5fd'),
    ColorOption(name: 'Pink', hex: '#f9a8d4'),
    ColorOption(name: 'Gray', hex: '#94a3b8'),
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadWorkspaceData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _loadWorkspaceData() {
    // Load workspace data for editing
    final workspaceBloc = context.read<WorkspaceBloc>();
    if (workspaceBloc.state is WorkspaceLoaded) {
      final workspaces = (workspaceBloc.state as WorkspaceLoaded).workspaces;
      final workspace = workspaces.firstWhere(
        (w) => w.id == widget.workspaceId,
        orElse: () => throw Exception('Workspace not found'),
      );
      
      setState(() {
        _nameController.text = workspace.name;
        _descriptionController.text = workspace.description ?? '';
        _selectedIcon = workspace.iconName;
        _selectedColor = workspace.colorHex;
      });
    }
  }

  void _saveWorkspace() {
    if (_formKey.currentState!.validate()) {
      if (_isEditing) {
        // Update existing workspace
        context.read<WorkspaceBloc>().add(
          UpdateWorkspaceEvent(
            id: widget.workspaceId!,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            iconName: _selectedIcon,
            colorHex: _selectedColor,
          ),
        );
      } else {
        // Create new workspace
        context.read<WorkspaceBloc>().add(
          CreateWorkspaceEvent(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            iconName: _selectedIcon,
            colorHex: _selectedColor,
          ),
        );
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101922)
          : const Color(0xFFf6f7f8),
      body: SafeArea(
        child: BlocListener<WorkspaceBloc, WorkspaceState>(
          listener: (context, state) {
            if (state is WorkspaceOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is WorkspaceError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(theme, isDark),

              // Form content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name field
                        _buildNameField(theme, isDark),
                        const SizedBox(height: 24),

                        // Description field
                        _buildDescriptionField(theme, isDark),
                        const SizedBox(height: 24),

                        // Icon picker
                        _buildIconPicker(theme, isDark),
                        const SizedBox(height: 24),

                        // Color picker
                        _buildColorPicker(theme, isDark),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Sticky save button
      bottomNavigationBar: _buildSaveButton(theme, isDark),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101922) : const Color(0xFFf6f7f8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
          ),
          Expanded(
            child: Text(
              _isEditing ? 'create_workspace.edit_title'.tr() : 'workspaces.create_workspace'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFE5E5EA)
                    : const Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildNameField(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'workspaces.name'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'e.g. Personal Projects',
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF3A3A3C)
                    : const Color(0xFFE5E5EA),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF3A3A3C)
                    : const Color(0xFFE5E5EA),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF137fec), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: TextStyle(
            color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'validation.title_required'.tr();
            }
            if (value.trim().length < 2) {
              return 'validation.title_min_length'.tr();
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildDescriptionField(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'workspaces.description'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'A space for all my personal projects and ideas.',
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF3A3A3C)
                    : const Color(0xFFE5E5EA),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF3A3A3C)
                    : const Color(0xFFE5E5EA),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF137fec), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: TextStyle(
            color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildIconPicker(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'workspaces.icon'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _availableIcons.map((iconOption) {
            final isSelected = _selectedIcon == iconOption.name;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIcon = iconOption.name;
                });
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF137fec).withValues(alpha: 0.2)
                      : (isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E5EA)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF137fec)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  iconOption.icon,
                  color: isSelected
                      ? const Color(0xFF137fec)
                      : (isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF666666)),
                  size: 24,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorPicker(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'workspaces.color'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _availableColors.map((colorOption) {
            final isSelected = _selectedColor == colorOption.hex;
            final color = _parseColor(colorOption.hex);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = colorOption.hex;
                });
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101922) : const Color(0xFFf6f7f8),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saveWorkspace,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF137fec),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _isEditing ? 'create_workspace.save_changes'.tr() : 'workspaces.create_workspace'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF137fec);
    }
  }
}

// Helper classes
class IconOption {
  final String name;
  final IconData icon;

  IconOption({required this.name, required this.icon});
}

class ColorOption {
  final String name;
  final String hex;

  ColorOption({required this.name, required this.hex});
}
