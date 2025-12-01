import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme_provider.dart';
import '../../core/app_state_provider.dart';
import '../../data/services/github_sync_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  final GitHubSyncService _githubSyncService = GitHubSyncService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Settings are now managed by AppStateProvider
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(theme, isDark),
            const SizedBox(height: 20),
            // Settings Content
            Expanded(
              child: _buildSettingsContent(theme, isDark),
            ),
            // App Version
            _buildAppVersion(theme, isDark),
            const SizedBox(height: 20),
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
          // Back Button
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.arrow_back,
                color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Text(
              'settings.title'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(width: 48), // Spacer for centering
        ],
      ),
    );
  }

  Widget _buildSettingsContent(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dark Mode Setting
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: _buildSettingItem(
                    icon: Icons.dark_mode,
                    title: 'settings.dark_mode'.tr(),
                    isDark: isDark,
                    child: Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return _buildToggleSwitch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) => themeProvider.toggleTheme(),
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Notifications Setting
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: _buildSettingItem(
                    icon: Icons.notifications,
                    title: 'settings.notifications'.tr(),
                    isDark: isDark,
                    child: _buildToggleSwitch(
                      value: _notificationsEnabled,
                      onChanged: (value) => setState(() => _notificationsEnabled = value),
                      isDark: isDark,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Sync/Offline Mode Setting
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: _buildSettingItem(
                    icon: Icons.sync,
                    title: 'settings.sync_offline'.tr(),
                    isDark: isDark,
                    child: Consumer<AppStateProvider>(
                      builder: (context, appState, child) {
                        return _buildToggleSwitch(
                          value: appState.syncEnabled,
                          onChanged: (value) async {
                            await _githubSyncService.updateSyncSettings(value);
                            await appState.setSyncEnabled(value);
                          },
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
                 ),
                 const SizedBox(height: 8),
                 // Tags Setting
                 TweenAnimationBuilder<double>(
                   duration: const Duration(milliseconds: 700),
                   tween: Tween(begin: 0.0, end: 1.0),
                   builder: (context, value, child) {
                     return Transform.translate(
                       offset: Offset(0, 20 * (1 - value)),
                       child: Opacity(
                         opacity: value.clamp(0.0, 1.0),
                         child: _buildSettingItem(
                           icon: Icons.label,
                           title: 'settings.tags'.tr(),
                           isDark: isDark,
                           child: GestureDetector(
                             onTap: () {
                               context.push('/tags');
                             },
                             child: Row(
                               children: [
                                 Text(
                                   'settings.manage_tags'.tr(),
                                   style: const TextStyle(
                                     fontSize: 16,
                                     fontWeight: FontWeight.w500,
                                     color: Color(0xFF137FEC),
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 Icon(
                                   Icons.arrow_forward_ios,
                                   color: const Color(0xFF137FEC).withValues(alpha: 0.7),
                                   size: 16,
                                 ),
                               ],
                             ),
                           ),
                         ),
                       ),
                     );
                   },
                 ),
                 const SizedBox(height: 8),
                 // Display Settings Section
                 _buildDisplaySettingsSection(theme, isDark),
                 const SizedBox(height: 8),
                 // Language Setting
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: _buildSettingItem(
                    icon: Icons.language,
                    title: 'settings.language'.tr(),
                    isDark: isDark,
                    child: GestureDetector(
                      onTap: () => _showLanguageDialog(context),
                      child: Row(
                        children: [
                          Text(
                            context.locale.languageCode == 'ru' ? 'settings.russian'.tr() : 'settings.english'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF137FEC),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: const Color(0xFF137FEC).withValues(alpha: 0.7),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // GitHub Sync Setting
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: _buildSettingItem(
                    icon: Icons.code,
                    title: 'github_sync.title'.tr(),
                    isDark: isDark,
                    child: GestureDetector(
                      onTap: () {
                        context.push('/github-sync');
                      },
                      child: Row(
                        children: [
                          Text(
                            'github_sync.configure'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF137FEC),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: const Color(0xFF137FEC).withValues(alpha: 0.7),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF137FEC).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF137FEC),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333),
              ),
            ),
          ),
          // Child widget (toggle, button, etc.)
          child,
        ],
      ),
    );
  }

  Widget _buildToggleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          color: value ? const Color(0xFF137FEC) : const Color(0xFF137FEC).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15.5),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 27,
            height: 27,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppVersion(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'settings.version'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFE5E5EA).withValues(alpha: 0.6) : const Color(0xFF333333).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'settings.contact_support'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFE5E5EA).withValues(alpha: 0.6) : const Color(0xFF333333).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('settings.english'.tr()),
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('settings.russian'.tr()),
              onTap: () {
                context.setLocale(const Locale('ru'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build display settings section
  Widget _buildDisplaySettingsSection(ThemeData theme, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'settings.display_settings'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        
        // Show Search Setting
        Consumer<AppStateProvider>(
          builder: (context, appState, child) {
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: _buildSettingItem(
                      icon: Icons.search,
                      title: 'settings.show_search'.tr(),
                      isDark: isDark,
                      child: _buildToggleSwitch(
                        value: appState.showSearch,
                        onChanged: (value) {
                          appState.setShowSearch(value);
                        },
                        isDark: isDark,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 8),
        
        // Workspace View Mode Setting
        Consumer<AppStateProvider>(
          builder: (context, appState, child) {
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: _buildSettingItem(
                      icon: Icons.view_module,
                      title: 'settings.workspace_display_mode'.tr(),
                      isDark: isDark,
                      child: GestureDetector(
                        onTap: () => _showViewModeDialog(context, appState),
                        child: Row(
                          children: [
                            Text(
                              appState.workspaceViewMode == 'grid' ? 'settings.grid'.tr() : 'settings.list'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF137FEC),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: const Color(0xFF137FEC).withValues(alpha: 0.7),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// Show view mode selection dialog
  void _showViewModeDialog(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings.display_mode'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: Text('settings.grid'.tr()),
              trailing: appState.workspaceViewMode == 'grid' 
                ? const Icon(Icons.check, color: Color(0xFF137FEC))
                : null,
              onTap: () {
                appState.setWorkspaceViewMode('grid');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: Text('settings.list'.tr()),
              trailing: appState.workspaceViewMode == 'list' 
                ? const Icon(Icons.check, color: Color(0xFF137FEC))
                : null,
              onTap: () {
                appState.setWorkspaceViewMode('list');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}