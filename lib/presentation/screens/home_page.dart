import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme_provider.dart';
import '../../core/app_state_provider.dart';
import '../../domain/entities/workspace.dart';
import '../blocs/workspace_bloc.dart';
import '../blocs/workspace_event.dart';
import '../blocs/workspace_state.dart';
import '../blocs/task_bloc.dart';
import '../blocs/task_state.dart';
import '../widgets/workspace_card.dart';
import '../utils/responsive_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WorkspaceBloc>().add(const LoadWorkspacesEvent());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
                  children: [
            _buildTopAppBar(theme, isDark),
            const SizedBox(height: 16),
            Consumer<AppStateProvider>(
              builder: (context, appState, child) {
                return appState.showSearch
                    ? TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          hintText: 'home.search_workspaces'.tr(),
                                          hintStyle: TextStyle(
                                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                                          ),
                                          prefixIcon: TweenAnimationBuilder<double>(
                                            duration: const Duration(milliseconds: 800),
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            builder: (context, value, child) {
                                              return Transform.rotate(
                                                angle: value * 2 * 3.14159,
                                                child: Icon(
                                                  Icons.search,
                                                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                                                ),
                                              );
                                            },
                                          ),
                                          suffixIcon: _searchQuery.isNotEmpty
                                              ? TweenAnimationBuilder<double>(
                                                  duration: const Duration(milliseconds: 200),
                                                  tween: Tween(begin: 0.0, end: 1.0),
                                                  builder: (context, value, child) {
                                                    return Transform.scale(
                                                      scale: value,
                                                      child: IconButton(
                                                        icon: Icon(
                                                          Icons.clear,
                                                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                                                        ),
                                                        onPressed: () {
                                                          _searchController.clear();
                                                          setState(() {
                                                            _searchQuery = '';
                                                            _showSearchResults = false;
                                                          });
                                                        },
                                                      ),
                                                    );
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
                                            _showSearchResults = query.isNotEmpty;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : const SizedBox(height: 20);
              },
            ),
            Expanded(
              child: BlocListener<TaskBloc, TaskState>(
                listener: (context, state) {
                  if (state is TaskOperationSuccess || state is TaskLoaded) {
                    context.read<WorkspaceBloc>().add(const LoadWorkspacesEvent());
                  }
                },
                child: BlocConsumer<WorkspaceBloc, WorkspaceState>(
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
                builder: (context, state) {
                  if (state is WorkspaceLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (state is WorkspaceEmpty) {
                    return _buildEmptyState();
                  }
                  
                  if (state is WorkspaceError) {
                    return _buildErrorState(state.message);
                  }
                  
                  if (state is WorkspaceLoaded || state is WorkspaceOperationSuccess) {
                    final workspaces = state is WorkspaceLoaded
                        ? state.workspaces
                        : (state as WorkspaceOperationSuccess).workspaces;
                    
                    final filteredWorkspaces = _showSearchResults 
                        ? _filterWorkspaces(workspaces, _searchQuery)
                        : workspaces;
                    
                    return _buildWorkspaceContent(filteredWorkspaces, theme, isDark);
                  }
                  
                  return _buildEmptyState();
                },
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
      padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.task_alt,
                  color: Color(0xFF137FEC),
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Momentum',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Consumer<AppStateProvider>(
                builder: (context, appState, child) {
                  return TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.9 + (0.1 * value),
                        child: GestureDetector(
                          onTap: () {
                            appState.setWorkspaceViewMode(
                              appState.workspaceViewMode == 'grid' ? 'list' : 'grid'
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return RotationTransition(
                                  turns: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Icon(
                                appState.workspaceViewMode == 'grid' ? Icons.list : Icons.grid_view,
                                key: ValueKey(appState.workspaceViewMode),
                                color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return GestureDetector(
                    onTap: () => themeProvider.toggleTheme(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.go('/settings'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: theme.colorScheme.primary,
                  ),
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceContent(List<Workspace> workspaces, ThemeData theme, bool isDark) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
              child: ResponsiveHelper.responsiveContainer(
                context: context,
                padding: ResponsiveHelper.responsivePadding(
                  context,
                  mobile: const EdgeInsets.symmetric(horizontal: 16),
                  tablet: const EdgeInsets.symmetric(horizontal: 24),
                  desktop: const EdgeInsets.symmetric(horizontal: 32),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: appState.workspaceViewMode == 'grid'
                      ? _buildGridView(workspaces, theme, isDark)
                      : _buildListView(workspaces, theme, isDark),
                ),
              ),
            ),
            if (workspaces.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildCreateWorkspaceButton(theme),
              const SizedBox(height: 20),
            ],
          ],
        );
      },
    );
  }

  Widget _buildGridView(List<Workspace> workspaces, ThemeData theme, bool isDark) {
    return ResponsiveHelper.responsiveBuilder(
      context,
      mobile: (context) => _buildMobileGridView(workspaces, theme, isDark),
      tablet: (context) => _buildTabletGridView(workspaces, theme, isDark),
      desktop: (context) => _buildDesktopGridView(workspaces, theme, isDark),
    );
  }

  Widget _buildMobileGridView(List<Workspace> workspaces, ThemeData theme, bool isDark) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: workspaces.length,
      itemBuilder: (context, index) {
        final workspace = workspaces[index];
        return WorkspaceCard(
          workspace: workspace,
          isDark: isDark,
          onTap: () => _showWorkspaceOptions(workspace),
        );
      },
    );
  }

  Widget _buildTabletGridView(List<Workspace> workspaces, ThemeData theme, bool isDark) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: workspaces.length,
      itemBuilder: (context, index) {
        final workspace = workspaces[index];
        return WorkspaceCard(
          workspace: workspace,
          isDark: isDark,
          onTap: () => _showWorkspaceOptions(workspace),
        );
      },
    );
  }

  Widget _buildDesktopGridView(List<Workspace> workspaces, ThemeData theme, bool isDark) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: workspaces.length,
      itemBuilder: (context, index) {
        final workspace = workspaces[index];
        return WorkspaceCard(
          workspace: workspace,
          isDark: isDark,
          onTap: () => _showWorkspaceOptions(workspace),
        );
      },
    );
  }


  Widget _buildListView(List<Workspace> workspaces, ThemeData theme, bool isDark) {
    return ListView.builder(
      itemCount: workspaces.length,
                  itemBuilder: (context, index) {
        final workspace = workspaces[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            final clampedValue = value.clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, 50 * (1 - clampedValue)),
              child: Transform.scale(
                scale: 0.8 + (0.2 * clampedValue),
                child: Opacity(
                  opacity: clampedValue,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: _buildWorkspaceListCard(workspace, theme, isDark),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildCreateWorkspaceButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              context.go('/create-workspace');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF137FEC),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFF137FEC).withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'workspaces.create'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: (1 - value) * 0.3,
                        child: Icon(
                          Icons.folder_open,
                          size: 100,
                          color: const Color(0xFF137FEC).withValues(alpha: 0.3),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: Text(
                            'No Workspaces Yet',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: Text(
                            'Create your first workspace to get started',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1400),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.go('/create-workspace');
                            },
                            icon: const Icon(Icons.add),
                            label: Text('workspaces.create'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF137FEC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 100,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          Text(
            'Error Loading Workspaces',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.read<WorkspaceBloc>().add(const LoadWorkspacesEvent());
            },
            icon: const Icon(Icons.refresh),
            label: Text('buttons.retry'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF137FEC),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }


  IconData _parseIcon(String iconName) {
    switch (iconName) {
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
      case 'school':
        return Icons.school_rounded;
      case 'person':
        return Icons.person_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  void _showWorkspaceOptions(Workspace workspace) {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _parseColor(workspace.colorHex).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    _parseIcon(workspace.iconName),
                    color: _parseColor(workspace.colorHex),
                    size: 30,
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${workspace.totalTasks} tasks • ${workspace.completedTasks} completed',
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
            const SizedBox(height: 30),
            _buildOptionTile(
              icon: Icons.task_alt,
              title: 'home.open_tasks'.tr(),
              onTap: () {
                Navigator.pop(context);
                context.push('/workspace/${workspace.id}', extra: workspace);
              },
            ),
            _buildOptionTile(
              icon: Icons.edit,
              title: 'home.edit'.tr(),
              onTap: () {
                Navigator.pop(context);
                context.push('/edit-workspace/${workspace.id}');
              },
            ),
            _buildOptionTile(
              icon: Icons.delete,
              title: 'home.delete'.tr(),
              onTap: () {
                Navigator.pop(context);
                context.read<WorkspaceBloc>().add(DeleteWorkspaceEvent(workspace.id));
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
    );
  }



  Widget _buildWorkspaceListCard(Workspace workspace, ThemeData theme, bool isDark) {
    return WorkspaceCard(
      workspace: workspace,
      isDark: isDark,
      isListView: true,
      onTap: () => _showWorkspaceOptions(workspace),
    );
  }


  List<Workspace> _filterWorkspaces(List<Workspace> workspaces, String query) {
    if (query.isEmpty) return workspaces;
    
    return workspaces.where((workspace) {
      return workspace.name.toLowerCase().contains(query.toLowerCase()) ||
             (workspace.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  Color _parseColor(String hexColor) {
    try {
      String cleanHex = hexColor.replaceFirst('#', '');
      
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return const Color(0xFF137FEC);
    }
  }

}