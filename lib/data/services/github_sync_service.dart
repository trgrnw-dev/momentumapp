import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/entities/tag.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../domain/repositories/tag_repository.dart';

/// GitHub Sync Service
/// Uses GitHub API for data synchronization
/// Stores data as JSON files in a GitHub repository
class GitHubSyncService {
  static final GitHubSyncService _instance = GitHubSyncService._internal();
  factory GitHubSyncService() => _instance;
  GitHubSyncService._internal() {
    // Initialize Dio immediately when service is created
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.github.com',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Momentum-App/1.0.0',
        },
      ),
    );
    
    // Add interceptors for better error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => debugPrint('Dio: $obj'),
    ));
    
    debugPrint('GitHubSyncService: Dio initialized');
  }

  late Dio _dio;
  final Connectivity _connectivity = Connectivity();

  // GitHub configuration
  String? _githubToken;
  String? _repositoryOwner;
  String? _repositoryName;
  String? _branchName;

  // Repositories
  TaskRepository? _taskRepository;
  WorkspaceRepository? _workspaceRepository;
  TagRepository? _tagRepository;

  // Sync state
  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _autoSyncEnabled = true;
  bool _dataClearedByUser = false;
  DateTime? _lastSyncTime;
  DateTime? _lastRateLimitHit;
  Timer? _autoSyncTimer;
  Timer? _debounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Data change listeners
  StreamSubscription? _taskChangesSubscription;
  StreamSubscription? _workspaceChangesSubscription;
  StreamSubscription? _tagChangesSubscription;

  final List<GitHubSyncOperation> _syncQueue = [];
  final StreamController<GitHubSyncStatus> _syncStatusController =
      StreamController<GitHubSyncStatus>.broadcast();

  /// Stream of sync status updates
  Stream<GitHubSyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if auto-sync is enabled (depends on online mode)
  bool get autoSyncEnabled => _autoSyncEnabled && _isOnlineModeEnabled();

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if GitHub is configured
  bool get isConfigured =>
      _githubToken != null &&
      _repositoryOwner != null &&
      _repositoryName != null;

  /// Initialize the GitHub sync service
  Future<void> initialize({
    required TaskRepository taskRepository,
    required WorkspaceRepository workspaceRepository,
    required TagRepository tagRepository,
    bool enableAutoSync = true,
  }) async {
    _taskRepository = taskRepository;
    _workspaceRepository = workspaceRepository;
    _tagRepository = tagRepository;
    _autoSyncEnabled = enableAutoSync;

    // Initialize GitHub sync on all platforms
    debugPrint('GitHubSyncService: Initializing GitHub sync service...');
    
    // Test basic connectivity first
    await _testBasicConnectivity();

    // Load GitHub configuration
    await _loadGitHubConfig();

    // Load sync settings
    await _loadSyncSettings();

    // Don't force reset to offline mode - respect saved settings
    debugPrint('GitHubSyncService: Sync enabled: $_syncEnabled');

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _onConnectivityChanged(results);
    });

    // Start auto-sync timer if enabled
    if (_autoSyncEnabled && isConfigured) {
      _startAutoSync();
    }

    // Setup data change listeners
    _setupDataChangeListeners();

    debugPrint('GitHubSyncService: Initialized');
  }

  /// Load sync settings from SharedPreferences
  Future<void> _loadSyncSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _syncEnabled =
        prefs.getBool('sync_enabled') ?? false; // Default to offline mode
    debugPrint('GitHubSyncService: Sync enabled: $_syncEnabled');
  }

  /// Load GitHub configuration from SharedPreferences
  Future<void> _loadGitHubConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _githubToken = prefs.getString('github_token');
    _repositoryOwner = prefs.getString('github_repo_owner');
    _repositoryName = prefs.getString('github_repo_name');
    _branchName = prefs.getString('github_branch') ?? 'main';
    _lastSyncTime = prefs.getString('last_sync_time') != null
        ? DateTime.parse(prefs.getString('last_sync_time')!)
        : null;

    // Update Dio headers with token
    if (_githubToken != null) {
      _dio.options.headers['Authorization'] = 'token $_githubToken';
    }
  }

  /// Configure GitHub repository
  Future<bool> configureGitHub({
    required String token,
    required String repositoryOwner,
    required String repositoryName,
    String branchName = 'main',
  }) async {
    // Configure GitHub on all platforms
    
    
    try {
      // Test GitHub connection
      _dio.options.headers['Authorization'] = 'token $token';
      final response = await _dio.get(
        '/repos/$repositoryOwner/$repositoryName',
      );

      if (response.statusCode == 200) {
        // Repository exists, save configuration
        await _saveConfiguration(token, repositoryOwner, repositoryName, branchName);
        debugPrint('GitHubSyncService: Configuration saved successfully');
        return true;
      }
    } catch (e) {
      // Handle network errors gracefully
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionError || 
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          debugPrint('GitHubSyncService: Network error - will retry later: $e');
          // Save configuration anyway for offline mode
          await _saveConfiguration(token, repositoryOwner, repositoryName, branchName);
          return true;
        } else if (e.response?.statusCode == 404) {
          debugPrint('GitHubSyncService: Repository not found, attempting to create...');
          try {
            final createResponse = await _dio.post(
              '/user/repos',
              data: {
                'name': repositoryName,
                'description': 'Momentum app data synchronization repository',
                'private': true,
                'auto_init': true,
              },
            );
            
            if (createResponse.statusCode == 201) {
              debugPrint('GitHubSyncService: Repository created successfully');
              await _saveConfiguration(token, repositoryOwner, repositoryName, branchName);
              return true;
            }
          } catch (createError) {
            debugPrint('GitHubSyncService: Failed to create repository: $createError');
          }
        }
      }
      debugPrint('GitHubSyncService: Configuration failed: $e');
    }
    return false;
  }

  /// Save GitHub configuration
  Future<void> _saveConfiguration(String token, String repositoryOwner, String repositoryName, String branchName) async {
    try {
      debugPrint('GitHubSyncService: Saving configuration...');
      final prefs = await SharedPreferences.getInstance();
      
      // Save each setting individually with error handling
      final tokenResult = await prefs.setString('github_token', token);
      final ownerResult = await prefs.setString('github_repo_owner', repositoryOwner);
      final nameResult = await prefs.setString('github_repo_name', repositoryName);
      final branchResult = await prefs.setString('github_branch', branchName);
      
      if (!tokenResult || !ownerResult || !nameResult || !branchResult) {
        debugPrint('GitHubSyncService: Failed to save some configuration settings');
        throw Exception('Failed to save configuration to SharedPreferences');
      }
      
      debugPrint('GitHubSyncService: Configuration saved successfully');

      _githubToken = token;
      _repositoryOwner = repositoryOwner;
      _repositoryName = repositoryName;
      _branchName = branchName;

      // Update Dio headers
      _dio.options.headers['Authorization'] = 'token $token';

      // Start auto-sync if enabled
      if (_autoSyncEnabled) {
        _startAutoSync();
      }
    } catch (e) {
      debugPrint('GitHubSyncService: Failed to save configuration: $e');
      rethrow;
    }
  }

  /// Create a new GitHub repository for Momentum data
  Future<bool> createMomentumRepository({
    required String token,
    required String repositoryName,
    String description = 'Momentum Task Management Data',
    bool isPrivate = true,
  }) async {
    if (!_isInitialized) {
      debugPrint('GitHubSyncService: Not initialized');
      return false;
    }

    try {
      _dio.options.headers['Authorization'] = 'token $token';

      final response = await _dio.post(
        '/user/repos',
        data: {
          'name': repositoryName,
          'description': description,
          'private': isPrivate,
          'auto_init': false,
        },
      );

      if (response.statusCode == 201) {
        final repoData = response.data;
        return await configureGitHub(
          token: token,
          repositoryOwner: repoData['owner']['login'],
          repositoryName: repositoryName,
        );
      }
    } catch (e) {
      // Check if repository already exists (422 error)
      if (e is DioException && e.response?.statusCode == 422) {
        debugPrint(
          'GitHubSyncService: Repository already exists, trying to configure...',
        );
        return await configureGitHub(
          token: token,
          repositoryOwner: await _getCurrentUser(token),
          repositoryName: repositoryName,
        );
      }
      debugPrint('GitHubSyncService: Repository creation failed: $e');
    }
    return false;
  }

  /// Get current GitHub user
  Future<String> _getCurrentUser(String token) async {
    try {
      final response = await _dio.get('/user');
      return response.data['login'];
    } catch (e) {
      debugPrint('GitHubSyncService: Failed to get current user: $e');
      return 'unknown';
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (hasConnection && _autoSyncEnabled && !_isSyncing && isConfigured) {
      debugPrint('GitHubSyncService: Network restored, starting sync');
      syncAll();
    }
  }

  /// Start automatic sync timer
  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(minutes: 30), // Sync every 30 minutes
      (_) {
        if (_autoSyncEnabled &&
            !_isSyncing &&
            isConfigured &&
            _isOnlineModeEnabled()) {
          syncAll();
        }
      },
    );
    debugPrint('GitHubSyncService: Auto-sync started (30 min interval)');
  }

  /// Stop automatic sync timer
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    debugPrint('GitHubSyncService: Auto-sync stopped');
  }

  /// Enable or disable auto-sync
  Future<void> setAutoSync(bool enabled) async {
    _autoSyncEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('github_auto_sync', enabled);

    if (enabled && isConfigured) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }
  }

  /// Test basic connectivity to GitHub
  Future<void> _testBasicConnectivity() async {
    try {
      debugPrint('GitHubSyncService: Testing basic connectivity...');
      
      // Test with a simple HTTP request first
      final testDio = Dio();
      testDio.options.connectTimeout = const Duration(seconds: 10);
      testDio.options.receiveTimeout = const Duration(seconds: 10);
      
      final response = await testDio.get('https://api.github.com');
      debugPrint('GitHubSyncService: Basic connectivity test successful: ${response.statusCode}');
    } catch (e) {
      debugPrint('GitHubSyncService: Basic connectivity test failed: $e');
      if (e is SocketException) {
        debugPrint('GitHubSyncService: Socket error details: ${e.message}');
        debugPrint('GitHubSyncService: Error code: ${e.osError?.errorCode}');
        debugPrint('GitHubSyncService: This indicates macOS network permissions issue');
      }
    }
  }

  /// Check internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  /// Sync all data with GitHub
  Future<GitHubSyncResult> syncAll() async {
    // Sync on all platforms
    
    if (_isSyncing) {
      debugPrint('GitHubSyncService: Sync already in progress');
      return GitHubSyncResult(
        success: false,
        message: 'Sync already in progress',
      );
    }

    if (!isConfigured) {
      debugPrint('GitHubSyncService: GitHub not configured');
      return GitHubSyncResult(success: false, message: 'GitHub not configured');
    }

    if (!_isOnlineModeEnabled()) {
      debugPrint('GitHubSyncService: Cannot sync - offline mode enabled');
      return GitHubSyncResult(success: false, message: 'Offline mode enabled');
    }

    if (!await hasInternetConnection()) {
      debugPrint('GitHubSyncService: No internet connection');
      _syncStatusController.add(
        GitHubSyncStatus(
          state: GitHubSyncState.failed,
          message: 'No internet connection',
        ),
      );
      return GitHubSyncResult(
        success: false,
        message: 'No internet connection',
      );
    }

    // Check for network connectivity issues
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        debugPrint('GitHubSyncService: No network connectivity');
        _syncStatusController.add(
          GitHubSyncStatus(
            state: GitHubSyncState.failed,
            message: 'No network connectivity',
          ),
        );
        return GitHubSyncResult(
          success: false,
          message: 'No network connectivity',
        );
      }
    } catch (e) {
      debugPrint('GitHubSyncService: Error checking connectivity: $e');
      // Continue with sync attempt anyway
    }

    _isSyncing = true;
    _syncStatusController.add(
      GitHubSyncStatus(
        state: GitHubSyncState.syncing,
        message: 'Syncing with GitHub...',
      ),
    );

    try {
      debugPrint('========================================');
      debugPrint('GitHubSyncService: Starting syncAll()');
      debugPrint('========================================');
      debugPrint('GitHubSyncService: Checking online mode - _syncEnabled: $_syncEnabled');
      debugPrint('GitHubSyncService: Configuration:');
      debugPrint('  - Repository Owner: $_repositoryOwner');
      debugPrint('  - Repository Name: $_repositoryName');
      debugPrint('  - Branch: $_branchName');

      // Get current commit SHA
      debugPrint('GitHubSyncService: Getting current commit SHA...');
      final currentCommit = await _getCurrentCommit();
      debugPrint('GitHubSyncService: Current commit SHA: $currentCommit');

      // Check if local database is empty
      if (_taskRepository == null || _workspaceRepository == null || _tagRepository == null) {
        throw Exception('Repositories not initialized');
      }
      
      final localTasks = await _taskRepository!.getAllTasks();
      final localWorkspaces = await _workspaceRepository!.getAllWorkspaces();
      final localTags = await _tagRepository!.getAllTags();
      
      final isLocalEmpty = localTasks.isEmpty && localWorkspaces.isEmpty && localTags.isEmpty;
      
      if (isLocalEmpty) {
        debugPrint('GitHubSyncService: Local database is empty, loading from GitHub...');
        await _loadDataFromGitHub();
        debugPrint('GitHubSyncService: Data loaded from GitHub');
      } else {
        debugPrint('GitHubSyncService: Local database has data, syncing to GitHub...');
      }

      // Sync tasks
      debugPrint('GitHubSyncService: Starting tasks sync...');
      await _syncTasksToGitHub(currentCommit);
      debugPrint('GitHubSyncService: Tasks sync completed');

      // Sync workspaces
      debugPrint('GitHubSyncService: Starting workspaces sync...');
      await _syncWorkspacesToGitHub(currentCommit);
      debugPrint('GitHubSyncService: Workspaces sync completed');

      // Sync tags
      debugPrint('GitHubSyncService: Starting tags sync...');
      await _syncTagsToGitHub(currentCommit);
      debugPrint('GitHubSyncService: Tags sync completed');

      // Update last sync time
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', _lastSyncTime!.toIso8601String());

      _isSyncing = false;
      _syncStatusController.add(
        GitHubSyncStatus(
          state: GitHubSyncState.completed,
          message: 'GitHub sync completed successfully',
          lastSyncTime: _lastSyncTime,
        ),
      );

      debugPrint('=======================================');
      debugPrint('GitHubSyncService: ✓✓✓ Sync completed successfully ✓✓✓');
      debugPrint('=======================================');
      debugPrint('');
      return GitHubSyncResult(success: true, message: 'GitHub sync completed');
    } catch (e) {
      _isSyncing = false;
      debugPrint('=======================================');
      debugPrint('GitHubSyncService: SYNC FAILED!');
      debugPrint('Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      debugPrint('=======================================');
      debugPrint('');
      
      String errorMessage = 'GitHub sync failed';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionError) {
          debugPrint('GitHubSyncService: Connection error details: ${e.message}');
          if (e.error is SocketException) {
            final socketError = e.error as SocketException;
            debugPrint('GitHubSyncService: Socket error: ${socketError.message}');
            debugPrint('GitHubSyncService: Error code: ${socketError.osError?.errorCode}');
            
            if (socketError.message.contains('Failed host lookup')) {
              errorMessage = 'DNS resolution failed - check your internet connection';
            } else if (socketError.message.contains('Connection refused')) {
              errorMessage = 'Connection refused - check firewall settings';
            } else if (socketError.osError?.errorCode == 7) {
              errorMessage = 'No internet connection - please check your network';
            } else if (socketError.osError?.errorCode == 1) {
              errorMessage = 'Network permission denied - please check app permissions';
            } else {
              errorMessage = 'Network error: ${socketError.message}';
            }
          } else {
            errorMessage = 'Connection error - check your internet connection';
          }
        } else if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timeout - try again later';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Receive timeout - try again later';
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Authentication failed - check your GitHub token';
        } else if (e.response?.statusCode == 403) {
          _lastRateLimitHit = DateTime.now();
          errorMessage = 'GitHub API rate limit exceeded - waiting 1 hour before retry';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Repository not found - check repository name';
        } else {
          errorMessage = 'GitHub API error: ${e.response?.statusCode}';
        }
      } else if (e is SocketException) {
        errorMessage = 'Network error - check your internet connection and macOS network permissions';
        debugPrint('GitHubSyncService: Socket error: ${e.message}');
        debugPrint('GitHubSyncService: Error code: ${e.osError?.errorCode}');
      }
      
      _syncStatusController.add(
        GitHubSyncStatus(
          state: GitHubSyncState.failed,
          message: errorMessage,
        ),
      );
      return GitHubSyncResult(
        success: false,
        message: errorMessage,
      );
    }
  }

  /// Get current commit SHA
  Future<String> _getCurrentCommit() async {
    final response = await _dio.get(
      '/repos/$_repositoryOwner/$_repositoryName/git/refs/heads/$_branchName',
    );
    return response.data['object']['sha'];
  }

  /// Load data from GitHub
  Future<void> _loadDataFromGitHub() async {
    try {
      // Load tasks
      await _loadTasksFromGitHub();

      // Load workspaces
      await _loadWorkspacesFromGitHub();

      // Load tags
      await _loadTagsFromGitHub();

      debugPrint('GitHubSyncService: All data loaded from GitHub successfully');
    } catch (e, stackTrace) {
      debugPrint('GitHubSyncService: Error loading data from GitHub: $e');
      debugPrint('GitHubSyncService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Load tasks from GitHub
  Future<void> _loadTasksFromGitHub() async {
    try {
      debugPrint('GitHubSyncService: [LOAD] Fetching tasks from GitHub...');

      final response = await _dio.get(
        '/repos/$_repositoryOwner/$_repositoryName/contents/data/tasks.json',
      );

      if (response.statusCode == 200) {
        final content = response.data['content'] as String;
        debugPrint(
          'GitHubSyncService: [LOAD] Raw content length: ${content.length}',
        );

        // Clean the content (remove newlines and spaces)
        final cleanContent = content.replaceAll(RegExp(r'\s+'), '');
        debugPrint(
          'GitHubSyncService: [LOAD] Clean content length: ${cleanContent.length}',
        );

        final decodedContent = utf8.decode(base64Decode(cleanContent));
        debugPrint(
          'GitHubSyncService: [LOAD] Decoded content: ${decodedContent.substring(0, 100)}...',
        );

        final jsonData = jsonDecode(decodedContent) as Map<String, dynamic>;

        final tasksJson = jsonData['tasks'] as List<dynamic>? ?? [];
        debugPrint(
          'GitHubSyncService: [LOAD] Found ${tasksJson.length} tasks on GitHub',
        );

        // Check if local database is empty before loading from GitHub
        final localTasks = await _taskRepository!.getAllTasks();
        
        if (tasksJson.isNotEmpty && localTasks.isEmpty && !_wasDataClearedByUser()) {
          debugPrint('GitHubSyncService: [LOAD] Local database is empty, loading from GitHub...');

          // Convert and save tasks to local database
          for (final taskJson in tasksJson) {
            final task = _taskFromJson(taskJson as Map<String, dynamic>);
            await _taskRepository!.createTask(task);
          }

          debugPrint('GitHubSyncService: [LOAD] ✓ Tasks loaded from GitHub');
        } else if (_wasDataClearedByUser()) {
          debugPrint(
            'GitHubSyncService: [LOAD] Skipping tasks load - data was cleared by user',
          );
        } else if (localTasks.isNotEmpty) {
          debugPrint('GitHubSyncService: [LOAD] Local database has tasks, skipping GitHub load');
        } else {
          debugPrint('GitHubSyncService: [LOAD] No tasks found on GitHub');
        }
      } else {
        debugPrint('GitHubSyncService: [LOAD] No tasks file found on GitHub');
      }
    } catch (e) {
      debugPrint('GitHubSyncService: [LOAD] Error loading tasks: $e');
      // Don't rethrow - continue with other data
    }
  }

  /// Load workspaces from GitHub
  Future<void> _loadWorkspacesFromGitHub() async {
    try {
      debugPrint(
        'GitHubSyncService: [LOAD] Fetching workspaces from GitHub...',
      );

      final response = await _dio.get(
        '/repos/$_repositoryOwner/$_repositoryName/contents/data/workspaces.json',
      );

      if (response.statusCode == 200) {
        final content = response.data['content'] as String;
        debugPrint(
          'GitHubSyncService: [LOAD] Raw content length: ${content.length}',
        );

        // Clean the content (remove newlines and spaces)
        final cleanContent = content.replaceAll(RegExp(r'\s+'), '');
        debugPrint(
          'GitHubSyncService: [LOAD] Clean content length: ${cleanContent.length}',
        );

        final decodedContent = utf8.decode(base64Decode(cleanContent));
        debugPrint(
          'GitHubSyncService: [LOAD] Decoded content: ${decodedContent.substring(0, 100)}...',
        );

        final jsonData = jsonDecode(decodedContent) as Map<String, dynamic>;

        final workspacesJson = jsonData['workspaces'] as List<dynamic>? ?? [];
        debugPrint(
          'GitHubSyncService: [LOAD] Found ${workspacesJson.length} workspaces on GitHub',
        );

        // Check if local database is empty before loading from GitHub
        final localWorkspaces = await _workspaceRepository!.getAllWorkspaces();
        
        if (workspacesJson.isNotEmpty && localWorkspaces.isEmpty && !_wasDataClearedByUser()) {
          debugPrint(
            'GitHubSyncService: [LOAD] Local database is empty, loading from GitHub...',
          );

          // Convert and save workspaces to local database
          for (final workspaceJson in workspacesJson) {
            final workspace = _workspaceFromJson(
              workspaceJson as Map<String, dynamic>,
            );
            await _workspaceRepository!.createWorkspace(workspace);
          }

          debugPrint(
            'GitHubSyncService: [LOAD] ✓ Workspaces loaded from GitHub',
          );
        } else if (_wasDataClearedByUser()) {
          debugPrint(
            'GitHubSyncService: [LOAD] Skipping workspaces load - data was cleared by user',
          );
        } else if (localWorkspaces.isNotEmpty) {
          debugPrint('GitHubSyncService: [LOAD] Local database has workspaces, skipping GitHub load');
        } else {
          debugPrint('GitHubSyncService: [LOAD] No workspaces found on GitHub');
        }
      } else {
        debugPrint(
          'GitHubSyncService: [LOAD] No workspaces file found on GitHub',
        );
      }
    } catch (e) {
      debugPrint('GitHubSyncService: [LOAD] Error loading workspaces: $e');
      // Don't rethrow - continue with other data
    }
  }

  /// Load tags from GitHub
  Future<void> _loadTagsFromGitHub() async {
    try {
      debugPrint('GitHubSyncService: [LOAD] Fetching tags from GitHub...');

      final response = await _dio.get(
        '/repos/$_repositoryOwner/$_repositoryName/contents/data/tags.json',
      );

      if (response.statusCode == 200) {
        final content = response.data['content'] as String;
        debugPrint(
          'GitHubSyncService: [LOAD] Raw content length: ${content.length}',
        );

        // Clean the content (remove newlines and spaces)
        final cleanContent = content.replaceAll(RegExp(r'\s+'), '');
        debugPrint(
          'GitHubSyncService: [LOAD] Clean content length: ${cleanContent.length}',
        );

        final decodedContent = utf8.decode(base64Decode(cleanContent));
        debugPrint(
          'GitHubSyncService: [LOAD] Decoded content: ${decodedContent.substring(0, 100)}...',
        );

        final jsonData = jsonDecode(decodedContent) as Map<String, dynamic>;

        final tagsJson = jsonData['tags'] as List<dynamic>? ?? [];
        debugPrint(
          'GitHubSyncService: [LOAD] Found ${tagsJson.length} tags on GitHub',
        );

        // Check if local database is empty before loading from GitHub
        final localTags = await _tagRepository!.getAllTags();
        
        if (tagsJson.isNotEmpty && localTags.isEmpty && !_wasDataClearedByUser()) {
          debugPrint('GitHubSyncService: [LOAD] Local database is empty, loading from GitHub...');

          // Convert and save tags to local database
          for (final tagJson in tagsJson) {
            final tag = _tagFromJson(tagJson as Map<String, dynamic>);
            await _tagRepository!.createTag(tag);
          }

          debugPrint('GitHubSyncService: [LOAD] ✓ Tags loaded from GitHub');
        } else if (_wasDataClearedByUser()) {
          debugPrint(
            'GitHubSyncService: [LOAD] Skipping tags load - data was cleared by user',
          );
        } else if (localTags.isNotEmpty) {
          debugPrint('GitHubSyncService: [LOAD] Local database has tags, skipping GitHub load');
        } else {
          debugPrint('GitHubSyncService: [LOAD] No tags found on GitHub');
        }
      } else {
        debugPrint('GitHubSyncService: [LOAD] No tags file found on GitHub');
      }
    } catch (e) {
      debugPrint('GitHubSyncService: [LOAD] Error loading tags: $e');
      // Don't rethrow - continue with other data
    }
  }

  /// Sync tasks to GitHub
  Future<void> _syncTasksToGitHub(String currentCommit) async {
    try {
      debugPrint('GitHubSyncService: [TASKS] Fetching local tasks...');
      final localTasks = await _taskRepository!.getAllTasks();
      debugPrint('GitHubSyncService: [TASKS] Found ${localTasks.length} local tasks');
      
      // Always sync tasks, even if empty
      final tasksJson = {
        'tasks': localTasks.map((task) => _taskToJson(task)).toList(),
        'last_updated': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };

      final jsonString = jsonEncode(tasksJson);
      debugPrint('GitHubSyncService: [TASKS] JSON size: ${jsonString.length} bytes');

      // If no tasks, delete the file from GitHub
      if (localTasks.isEmpty) {
        debugPrint(
          'GitHubSyncService: [TASKS] No local tasks - deleting file from GitHub',
        );
        _markDataClearedByUser();
        await _deleteFileFromGitHub(
          path: 'data/tasks.json',
          message: 'Delete tasks - ${DateTime.now().toIso8601String()}',
          currentCommit: currentCommit,
        );
        debugPrint(
          'GitHubSyncService: [TASKS] ✓ Tasks file deleted from GitHub',
        );
        return;
      }

      // Always update the file with current tasks
      await _updateFileInGitHub(
        path: 'data/tasks.json',
        content: jsonString,
        message: 'Update tasks - ${DateTime.now().toIso8601String()}',
        currentCommit: currentCommit,
      );

      debugPrint('GitHubSyncService: [TASKS] ✓ Tasks synced to GitHub successfully');
      _resetDataClearedFlag();
    } catch (e) {
      debugPrint('GitHubSyncService: [TASKS] ✗ Error syncing tasks: $e');
      debugPrint('GitHubSyncService: [TASKS] Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Sync workspaces to GitHub
  Future<void> _syncWorkspacesToGitHub(String currentCommit) async {
    try {
      debugPrint('GitHubSyncService: [WORKSPACES] Fetching local workspaces...');
      final localWorkspaces = await _workspaceRepository!.getAllWorkspaces();
      debugPrint('GitHubSyncService: [WORKSPACES] Found ${localWorkspaces.length} local workspaces');
      
      // Always sync workspaces, even if empty
      final workspacesJson = {
        'workspaces': localWorkspaces
            .map((workspace) => _workspaceToJson(workspace))
            .toList(),
        'last_updated': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };

      final jsonString = jsonEncode(workspacesJson);
      debugPrint('GitHubSyncService: [WORKSPACES] JSON size: ${jsonString.length} bytes');

      // If no workspaces, delete the file from GitHub
      if (localWorkspaces.isEmpty) {
        debugPrint(
          'GitHubSyncService: [WORKSPACES] No local workspaces - deleting file from GitHub',
        );
        _markDataClearedByUser();
        await _deleteFileFromGitHub(
          path: 'data/workspaces.json',
          message: 'Delete workspaces - ${DateTime.now().toIso8601String()}',
          currentCommit: currentCommit,
        );
        debugPrint(
          'GitHubSyncService: [WORKSPACES] ✓ Workspaces file deleted from GitHub',
        );
        return;
      }

      // Always update the file with current workspaces
      await _updateFileInGitHub(
        path: 'data/workspaces.json',
        content: jsonString,
        message: 'Update workspaces - ${DateTime.now().toIso8601String()}',
        currentCommit: currentCommit,
      );

      debugPrint('GitHubSyncService: [WORKSPACES] ✓ Workspaces synced to GitHub successfully');
      _resetDataClearedFlag();
    } catch (e) {
      debugPrint('GitHubSyncService: [WORKSPACES] ✗ Error syncing workspaces: $e');
      debugPrint('GitHubSyncService: [WORKSPACES] Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Sync tags to GitHub
  Future<void> _syncTagsToGitHub(String currentCommit) async {
    try {
      debugPrint('GitHubSyncService: [TAGS] Fetching local tags...');
      final localTags = await _tagRepository!.getAllTags();
      debugPrint('GitHubSyncService: [TAGS] Found ${localTags.length} local tags');
      
      // Always sync tags, even if empty
      final tagsJson = {
        'tags': localTags.map((tag) => _tagToJson(tag)).toList(),
        'last_updated': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };

      final jsonString = jsonEncode(tagsJson);
      debugPrint('GitHubSyncService: [TAGS] JSON size: ${jsonString.length} bytes');

      // If no tags, delete the file from GitHub
      if (localTags.isEmpty) {
        debugPrint(
          'GitHubSyncService: [TAGS] No local tags - deleting file from GitHub',
        );
        _markDataClearedByUser();
        await _deleteFileFromGitHub(
          path: 'data/tags.json',
          message: 'Delete tags - ${DateTime.now().toIso8601String()}',
          currentCommit: currentCommit,
        );
        debugPrint('GitHubSyncService: [TAGS] ✓ Tags file deleted from GitHub');
        return;
      }

      // Always update the file with current tags
      await _updateFileInGitHub(
        path: 'data/tags.json',
        content: jsonString,
        message: 'Update tags - ${DateTime.now().toIso8601String()}',
        currentCommit: currentCommit,
      );

      debugPrint('GitHubSyncService: [TAGS] ✓ Tags synced to GitHub successfully');
      _resetDataClearedFlag();
    } catch (e) {
      debugPrint('GitHubSyncService: [TAGS] ✗ Error syncing tags: $e');
      debugPrint('GitHubSyncService: [TAGS] Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Update file in GitHub repository
  Future<void> _updateFileInGitHub({
    required String path,
    required String content,
    required String message,
    required String currentCommit,
  }) async {
    debugPrint('');
    debugPrint('┌─────────────────────────────────────────');
    debugPrint('│ UPDATE FILE: $path');
    debugPrint('└─────────────────────────────────────────');
    debugPrint('  Repository: $_repositoryOwner/$_repositoryName');
    debugPrint('  Branch: $_branchName');
    debugPrint('  Commit SHA: $currentCommit');
    debugPrint('  Content size: ${content.length} chars');
    debugPrint('  Message: $message');

    try {
      // Get file SHA if it exists
      String? fileSha;
      debugPrint('  → Checking if file exists...');
      try {
        final fileResponse = await _dio.get(
          '/repos/$_repositoryOwner/$_repositoryName/contents/$path',
          queryParameters: {'ref': _branchName},
        );
        fileSha = fileResponse.data['sha'];
        debugPrint('  ✓ File EXISTS with SHA: $fileSha');
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 404) {
          debugPrint('  ℹ File does NOT exist, will be created');
        } else {
          debugPrint('  ⚠ Error checking file: $e');
          if (e is DioException) {
            debugPrint('  Response status: ${e.response?.statusCode}');
            debugPrint('  Response data: ${e.response?.data}');
          }
          rethrow;
        }
      }

      // Prepare data for API call
      debugPrint('  → Preparing data for GitHub API...');
      final data = {
        'message': message,
        'content': base64Encode(utf8.encode(content)),
        'branch': _branchName,
        if (fileSha != null) 'sha': fileSha, // Only include SHA if file exists
      };

      debugPrint('  Data prepared:');
      debugPrint('    - message: $message');
      debugPrint('    - branch: $_branchName');
      if (fileSha != null) {
        debugPrint('    - sha: $fileSha');
      }
      debugPrint('    - content: ${base64Encode(utf8.encode(content)).length} bytes (base64)');

      // Create or update file
      debugPrint('  → Sending PUT request to GitHub...');
      try {
        final response = await _dio.put(
          '/repos/$_repositoryOwner/$_repositoryName/contents/$path',
          data: data,
        );

        debugPrint('  ← Response status: ${response.statusCode}');
        debugPrint('  ← Response data: ${response.data}');

        if (response.statusCode != 200 && response.statusCode != 201) {
          debugPrint('  ✗ UNEXPECTED STATUS CODE!');
          throw Exception('Failed to update file in GitHub');
        }
        debugPrint('  ✓ File updated successfully');
        debugPrint('└─────────────────────────────────────────');
        debugPrint('');
      } catch (e) {
        debugPrint('  ✗ ERROR during PUT request!');
        debugPrint('  Error type: ${e.runtimeType}');
        debugPrint('  Error: $e');

        if (e is DioException) {
          debugPrint('  HTTP Status: ${e.response?.statusCode}');
          debugPrint('  Response headers: ${e.response?.headers}');
          debugPrint('  Response data: ${e.response?.data}');
          debugPrint('  Request data: ${e.requestOptions.data}');

          // Handle 409 conflict - retry with fresh SHA
          if (e.response?.statusCode == 409) {
            debugPrint('  ⚠ CONFLICT (409) detected!');
            debugPrint('  ℹ This usually means the file was modified between our check and update');
            debugPrint('  → Attempting retry with fresh SHA...');
            
            try {
              // Get fresh SHA
              debugPrint('  → Fetching latest file SHA...');
              final freshFileResponse = await _dio.get(
                '/repos/$_repositoryOwner/$_repositoryName/contents/$path',
                queryParameters: {'ref': _branchName},
              );
              final freshSha = freshFileResponse.data['sha'];
              debugPrint('  ✓ Got new SHA: $freshSha');
              debugPrint('  ℹ Old SHA was: $fileSha');
              
              // Retry with fresh SHA
              debugPrint('  → Retrying PUT request with new SHA...');
              final retryData = {
                'message': message,
                'content': base64Encode(utf8.encode(content)),
                'branch': _branchName,
                'sha': freshSha,
              };
              
              final retryResponse = await _dio.put(
                '/repos/$_repositoryOwner/$_repositoryName/contents/$path',
                data: retryData,
              );
              
              debugPrint('  ← Retry response status: ${retryResponse.statusCode}');
              debugPrint('  ← Retry response data: ${retryResponse.data}');
              
              if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
                debugPrint('  ✓ File updated successfully after retry!');
                debugPrint('└─────────────────────────────────────────');
                debugPrint('');
                return;
              } else {
                debugPrint('  ✗ Retry attempt failed!');
                debugPrint('  Retry error type: ${e.runtimeType}');
                debugPrint('  Retry error: $e');
                debugPrint('  Retry HTTP Status: ${e.response?.statusCode}');
                debugPrint('  Retry Response data: ${e.response?.data}');
                debugPrint('└─────────────────────────────────────────');
                debugPrint('');
                rethrow;
              }
            } catch (retryError) {
              debugPrint('  ✗ Retry attempt failed!');
              debugPrint('  Retry error type: ${retryError.runtimeType}');
              debugPrint('  Retry error: $retryError');
              if (retryError is DioException) {
                debugPrint('  Retry HTTP Status: ${retryError.response?.statusCode}');
                debugPrint('  Retry Response data: ${retryError.response?.data}');
              }
              debugPrint('└─────────────────────────────────────────');
              debugPrint('');
              rethrow;
            }
          }
        }

        debugPrint('└─────────────────────────────────────────');
        debugPrint('');
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('  ✗ FATAL ERROR in _updateFileInGitHub!');
      debugPrint('  Error: $e');
      debugPrint('  Stack trace: $stackTrace');
      debugPrint('└─────────────────────────────────────────');
      debugPrint('');
      rethrow;
    }
  }

  /// Download data from GitHub
  Future<void> downloadFromGitHub() async {
    if (!isConfigured) return;

    try {
      // Download tasks
      await _downloadTasksFromGitHub();

      // Download workspaces
      await _downloadWorkspacesFromGitHub();

      // Download tags
      await _downloadTagsFromGitHub();

      debugPrint('GitHubSyncService: Data downloaded from GitHub');
    } catch (e) {
      debugPrint('GitHubSyncService: Error downloading from GitHub: $e');
      rethrow;
    }
  }

  /// Download tasks from GitHub
  Future<void> _downloadTasksFromGitHub() async {
    try {
      final response = await _dio.get(
        '/repos/$_repositoryOwner/$_repositoryName/contents/data/tasks.json',
      );
      final content = utf8.decode(base64Decode(response.data['content']));
      final data = jsonDecode(content);

      final tasks = (data['tasks'] as List)
          .map((json) => _taskFromJson(json))
          .toList();

      // Update local tasks
      for (final task in tasks) {
        final existingTask = await _taskRepository!.getTaskById(task.id);
        if (existingTask != null) {
          await _taskRepository!.updateTask(task);
        } else {
          await _taskRepository!.createTask(task);
        }
      }
    } catch (e) {
      debugPrint('GitHubSyncService: Error downloading tasks: $e');
    }
  }

  /// Download workspaces from GitHub
  Future<void> _downloadWorkspacesFromGitHub() async {
    try {
      final response = await _dio.get(
        '/repos/$_repositoryOwner/$_repositoryName/contents/data/workspaces.json',
      );
      final content = utf8.decode(base64Decode(response.data['content']));
      final data = jsonDecode(content);

      final workspaces = (data['workspaces'] as List)
          .map((json) => _workspaceFromJson(json))
          .toList();

      // Update local workspaces
      for (final workspace in workspaces) {
        final existingWorkspace = await _workspaceRepository!.getWorkspaceById(
          workspace.id,
        );
        if (existingWorkspace != null) {
          await _workspaceRepository!.updateWorkspace(workspace);
        } else {
          await _workspaceRepository!.createWorkspace(workspace);
        }
      }
    } catch (e) {
      debugPrint('GitHubSyncService: Error downloading workspaces: $e');
    }
  }

  /// Download tags from GitHub
  Future<void> _downloadTagsFromGitHub() async {
    try {
      final response = await _dio.get(
        '/repos/$_repositoryOwner/$_repositoryName/contents/data/tags.json',
      );
      final content = utf8.decode(base64Decode(response.data['content']));
      final data = jsonDecode(content);

      final tags = (data['tags'] as List)
          .map((json) => _tagFromJson(json))
          .toList();

      // Update local tags
      for (final tag in tags) {
        final existingTag = await _tagRepository!.getTagById(tag.id);
        if (existingTag != null) {
          await _tagRepository!.updateTag(tag);
        } else {
          await _tagRepository!.createTag(tag);
        }
      }
    } catch (e) {
      debugPrint('GitHubSyncService: Error downloading tags: $e');
    }
  }

  /// Convert Task to JSON
  Map<String, dynamic> _taskToJson(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'category': task.category,
      'priority': task.priority.name,
      'dueDate': task.dueDate.toIso8601String(),
      'isCompleted': task.isCompleted,
      'progress': task.progress,
      'workspaceId': task.workspaceId,
      'createdAt': task.createdAt.toIso8601String(),
      'estimatedHours': task.estimatedHours,
      'tagIds': task.tagIds,
    };
  }

  /// Convert JSON to Task
  Task _taskFromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: DateTime.parse(json['dueDate']),
      isCompleted: json['isCompleted'] ?? false,
      progress: json['progress'],
      workspaceId: json['workspaceId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['createdAt']),
      estimatedHours: json['estimatedHours'],
      tagIds: json['tagIds'] != null ? List<int>.from(json['tagIds']) : null,
    );
  }

  /// Convert Workspace to JSON
  Map<String, dynamic> _workspaceToJson(Workspace workspace) {
    return {
      'id': workspace.id,
      'name': workspace.name,
      'description': workspace.description,
      'iconName': workspace.iconName,
      'colorHex': workspace.colorHex,
      'createdAt': workspace.createdAt.toIso8601String(),
      'updatedAt': workspace.updatedAt.toIso8601String(),
      'order': workspace.order,
      'totalTasks': workspace.totalTasks,
      'completedTasks': workspace.completedTasks,
    };
  }

  /// Convert JSON to Workspace
  Workspace _workspaceFromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconName: json['iconName'],
      colorHex: json['colorHex'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['createdAt']),
      order: json['order'] ?? 0,
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
    );
  }

  /// Convert Tag to JSON
  Map<String, dynamic> _tagToJson(Tag tag) {
    return {
      'id': tag.id,
      'name': tag.name,
      'colorHex': tag.colorHex,
      'createdAt': tag.createdAt.toIso8601String(),
      'usageCount': tag.usageCount,
    };
  }

  /// Convert JSON to Tag
  Tag _tagFromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      colorHex: json['colorHex'],
      createdAt: DateTime.parse(json['createdAt']),
      usageCount: json['usageCount'] ?? 0,
    );
  }

  /// Get sync statistics
  Future<GitHubSyncStatistics> getSyncStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final totalSyncs = prefs.getInt('github_total_syncs') ?? 0;
    final failedSyncs = prefs.getInt('github_failed_syncs') ?? 0;

    return GitHubSyncStatistics(
      lastSyncTime: _lastSyncTime,
      totalSyncs: totalSyncs,
      failedSyncs: failedSyncs,
      queuedOperations: _syncQueue.length,
      autoSyncEnabled: _autoSyncEnabled,
      repositoryOwner: _repositoryOwner,
      repositoryName: _repositoryName,
      branchName: _branchName,
    );
  }

  /// Clear GitHub configuration
  Future<void> clearGitHubConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('github_token');
    await prefs.remove('github_repo_owner');
    await prefs.remove('github_repo_name');
    await prefs.remove('github_branch');
    await prefs.remove('last_sync_time');

    _githubToken = null;
    _repositoryOwner = null;
    _repositoryName = null;
    _branchName = null;
    _lastSyncTime = null;
    _syncQueue.clear();

    _stopAutoSync();
    debugPrint('GitHubSyncService: Configuration cleared');
  }

  /// Check if online mode is enabled
  bool _isOnlineModeEnabled() {
    // Check SharedPreferences for sync/offline mode setting
    // The setting is stored as 'sync_enabled' in SharedPreferences
    // We need to check this synchronously, so we'll use a cached value
    debugPrint(
      'GitHubSyncService: Checking online mode - _syncEnabled: $_syncEnabled',
    );
    return _syncEnabled;
  }

  // Cache the sync enabled state (default to offline mode)
  bool _syncEnabled = false;

  /// Update sync settings
  Future<void> updateSyncSettings(bool enabled) async {
    try {
      debugPrint('GitHubSyncService: Updating sync settings to: $enabled');
      _syncEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setBool('sync_enabled', enabled);
      
      if (!result) {
        debugPrint('GitHubSyncService: Failed to save sync settings');
        throw Exception('Failed to save sync settings to SharedPreferences');
      }
      
      debugPrint('GitHubSyncService: Sync settings updated successfully: $enabled');

      // Restart or stop auto-sync based on new setting
      if (enabled && isConfigured) {
        _startAutoSync();
        // Моментальная синхронизация при включении
        debugPrint('GitHubSyncService: Triggering immediate sync on enable...');
        syncAll();
      } else {
        _stopAutoSync();
      }
    } catch (e) {
      debugPrint('GitHubSyncService: Failed to update sync settings: $e');
      rethrow;
    }
  }

  /// Force reset sync settings to offline mode
  Future<void> resetToOfflineMode() async {
    try {
      debugPrint('GitHubSyncService: Resetting to offline mode...');
      _syncEnabled = false;
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setBool('sync_enabled', false);
      
      if (!result) {
        debugPrint('GitHubSyncService: Failed to save offline mode setting');
        throw Exception('Failed to save offline mode to SharedPreferences');
      }
      
      _stopAutoSync();
      debugPrint('GitHubSyncService: Successfully reset to offline mode');
    } catch (e) {
      debugPrint('GitHubSyncService: Failed to reset to offline mode: $e');
      rethrow;
    }
  }

  /// Setup data change listeners for automatic sync
  void _setupDataChangeListeners() {
    debugPrint('GitHubSyncService: Setting up data change listeners...');

    // Listen to task changes
    _taskChangesSubscription = _taskRepository?.watchAllTasks().listen((_) {
      debugPrint('GitHubSyncService: Task data changed, triggering sync...');
      _triggerSync();
    });

    // Listen to workspace changes
    _workspaceChangesSubscription = _workspaceRepository
        ?.watchAllWorkspaces()
        .listen((_) {
          debugPrint(
            'GitHubSyncService: Workspace data changed, triggering sync...',
          );
          _triggerSync();
        });

    // Listen to tag changes
    _tagChangesSubscription = _tagRepository?.watchAllTags().listen((_) {
      debugPrint('GitHubSyncService: Tag data changed, triggering sync...');
      _triggerSync();
    });

    debugPrint('GitHubSyncService: Data change listeners setup complete');
  }

  /// Trigger sync when data changes (with debouncing and rate limit protection)
  void _triggerSync() {
    debugPrint('GitHubSyncService: _triggerSync called');

    // Sync on all platforms

    if (!isConfigured) {
      debugPrint('GitHubSyncService: Cannot sync - not configured');
      return;
    }

    if (!_isOnlineModeEnabled()) {
      debugPrint('GitHubSyncService: Cannot sync - offline mode enabled');
      return;
    }

    if (_isSyncing) {
      debugPrint('GitHubSyncService: Sync already in progress, skipping...');
      return;
    }

    // Check if we hit rate limit recently (wait 1 hour)
    if (_lastRateLimitHit != null) {
      final timeSinceRateLimit = DateTime.now().difference(_lastRateLimitHit!);
      if (timeSinceRateLimit.inMinutes < 60) {
        debugPrint('GitHubSyncService: Rate limit hit recently, skipping sync for ${60 - timeSinceRateLimit.inMinutes} more minutes');
        return;
      }
    }

    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    // Set new debounce timer (30 seconds delay to reduce API calls)
    _debounceTimer = Timer(const Duration(seconds: 30), () {
      debugPrint('GitHubSyncService: Triggering sync due to data change...');
      syncAll();
    });
    
    debugPrint('GitHubSyncService: Debounced sync scheduled in 30 seconds');
  }

  /// Mark that user has cleared all data
  void _markDataClearedByUser() {
    _dataClearedByUser = true;
    debugPrint('GitHubSyncService: Data marked as cleared by user');
  }

  /// Check if data was cleared by user
  bool _wasDataClearedByUser() {
    return _dataClearedByUser;
  }

  /// Reset the cleared flag (when user adds new data)
  void _resetDataClearedFlag() {
    _dataClearedByUser = false;
    debugPrint('GitHubSyncService: Data cleared flag reset');
  }

  /// Delete file from GitHub repository
  Future<void> _deleteFileFromGitHub({
    required String path,
    required String message,
    required String? currentCommit,
  }) async {
    debugPrint('');
    debugPrint('┌─────────────────────────────────────────');
    debugPrint('│ DELETE FILE: $path');
    debugPrint('└─────────────────────────────────────────');
    debugPrint('  Repository: $_repositoryOwner/$_repositoryName');
    debugPrint('  Branch: $_branchName');
    debugPrint('  Commit SHA: ${currentCommit ?? "null (empty repo)"}');
    debugPrint('  Message: $message');

    try {
      // Get file SHA if it exists
      String? fileSha;
      if (currentCommit != null) {
        debugPrint('  → Checking if file exists...');
        try {
          final fileResponse = await _dio.get(
            '/repos/$_repositoryOwner/$_repositoryName/contents/$path',
            queryParameters: {'ref': _branchName},
          );
          fileSha = fileResponse.data['sha'];
          debugPrint('  ✓ File EXISTS with SHA: $fileSha');
        } catch (e) {
          if (e is DioException && e.response?.statusCode == 404) {
            debugPrint('  ℹ File does NOT exist, nothing to delete');
            debugPrint('└─────────────────────────────────────────');
            debugPrint('');
            return;
          } else {
            debugPrint('  ⚠ Error checking file: $e');
            if (e is DioException) {
              debugPrint('  Response status: ${e.response?.statusCode}');
              debugPrint('  Response data: ${e.response?.data}');
            }
            rethrow;
          }
        }
      } else {
        debugPrint('  ℹ Repository is empty - nothing to delete');
        debugPrint('└─────────────────────────────────────────');
        debugPrint('');
        return;
      }

      if (fileSha == null) {
        debugPrint('  ℹ File does not exist, nothing to delete');
        debugPrint('└─────────────────────────────────────────');
        debugPrint('');
        return;
      }

      // Prepare data for deletion
      debugPrint('  → Preparing data for GitHub API...');
      final data = {'message': message, 'sha': fileSha, 'branch': _branchName};

      debugPrint('  Data prepared:');
      debugPrint('    - message: $message');
      debugPrint('    - branch: $_branchName');
      debugPrint('    - sha: $fileSha');

      // Delete file
      debugPrint('  → Sending DELETE request to GitHub...');
      try {
        final response = await _dio.delete(
          '/repos/$_repositoryOwner/$_repositoryName/contents/$path',
          data: data,
        );

        debugPrint('  ← Response status: ${response.statusCode}');
        debugPrint('  ← Response data: ${response.data}');

        if (response.statusCode != 200) {
          debugPrint('  ✗ UNEXPECTED STATUS CODE!');
          throw Exception('Failed to delete file from GitHub');
        }
        debugPrint('  ✓ File deleted successfully');
        debugPrint('└─────────────────────────────────────────');
        debugPrint('');
      } catch (e) {
        debugPrint('  ✗ ERROR during DELETE request!');
        debugPrint('  Error type: ${e.runtimeType}');
        debugPrint('  Error: $e');

        if (e is DioException) {
          debugPrint('  HTTP Status: ${e.response?.statusCode}');
          debugPrint('  Response headers: ${e.response?.headers}');
          debugPrint('  Response data: ${e.response?.data}');
          debugPrint('  Request data: ${e.requestOptions.data}');
        }

        debugPrint('└─────────────────────────────────────────');
        debugPrint('');
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('  ✗ FATAL ERROR in _deleteFileFromGitHub!');
      debugPrint('  Error: $e');
      debugPrint('  Stack trace: $stackTrace');
      debugPrint('└─────────────────────────────────────────');
      debugPrint('');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _stopAutoSync();
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    _taskChangesSubscription?.cancel();
    _workspaceChangesSubscription?.cancel();
    _tagChangesSubscription?.cancel();
    _syncStatusController.close();
    debugPrint('GitHubSyncService: Disposed');
  }
}

/// GitHub sync operation model
class GitHubSyncOperation {
  final GitHubSyncOperationType type;
  final dynamic data;
  final DateTime timestamp;

  GitHubSyncOperation({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// GitHub sync operation types
enum GitHubSyncOperationType {
  createTask,
  updateTask,
  deleteTask,
  createWorkspace,
  updateWorkspace,
  deleteWorkspace,
  createTag,
  updateTag,
  deleteTag,
}

/// GitHub sync state
enum GitHubSyncState { idle, syncing, completed, failed }

/// GitHub sync status model
class GitHubSyncStatus {
  final GitHubSyncState state;
  final String message;
  final DateTime? lastSyncTime;

  GitHubSyncStatus({
    required this.state,
    required this.message,
    this.lastSyncTime,
  });
}

/// GitHub sync result model
class GitHubSyncResult {
  final bool success;
  final String message;
  final int? syncedItems;

  GitHubSyncResult({
    required this.success,
    required this.message,
    this.syncedItems,
  });
}

/// GitHub sync statistics model
class GitHubSyncStatistics {
  final DateTime? lastSyncTime;
  final int totalSyncs;
  final int failedSyncs;
  final int queuedOperations;
  final bool autoSyncEnabled;
  final String? repositoryOwner;
  final String? repositoryName;
  final String? branchName;

  GitHubSyncStatistics({
    required this.lastSyncTime,
    required this.totalSyncs,
    required this.failedSyncs,
    required this.queuedOperations,
    required this.autoSyncEnabled,
    this.repositoryOwner,
    this.repositoryName,
    this.branchName,
  });

  double get successRate {
    if (totalSyncs == 0) return 0.0;
    return (totalSyncs - failedSyncs) / totalSyncs * 100;
  }
}
