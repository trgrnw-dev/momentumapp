import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../domain/repositories/tag_repository.dart';

/// Service for offline-first data synchronization
/// Manages sync between local database and remote server
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final Connectivity _connectivity = Connectivity();

  TaskRepository? _taskRepository;
  WorkspaceRepository? _workspaceRepository;
  TagRepository? _tagRepository;

  bool _isSyncing = false;
  bool _autoSyncEnabled = true;
  DateTime? _lastSyncTime;
  Timer? _autoSyncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final List<SyncOperation> _syncQueue = [];
  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Check if auto-sync is enabled
  bool get autoSyncEnabled => _autoSyncEnabled;

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Initialize the sync service
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

    // Load last sync time
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString('last_sync_time');
    if (lastSyncString != null) {
      _lastSyncTime = DateTime.parse(lastSyncString);
    }

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _onConnectivityChanged(results);
    });

    // Start auto-sync timer if enabled
    if (_autoSyncEnabled) {
      _startAutoSync();
    }

    debugPrint('SyncService: Initialized');
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (hasConnection && _autoSyncEnabled && !_isSyncing) {
      debugPrint('SyncService: Network restored, starting sync');
      syncAll();
    }
  }

  /// Start automatic sync timer
  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(minutes: 15), // Sync every 15 minutes
      (_) {
        if (_autoSyncEnabled && !_isSyncing) {
          syncAll();
        }
      },
    );
    debugPrint('SyncService: Auto-sync started (15 min interval)');
  }

  /// Stop automatic sync timer
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    debugPrint('SyncService: Auto-sync stopped');
  }

  /// Enable or disable auto-sync
  Future<void> setAutoSync(bool enabled) async {
    _autoSyncEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_enabled', enabled);

    if (enabled) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }

    debugPrint('SyncService: Auto-sync ${enabled ? "enabled" : "disabled"}');
  }

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      return connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );
    } catch (e) {
      debugPrint('SyncService: Error checking connectivity: $e');
      return false;
    }
  }

  /// Sync all data (tasks, workspaces, tags)
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      debugPrint('SyncService: Sync already in progress');
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    if (!await hasInternetConnection()) {
      debugPrint('SyncService: No internet connection');
      _syncStatusController.add(
        SyncStatus(state: SyncState.failed, message: 'No internet connection'),
      );
      return SyncResult(success: false, message: 'No internet connection');
    }

    // Authentication check removed - using only local sync

    _isSyncing = true;
    _syncStatusController.add(
      SyncStatus(state: SyncState.syncing, message: 'Syncing data...'),
    );

    try {
      // Sync tasks
      await _syncTasks();

      // Sync workspaces
      await _syncWorkspaces();

      // Sync tags
      await _syncTags();

      // Update last sync time
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', _lastSyncTime!.toIso8601String());

      _isSyncing = false;
      _syncStatusController.add(
        SyncStatus(
          state: SyncState.completed,
          message: 'Sync completed successfully',
          lastSyncTime: _lastSyncTime,
        ),
      );

      debugPrint('SyncService: Sync completed successfully');
      return SyncResult(success: true, message: 'Sync completed');
    } catch (e) {
      _isSyncing = false;
      debugPrint('SyncService: Sync failed: $e');
      _syncStatusController.add(
        SyncStatus(state: SyncState.failed, message: 'Sync failed: $e'),
      );
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
  }

  /// Sync tasks (local only for now)
  Future<void> _syncTasks() async {
    if (_taskRepository == null) return;

    try {
      // Local sync only - no server communication
      debugPrint('SyncService: Tasks synced locally');
    } catch (e) {
      debugPrint('SyncService: Error syncing tasks: $e');
      rethrow;
    }
  }

  /// Sync workspaces (local only for now)
  Future<void> _syncWorkspaces() async {
    if (_workspaceRepository == null) return;

    try {
      // Local sync only - no server communication
      debugPrint('SyncService: Workspaces synced locally');
    } catch (e) {
      debugPrint('SyncService: Error syncing workspaces: $e');
      rethrow;
    }
  }

  /// Sync tags (local only for now)
  Future<void> _syncTags() async {
    if (_tagRepository == null) return;

    try {
      // Local sync only - no server communication
      debugPrint('SyncService: Tags synced locally');
    } catch (e) {
      debugPrint('SyncService: Error syncing tags: $e');
      rethrow;
    }
  }

  /// Queue a sync operation for later
  void queueOperation(SyncOperation operation) {
    _syncQueue.add(operation);
    debugPrint('SyncService: Operation queued: ${operation.type}');
  }

  /// Process queued operations
  Future<void> processQueue() async {
    if (_syncQueue.isEmpty) return;

    debugPrint(
      'SyncService: Processing ${_syncQueue.length} queued operations',
    );

    while (_syncQueue.isNotEmpty) {
      final operation = _syncQueue.removeAt(0);
      try {
        await _executeOperation(operation);
      } catch (e) {
        debugPrint('SyncService: Error executing operation: $e');
        // Re-queue operation for retry
        _syncQueue.add(operation);
      }
    }
  }

  /// Execute a single sync operation (local only)
  Future<void> _executeOperation(SyncOperation operation) async {
    // Local operations only - no server communication
    debugPrint('SyncService: Executing local operation: ${operation.type}');
  }

  /// Force sync now (manual sync)
  Future<SyncResult> forceSyncNow() async {
    debugPrint('SyncService: Manual sync triggered');
    return await syncAll();
  }

  /// Upload only (local only for now)
  Future<void> uploadChanges() async {
    if (_taskRepository == null) return;

    try {
      // Local operations only - no server communication
      debugPrint('SyncService: Changes processed locally');
    } catch (e) {
      debugPrint('SyncService: Error processing changes: $e');
      rethrow;
    }
  }

  /// Download only (local only for now)
  Future<void> downloadChanges() async {
    if (_taskRepository == null) return;

    try {
      // Local operations only - no server communication
      debugPrint('SyncService: Changes processed locally');
    } catch (e) {
      debugPrint('SyncService: Error processing changes: $e');
      rethrow;
    }
  }


  /// Clear sync data
  Future<void> clearSyncData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_sync_time');
    _lastSyncTime = null;
    _syncQueue.clear();
    debugPrint('SyncService: Sync data cleared');
  }

  /// Get sync statistics
  Future<SyncStatistics> getSyncStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final totalSyncs = prefs.getInt('total_syncs') ?? 0;
    final failedSyncs = prefs.getInt('failed_syncs') ?? 0;

    return SyncStatistics(
      lastSyncTime: _lastSyncTime,
      totalSyncs: totalSyncs,
      failedSyncs: failedSyncs,
      queuedOperations: _syncQueue.length,
      autoSyncEnabled: _autoSyncEnabled,
    );
  }

  /// Dispose resources
  void dispose() {
    _stopAutoSync();
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
    debugPrint('SyncService: Disposed');
  }
}

/// Sync operation model
class SyncOperation {
  final SyncOperationType type;
  final dynamic data;
  final DateTime timestamp;

  SyncOperation({required this.type, required this.data, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

/// Sync operation types
enum SyncOperationType {
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

/// Sync state
enum SyncState { idle, syncing, completed, failed }

/// Sync status model
class SyncStatus {
  final SyncState state;
  final String message;
  final DateTime? lastSyncTime;

  SyncStatus({required this.state, required this.message, this.lastSyncTime});
}

/// Sync result model
class SyncResult {
  final bool success;
  final String message;
  final int? syncedItems;

  SyncResult({required this.success, required this.message, this.syncedItems});
}

/// Sync statistics model
class SyncStatistics {
  final DateTime? lastSyncTime;
  final int totalSyncs;
  final int failedSyncs;
  final int queuedOperations;
  final bool autoSyncEnabled;

  SyncStatistics({
    required this.lastSyncTime,
    required this.totalSyncs,
    required this.failedSyncs,
    required this.queuedOperations,
    required this.autoSyncEnabled,
  });

  double get successRate {
    if (totalSyncs == 0) return 0.0;
    return (totalSyncs - failedSyncs) / totalSyncs * 100;
  }
}
