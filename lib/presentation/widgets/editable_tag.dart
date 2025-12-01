import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/tag.dart';

/// Modern editable tag component with beautiful animations
class EditableTag extends StatefulWidget {
  final Tag tag;
  final bool isDark;
  final VoidCallback onDelete;
  final Function(Tag) onUpdate;

  const EditableTag({
    super.key,
    required this.tag,
    required this.isDark,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<EditableTag> createState() => _EditableTagState();
}

class _EditableTagState extends State<EditableTag> with TickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isEditing = false;
  late String _currentName;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tag.name);
    _currentName = widget.tag.name;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _isEditing ? _buildEditingWidget() : _buildDisplayWidget(),
          ),
        );
      },
    );
  }

  Widget _buildDisplayWidget() {
    return Container(
      margin: const EdgeInsets.only(right: 12, bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _startEditing,
          onLongPress: _showOptions,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _parseColor(widget.tag.colorHex).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _parseColor(widget.tag.colorHex).withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _parseColor(widget.tag.colorHex).withValues(alpha: 0.1),
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
                    color: _parseColor(widget.tag.colorHex),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.tag.name,
                  style: TextStyle(
                    color: _parseColor(widget.tag.colorHex),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (widget.tag.usageCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _parseColor(widget.tag.colorHex).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.tag.usageCount}',
                      style: TextStyle(
                        color: _parseColor(widget.tag.colorHex),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditingWidget() {
    return Container(
      margin: const EdgeInsets.only(right: 12, bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF137FEC),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF137FEC).withValues(alpha: 0.2),
              blurRadius: 8,
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
                color: _parseColor(widget.tag.colorHex),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(
                  color: widget.isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                autofocus: true,
                onSubmitted: (_) => _saveChanges(),
                onTapOutside: (_) {
                  _cancelEditing();
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _saveChanges,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _cancelEditing,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveChanges() {
    if (_controller.text.trim().isNotEmpty && _controller.text.trim() != _currentName) {
      final updatedTag = widget.tag.copyWith(name: _controller.text.trim());
      widget.onUpdate(updatedTag);
    }
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _controller.text = _currentName;
    });
  }

  void _showOptions() {
    // Check if modal is already open
    if (ModalRoute.of(context)?.isCurrent != true) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Tag info
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(widget.tag.colorHex),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.label,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.tag.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.tag.usageCount} использований',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Options
            _buildOptionTile(
              icon: Icons.edit,
              title: 'editable_tag.edit'.tr(),
              onTap: () {
                Navigator.pop(context);
                _startEditing();
              },
            ),
            _buildOptionTile(
              icon: Icons.delete,
              title: 'editable_tag.delete'.tr(),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              },
              isDestructive: true,
            ),
            const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('editable_tag.delete_tag'.tr()),
        content: Text('editable_tag.confirm_delete_tag'.tr(namedArgs: {'name': widget.tag.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('editable_tag.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('editable_tag.delete_button'.tr()),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF137FEC);
    }
  }
}