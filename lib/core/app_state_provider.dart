import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStateProvider with ChangeNotifier {
  static const String _currentWorkspaceKey = 'current_workspace_id';
  static const String _lastFilterKey = 'last_task_filter';
  static const String _showSearchKey = 'show_search';
  static const String _workspaceViewModeKey = 'workspace_view_mode';
  static const String _syncEnabledKey = 'sync_enabled';
  
  int? _currentWorkspaceId;
  String _lastFilter = 'today';
  bool _showSearch = true;
  String _workspaceViewMode = 'grid'; // 'grid' or 'list'
  bool _syncEnabled = false;
  bool _isInitialized = false;
  bool _tagsNeedRefresh = false;

  int? get currentWorkspaceId => _currentWorkspaceId;
  String get lastFilter => _lastFilter;
  bool get showSearch => _showSearch;
  String get workspaceViewMode => _workspaceViewMode;
  bool get syncEnabled => _syncEnabled;
  bool get isInitialized => _isInitialized;
  bool get tagsNeedRefresh => _tagsNeedRefresh;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentWorkspaceId = prefs.getInt(_currentWorkspaceKey);
      _lastFilter = prefs.getString(_lastFilterKey) ?? 'today';
      _showSearch = prefs.getBool(_showSearchKey) ?? true;
      _workspaceViewMode = prefs.getString(_workspaceViewModeKey) ?? 'grid';
      _syncEnabled = prefs.getBool(_syncEnabledKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading app state: $e');
      _isInitialized = true;
    }
  }

  Future<void> setCurrentWorkspace(int? workspaceId) async {
    if (_currentWorkspaceId == workspaceId) return;
    
    _currentWorkspaceId = workspaceId;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      if (workspaceId != null) {
        await prefs.setInt(_currentWorkspaceKey, workspaceId);
      } else {
        await prefs.remove(_currentWorkspaceKey);
      }
    } catch (e) {
      debugPrint('Error saving current workspace: $e');
    }
  }

  Future<void> setLastFilter(String filter) async {
    if (_lastFilter == filter) return;
    
    _lastFilter = filter;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastFilterKey, filter);
    } catch (e) {
      debugPrint('Error saving last filter: $e');
    }
  }

  Future<void> setShowSearch(bool show) async {
    if (_showSearch == show) return;
    
    _showSearch = show;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showSearchKey, show);
    } catch (e) {
      debugPrint('Error saving show search setting: $e');
    }
  }

  Future<void> setWorkspaceViewMode(String mode) async {
    if (_workspaceViewMode == mode) return;
    
    _workspaceViewMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_workspaceViewModeKey, mode);
    } catch (e) {
      debugPrint('Error saving workspace view mode: $e');
    }
  }

  Future<void> setSyncEnabled(bool enabled) async {
    if (_syncEnabled == enabled) return;
    
    _syncEnabled = enabled;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_syncEnabledKey, enabled);
    } catch (e) {
      debugPrint('Error saving sync enabled setting: $e');
    }
  }

  void markTagsNeedRefresh() {
    _tagsNeedRefresh = true;
    notifyListeners();
  }

  void clearTagsRefreshFlag() {
    _tagsNeedRefresh = false;
    notifyListeners();
  }

  Future<void> clearState() async {
    _currentWorkspaceId = null;
    _lastFilter = 'today';
    _showSearch = true;
    _workspaceViewMode = 'grid';
    _syncEnabled = false;
    _tagsNeedRefresh = false;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentWorkspaceKey);
      await prefs.remove(_lastFilterKey);
      await prefs.remove(_showSearchKey);
      await prefs.remove(_workspaceViewModeKey);
      await prefs.remove(_syncEnabledKey);
    } catch (e) {
      debugPrint('Error clearing app state: $e');
    }
  }
}
