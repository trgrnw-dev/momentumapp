import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../presentation/screens/home_page.dart';
import '../presentation/screens/workspace_tasks_page.dart';
import '../presentation/screens/create_task_page.dart';
import '../presentation/screens/task_details_page.dart';
import '../presentation/screens/create_workspace_screen.dart';
import '../presentation/screens/create_tag_page.dart';
import '../presentation/screens/tags_page.dart';
import '../presentation/screens/settings_page.dart';
import '../presentation/screens/github_sync_page.dart';
import '../domain/entities/workspace.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Home route
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      
      // Workspace tasks route
      GoRoute(
        path: '/workspace/:workspaceId',
        name: 'workspace-tasks',
        builder: (context, state) {
          final workspace = state.extra as Workspace?;
          if (workspace == null) {
            // Fallback to home if workspace is not provided
            return const HomePage();
          }
          return WorkspaceTasksPage(workspace: workspace);
        },
      ),
      
      // Create task route
      GoRoute(
        path: '/create-task',
        name: 'create-task',
        builder: (context, state) {
          final workspaceId = int.parse(state.uri.queryParameters['workspaceId']!);
          return CreateTaskPage(workspaceId: workspaceId);
        },
      ),
      
      // Edit task route
      GoRoute(
        path: '/edit-task/:taskId',
        name: 'edit-task',
        builder: (context, state) {
          final taskId = int.parse(state.pathParameters['taskId']!);
          // Get workspaceId from query parameters or default to 1
          final workspaceId = int.tryParse(state.uri.queryParameters['workspaceId'] ?? '1') ?? 1;
          return CreateTaskPage(taskId: taskId, workspaceId: workspaceId);
        },
      ),
      
      // Task details route
      GoRoute(
        path: '/task/:taskId',
        name: 'task-details',
        builder: (context, state) {
          final taskId = int.parse(state.pathParameters['taskId']!);
          return TaskDetailsPage(taskId: taskId);
        },
      ),
      
      
      // Create workspace route
      GoRoute(
        path: '/create-workspace',
        name: 'create-workspace',
        builder: (context, state) => const CreateWorkspaceScreen(),
      ),
      
      // Edit workspace route
      GoRoute(
        path: '/edit-workspace/:workspaceId',
        name: 'edit-workspace',
        builder: (context, state) {
          final workspaceId = int.parse(state.pathParameters['workspaceId']!);
          return CreateWorkspaceScreen(workspaceId: workspaceId);
        },
      ),
      
      // Create tag route
      GoRoute(
        path: '/create-tag',
        name: 'create-tag',
        builder: (context, state) => const CreateTagPage(),
      ),
      
      // Tags page route
      GoRoute(
        path: '/tags',
        name: 'tags',
        builder: (context, state) => const TagsPage(),
      ),
      
      // Settings route
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      
      // GitHub Sync route
      GoRoute(
        path: '/github-sync',
        name: 'github-sync',
        builder: (context, state) => GitHubSyncPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'router.page_not_found'.tr(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'router.path'.tr(namedArgs: {'path': state.uri.toString()}),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text('router.go_home'.tr()),
            ),
          ],
        ),
      ),
    ),
  );
}
