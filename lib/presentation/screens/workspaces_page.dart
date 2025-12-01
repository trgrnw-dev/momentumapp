import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/di.dart';
import '../../domain/entities/workspace.dart';
import '../blocs/workspace_bloc.dart';
import '../blocs/workspace_event.dart';
import '../blocs/workspace_state.dart';
import 'create_workspace_screen.dart';

class WorkspacesPage extends StatefulWidget {
  const WorkspacesPage({super.key});

  @override
  State<WorkspacesPage> createState() => _WorkspacesPageState();
}

class _WorkspacesPageState extends State<WorkspacesPage> {
  @override
  void initState() {
    super.initState();
    context.read<WorkspaceBloc>().add(const LoadWorkspacesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('workspaces.title'.tr()),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateWorkspace(),
            tooltip: 'workspaces.create'.tr(),
          ),
        ],
      ),
      body: BlocConsumer<WorkspaceBloc, WorkspaceState>(
        listener: (context, state) {
          if (state is WorkspaceOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is WorkspaceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is WorkspaceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WorkspaceEmpty) {
            return _buildEmptyState(state.message);
          }

          if (state is WorkspaceError) {
            return _buildErrorState(state.message);
          }

          if (state is WorkspaceLoaded || state is WorkspaceOperationSuccess) {
            final workspaces = state is WorkspaceLoaded
                ? state.workspaces
                : (state as WorkspaceOperationSuccess).workspaces;

            return _buildWorkspacesList(workspaces);
          }

          return _buildEmptyState('workspaces.no_workspaces'.tr());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateWorkspace(),
        icon: const Icon(Icons.add),
        label: Text('workspaces.new_workspace'.tr()),
      ),
    );
  }

  Widget _buildWorkspacesList(List<Workspace> workspaces) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workspaces.length,
      itemBuilder: (context, index) {
        return _buildWorkspaceCard(workspaces[index]);
      },
    );
  }

  Widget _buildWorkspaceCard(Workspace workspace) {
    final theme = Theme.of(context);
    final color = _parseColor(workspace.colorHex);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectWorkspace(workspace),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(workspace.iconName),
                  color: color,
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
                      workspace.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (workspace.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        workspace.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatChip(
                          'workspaces.tasks_count'.tr(namedArgs: {'count': workspace.totalTasks.toString()}),
                          theme,
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          'workspaces.completed_count'.tr(namedArgs: {'count': workspace.completedTasks.toString()}),
                          theme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editWorkspace(workspace);
                  } else if (value == 'delete') {
                    _deleteWorkspace(workspace);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('workspaces.edit_workspace'.tr()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('workspaces.delete_workspace'.tr(), style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: 100,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'workspaces.no_workspaces_desc'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 100,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            'messages.error_loading'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<WorkspaceBloc>().add(const LoadWorkspacesEvent());
            },
            icon: const Icon(Icons.refresh),
            label: Text('buttons.retry'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCreateWorkspace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => DI.createWorkspaceBloc(),
          child: const CreateWorkspaceScreen(),
        ),
      ),
    );

    if (result == true) {
      if (mounted) {
        context.read<WorkspaceBloc>().add(const LoadWorkspacesEvent());
      }
    }
  }

  void _selectWorkspace(Workspace workspace) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('workspaces_page.workspace_selected'.tr(namedArgs: {'name': workspace.name})),
      ),
    );
  }

  void _editWorkspace(Workspace workspace) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('workspaces_page.edit_coming_soon'.tr())),
    );
  }

  void _deleteWorkspace(Workspace workspace) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('workspaces.delete_workspace'.tr()),
        content: Text('workspaces.confirm_delete'.tr(namedArgs: {'name': workspace.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('buttons.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<WorkspaceBloc>().add(DeleteWorkspaceEvent(workspace.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('buttons.delete'.tr()),
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
      return const Color(0xFF137fec);
    }
  }

  IconData _getIconData(String iconName) {
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
      return Icons.workspace_premium;
    }
  }
}
