import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/workspace.dart';
import '../blocs/workspace_bloc.dart';
import '../blocs/workspace_event.dart';

/// Edit workspace page
class EditWorkspacePage extends StatefulWidget {
  final Workspace workspace;

  const EditWorkspacePage({
    super.key,
    required this.workspace,
  });

  @override
  State<EditWorkspacePage> createState() => _EditWorkspacePageState();
}

class _EditWorkspacePageState extends State<EditWorkspacePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedIcon = 'work';
  String _selectedColor = '#137FEC';
  bool _isDark = false;

  final List<String> _icons = [
    'work', 'school', 'person', 'fitness_center', 'home',
    'star', 'favorite', 'lightbulb', 'business', 'sports'
  ];

  final List<String> _colors = [
    '#137FEC', '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4',
    '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE'
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.workspace.name;
    _descriptionController.text = widget.workspace.description ?? '';
    _selectedIcon = widget.workspace.iconName;
    _selectedColor = widget.workspace.colorHex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('edit_workspace.title'.tr()),
        backgroundColor: _isDark ? const Color(0xFF2C2C2E) : Colors.white,
        foregroundColor: _isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
        elevation: 0,
      ),
      backgroundColor: _isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Workspace Preview
              _buildPreviewCard(),
              const SizedBox(height: 24),
              
              // Name Field
              _buildTextField(
                controller: _nameController,
                label: 'edit_workspace.name_label'.tr(),
                icon: Icons.work,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'edit_workspace.name_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description Field
              _buildTextField(
                controller: _descriptionController,
                label: 'edit_workspace.description_label'.tr(),
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Icon Selection
              _buildIconSelection(),
              const SizedBox(height: 24),
              
              // Color Selection
              _buildColorSelection(),
              const SizedBox(height: 32),
              
              // Save Button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _parseColor(_selectedColor).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getIconData(_selectedIcon),
              color: _parseColor(_selectedColor),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            _nameController.text.isEmpty ? 'edit_workspace.name_label'.tr() : _nameController.text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Description
          if (_descriptionController.text.isNotEmpty)
            Text(
              _descriptionController.text,
              style: TextStyle(
                fontSize: 14,
                color: _isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onChanged: (value) => setState(() {}), // Update preview
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: _isDark ? const Color(0xFF2C2C2E) : Colors.white,
      ),
      style: TextStyle(
        color: _isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
      ),
    );
  }

  Widget _buildIconSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'edit_workspace.select_icon'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _icons.map((icon) {
            final isSelected = icon == _selectedIcon;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIcon = icon;
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? _parseColor(_selectedColor).withValues(alpha: 0.2)
                      : (_isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF5F5F5)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? _parseColor(_selectedColor)
                        : (_isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E7)),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  _getIconData(icon),
                  color: isSelected 
                      ? _parseColor(_selectedColor)
                      : (_isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B)),
                  size: 24,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'edit_workspace.select_color'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors.map((color) {
            final isSelected = color == _selectedColor;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _parseColor(color),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: _parseColor(color).withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveWorkspace,
        style: ElevatedButton.styleFrom(
          backgroundColor: _parseColor(_selectedColor),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: _parseColor(_selectedColor).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'edit_workspace.save_changes'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _saveWorkspace() {
    if (_formKey.currentState!.validate()) {
      final updatedWorkspace = widget.workspace.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        iconName: _selectedIcon,
        colorHex: _selectedColor,
      );

      context.read<WorkspaceBloc>().add(UpdateWorkspaceEvent(
        id: updatedWorkspace.id,
        name: updatedWorkspace.name,
        description: updatedWorkspace.description,
        iconName: updatedWorkspace.iconName,
        colorHex: updatedWorkspace.colorHex,
      ));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('edit_workspace.workspace_updated'.tr()),
          duration: Duration(seconds: 2),
        ),
      );
      
      Navigator.pop(context);
    }
  }

  /// Safely parse color from hex string with fallback
  Color _parseColor(String hexColor) {
    try {
      String cleanHex = hexColor.replaceFirst('#', '');
      
      // Add alpha if not present (assume FF for full opacity)
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      // Return default color if parsing fails
      return const Color(0xFF137FEC);
    }
  }

  /// Get icon data from icon name
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'person':
        return Icons.person;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'home':
        return Icons.home;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'business':
        return Icons.business;
      case 'sports':
        return Icons.sports;
      default:
        return Icons.folder;
    }
  }
}
