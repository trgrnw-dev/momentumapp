import 'package:flutter/material.dart';
import '../../domain/entities/workspace.dart';

/// Reusable workspace card component
class WorkspaceCard extends StatelessWidget {
  final Workspace workspace;
  final bool isDark;
  final VoidCallback onTap;
  final bool isListView;

  const WorkspaceCard({
    super.key,
    required this.workspace,
    required this.isDark,
    required this.onTap,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress(workspace.completedTasks, workspace.totalTasks);
    final remainingTasks = workspace.totalTasks - workspace.completedTasks;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isListView ? _buildListViewContent(progress, remainingTasks) : _buildGridViewContent(progress, remainingTasks),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListViewContent(double progress, int remainingTasks) {
    return Row(
      children: [
        // Icon
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _parseColor(workspace.colorHex).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconData(workspace.iconName),
            color: _parseColor(workspace.colorHex),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                workspace.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
                ),
              ),
              if (workspace.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  workspace.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$remainingTasks задач',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${progress.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _parseColor(workspace.colorHex),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Progress indicator
        _buildProgressIndicator(progress, 40.0, 3.0, 10.0),
      ],
    );
  }

  Widget _buildGridViewContent(double progress, int remainingTasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon and Progress Ring
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Workspace Icon
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: (1 - value) * 0.5,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _parseColor(workspace.colorHex).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconData(workspace.iconName),
                      color: _parseColor(workspace.colorHex),
                      size: 24,
                    ),
                  ),
                );
              },
            ),
            // Progress Ring
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: progress / 100),
              builder: (context, value, child) {
                return SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E7),
                            width: 4,
                          ),
                        ),
                      ),
                      // Progress circle
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 4,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(_parseColor(workspace.colorHex)),
                        ),
                      ),
                      // Progress text
                      Text(
                        '${(value * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Workspace Info
        Text(
          workspace.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$remainingTasks задач',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(double progress, double size, double strokeWidth, double textSize) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: strokeWidth,
            backgroundColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
            valueColor: AlwaysStoppedAnimation<Color>(_parseColor(workspace.colorHex)),
          ),
          Text(
            '${progress.toInt()}%',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate progress percentage safely
  double _calculateProgress(int completedTasks, int totalTasks) {
    if (totalTasks <= 0) return 100.0; // If no tasks, consider it 100% complete
    return (completedTasks / totalTasks * 100).clamp(0.0, 100.0);
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
