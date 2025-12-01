import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../data/services/github_sync_service.dart';
import '../utils/responsive_helper.dart';
import '../utils/accessibility_helper.dart';

/// GitHub Sync Configuration Page
/// Allows users to configure GitHub synchronization
class GitHubSyncPage extends StatefulWidget {
  final GitHubSyncService? githubSyncService;
  
  const GitHubSyncPage({super.key, this.githubSyncService});

  @override
  State<GitHubSyncPage> createState() => _GitHubSyncPageState();
}

class _GitHubSyncPageState extends State<GitHubSyncPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _branchController = TextEditingController(text: 'main');

  late final GitHubSyncService _githubSyncService;
  
  bool _isLoading = false;
  bool _isConfigured = false;

  @override
  void initState() {
    super.initState();
    _githubSyncService = widget.githubSyncService ?? Provider.of<GitHubSyncService>(context, listen: false);
    _loadConfiguration();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _ownerController.dispose();
    _repoController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  /// Load current configuration
  Future<void> _loadConfiguration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _isConfigured = _githubSyncService.isConfigured;
      
      if (_isConfigured) {
        final stats = await _githubSyncService.getSyncStatistics();
        _ownerController.text = stats.repositoryOwner ?? '';
        _repoController.text = stats.repositoryName ?? '';
        _branchController.text = stats.branchName ?? 'main';
      }
    } catch (e) {
      _showErrorSnackBar('github_sync.load_config_error'.tr());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
      appBar: AppBar(
        title: Text('github_sync.title'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isConfigured)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _manualSync,
              tooltip: 'github_sync.manual_sync'.tr(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveHelper.responsiveContainer(
              context: context,
              padding: ResponsiveHelper.responsivePadding(
                context,
                mobile: const EdgeInsets.all(16),
                tablet: const EdgeInsets.all(24),
                desktop: const EdgeInsets.all(32),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GitHub Logo and Title
                    _buildHeader(theme, isDark),
                    const SizedBox(height: 32),

                    // Configuration Status
                    _buildStatusCard(theme, isDark),
                    const SizedBox(height: 24),

                    // Configuration Form
                    if (!_isConfigured) ...[
                      _buildConfigurationForm(theme, isDark),
                      const SizedBox(height: 24),
                    ],



                    // Action Buttons
                    _buildActionButtons(theme, isDark),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build header section
  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF24292E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.code,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'github_sync.header_title'.tr(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'github_sync.header_subtitle'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build status card
  Widget _buildStatusCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _isConfigured ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConfigured 
                      ? 'github_sync.configured'.tr()
                      : 'github_sync.not_configured'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isConfigured
                      ? 'github_sync.configured_desc'.tr()
                      : 'github_sync.not_configured_desc'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build configuration form
  Widget _buildConfigurationForm(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'github_sync.configuration'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 20),

            // GitHub Token
            AccessibilityHelper.createAccessibleTextField(
              controller: _tokenController,
              label: 'github_sync.token_label'.tr(),
              hint: 'github_sync.token_hint'.tr(),
              required: true,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'github_sync.token_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Repository Owner
            AccessibilityHelper.createAccessibleTextField(
              controller: _ownerController,
              label: 'github_sync.owner_label'.tr(),
              hint: 'github_sync.owner_hint'.tr(),
              required: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'github_sync.owner_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Repository Name
            AccessibilityHelper.createAccessibleTextField(
              controller: _repoController,
              label: 'github_sync.repo_label'.tr(),
              hint: 'github_sync.repo_hint'.tr(),
              required: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'github_sync.repo_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Branch Name
            AccessibilityHelper.createAccessibleTextField(
              controller: _branchController,
              label: 'github_sync.branch_label'.tr(),
              hint: 'github_sync.branch_hint'.tr(),
              required: false,
            ),
            const SizedBox(height: 24),

            // Configure Existing Repository Button (Primary)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _configureRepository,
                icon: const Icon(Icons.settings, size: 20),
                label: Text(
                  'github_sync.configure_existing'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: const Color(0xFF137FEC).withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }




  /// Build action buttons
  Widget _buildActionButtons(ThemeData theme, bool isDark) {
    return Column(
      children: [
        if (_isConfigured) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _manualSync,
              icon: const Icon(Icons.sync),
              label: Text('github_sync.manual_sync'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137FEC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearConfiguration,
              icon: const Icon(Icons.clear),
              label: Text('github_sync.clear_config'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }


  /// Configure existing repository
  Future<void> _configureRepository() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _githubSyncService.configureGitHub(
        token: _tokenController.text.trim(),
        repositoryOwner: _ownerController.text.trim(),
        repositoryName: _repoController.text.trim(),
        branchName: _branchController.text.trim(),
      );

      if (success) {
        _showSuccessSnackBar('github_sync.config_saved'.tr());
        await _loadConfiguration();
      } else {
        _showErrorSnackBar('github_sync.config_failed'.tr());
      }
    } catch (e) {
      _showErrorSnackBar('github_sync.config_error'.tr());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  /// Manual sync
  Future<void> _manualSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _githubSyncService.syncAll();
      if (result.success) {
        _showSuccessSnackBar('github_sync.sync_success'.tr());
        await _loadConfiguration();
      } else {
        _showErrorSnackBar('github_sync.sync_failed'.tr());
      }
    } catch (e) {
      _showErrorSnackBar('github_sync.sync_error'.tr());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Clear configuration
  Future<void> _clearConfiguration() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('github_sync.clear_config_title'.tr()),
        content: Text('github_sync.clear_config_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('buttons.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('buttons.clear'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _githubSyncService.clearGitHubConfig();
      _showSuccessSnackBar('github_sync.config_cleared'.tr());
      await _loadConfiguration();
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
