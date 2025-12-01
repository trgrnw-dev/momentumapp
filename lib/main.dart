import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'core/di.dart';
import 'core/theme_provider.dart';
import 'core/app_state_provider.dart';
import 'core/router.dart';
import 'presentation/themes/dark_theme.dart';
import 'presentation/themes/light_theme.dart';
import 'data/services/notification_service.dart';
import 'data/services/github_sync_service.dart';

/// Main entry point of the Momentum app
/// Initializes dependencies and runs the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Declare GitHub Sync Service
  late GitHubSyncService githubSyncService;

  try {
    debugPrint('Momentum: Starting app initialization...');
    
    // Initialize dependency injection and SQLite database
    debugPrint('Momentum: Initializing DI...');
    await DI.init();
    debugPrint('Momentum: DI initialized successfully');

    // Initialize GitHub Sync Service AFTER DI is ready
    githubSyncService = GitHubSyncService();

    // Initialize theme provider
    debugPrint('Momentum: Initializing theme provider...');
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();
    debugPrint('Momentum: Theme provider initialized');

    // Initialize app state provider
    debugPrint('Momentum: Initializing app state provider...');
    final appStateProvider = AppStateProvider();
    await appStateProvider.initialize();
    debugPrint('Momentum: App state provider initialized');

    // Initialize localization
    debugPrint('Momentum: Initializing localization...');
    await EasyLocalization.ensureInitialized();
    debugPrint('Momentum: Localization initialized');

    // Initialize notification service
    debugPrint('Momentum: Initializing notification service...');
    try {
      final notificationService = NotificationService();
      debugPrint('Momentum: NotificationService created');
      
      await notificationService.initialize(
        onNotificationTapped: (payload) {
          debugPrint('Notification tapped with payload: $payload');
          // Handle notification tap - navigate to task details
          if (payload != null && payload.startsWith('task_')) {
            final taskId = int.tryParse(payload.split('_')[1]);
            if (taskId != null) {
              // Navigate to task details
              debugPrint('Navigate to task: $taskId');
            }
          }
        },
      );
      debugPrint('Momentum: Notification service initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Momentum: Notification service failed to initialize: $e');
      debugPrint('Momentum: Notification service stack trace: $stackTrace');
      debugPrint('Momentum: Continuing without notifications...');
      // Continue without notifications - app will work without notifications
    }

    // Initialize GitHub Sync Service with error handling
    debugPrint('Momentum: Initializing GitHub sync service...');
    try {
      debugPrint('Momentum: Checking DI repositories...');
      debugPrint('Momentum: taskRepository: ${DI.taskRepository}');
      debugPrint('Momentum: workspaceRepository: ${DI.workspaceRepository}');
      debugPrint('Momentum: tagRepository: ${DI.tagRepository}');
      
      debugPrint('Momentum: Calling githubSyncService.initialize()...');
      await githubSyncService.initialize(
        taskRepository: DI.taskRepository,
        workspaceRepository: DI.workspaceRepository,
        tagRepository: DI.tagRepository,
        enableAutoSync: true, // Enabled for GitHub sync
      );
      debugPrint('Momentum: GitHub sync service initialized with auto-sync enabled');
    } catch (e) {
      debugPrint('Momentum: GitHub sync service failed to initialize: $e');
      debugPrint('Momentum: Stack trace: ${StackTrace.current}');
      debugPrint('Momentum: Continuing without GitHub sync...');
      // Continue without GitHub sync - app will work with local database only
    }
  } catch (e, stackTrace) {
    debugPrint('Momentum: Failed to initialize app: $e');
    debugPrint('Momentum: Stack trace: $stackTrace');
    // Continue anyway to show error screen
  }

  debugPrint('Momentum: Starting app...');
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ru')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ru'),
      child: MomentumApp(
        themeProvider: ThemeProvider(),
        appStateProvider: AppStateProvider(),
        githubSyncService: githubSyncService,
      ),
    ),
  );
}

/// Root widget of the application
class MomentumApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final AppStateProvider appStateProvider;
  final GitHubSyncService githubSyncService;

  const MomentumApp({
    super.key,
    required this.themeProvider,
    required this.appStateProvider,
    required this.githubSyncService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: appStateProvider),
        Provider.value(value: githubSyncService),
      ],
             child: MultiBlocProvider(
               providers: [
                 BlocProvider(create: (context) => DI.createTaskBloc()),
                 BlocProvider(create: (context) => DI.createWorkspaceBloc()),
                 BlocProvider(create: (context) => DI.createTagBloc()),
               ],
               child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp.router(
              title: 'Momentum',
              debugShowCheckedModeBanner: false,

              // Localization
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,

              // Theme configuration
              theme: lightTheme(),
              darkTheme: darkTheme(),
              themeMode: themeProvider.themeMode,

              // Router
              routerConfig: AppRouter.router,
            );
          },
        ),
      ),
    );
  }
}
