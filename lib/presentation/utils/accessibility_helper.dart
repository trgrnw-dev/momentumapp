import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Вспомогательный класс для функций доступности
/// Предоставляет утилиты для экранных читалок, масштабирования текста и доступности
class AccessibilityHelper {
  AccessibilityHelper._();

  /// Минимальный размер области касания (48x48 согласно Material Design)
  static const double minTouchTargetSize = 48.0;

  /// Проверить, включен ли экранный читатель
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// Получить коэффициент масштабирования текста
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  /// Проверить, масштабирован ли текст
  static bool isTextScaled(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0) > 1.0;
  }

  /// Проверить, включен ли жирный текст (iOS)
  static bool isBoldTextEnabled(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// Проверить, включено ли уменьшение движения
  static bool isReduceMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Получить доступный размер текста
  static double getAccessibleTextSize(BuildContext context, double baseSize) {
    final textScaleFactor = getTextScaleFactor(context);
    return baseSize * textScaleFactor;
  }

  /// Make widget accessible with semantic label
  static Widget makeAccessible({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    bool excludeSemantics = false,
    bool button = false,
    bool link = false,
    bool header = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button,
      link: link,
      header: header,
      onTap: onTap,
      onLongPress: onLongPress,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }

  /// Create semantic label for task card
  static String taskCardSemanticLabel({
    required String title,
    required bool isCompleted,
    required String priority,
    required DateTime dueDate,
    String? category,
  }) {
    final buffer = StringBuffer();
    buffer.write('Task: $title. ');
    buffer.write(isCompleted ? 'Completed. ' : 'Not completed. ');
    buffer.write('Priority: $priority. ');
    buffer.write('Due date: ${_formatDateForScreenReader(dueDate)}. ');
    if (category != null && category.isNotEmpty) {
      buffer.write('Category: $category. ');
    }
    buffer.write('Double tap to open details.');
    return buffer.toString();
  }

  /// Create semantic label for checkbox
  static String checkboxSemanticLabel({
    required String taskTitle,
    required bool isChecked,
  }) {
    return '$taskTitle, checkbox, ${isChecked ? "checked" : "unchecked"}';
  }

  /// Create semantic label for delete button
  static String deleteButtonSemanticLabel(String itemName) {
    return 'Delete $itemName, button';
  }

  /// Create semantic label for edit button
  static String editButtonSemanticLabel(String itemName) {
    return 'Edit $itemName, button';
  }

  /// Format date for screen reader
  static String _formatDateForScreenReader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${_monthName(date.month)} ${date.day}, ${date.year}';
    }
  }

  /// Get month name
  static String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  /// Announce message to screen reader
  static void announce(
    BuildContext context,
    String message, {
    Assertiveness assertiveness = Assertiveness.polite,
  }) {
    if (isScreenReaderEnabled(context)) {
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  /// Announce task created
  static void announceTaskCreated(BuildContext context, String taskTitle) {
    announce(context, 'Task "$taskTitle" created successfully');
  }

  /// Announce task completed
  static void announceTaskCompleted(BuildContext context, String taskTitle) {
    announce(context, 'Task "$taskTitle" marked as completed');
  }

  /// Announce task deleted
  static void announceTaskDeleted(BuildContext context, String taskTitle) {
    announce(context, 'Task "$taskTitle" deleted');
  }

  /// Announce error
  static void announceError(BuildContext context, String error) {
    announce(context, 'Error: $error', assertiveness: Assertiveness.assertive);
  }

  /// Check if widget size is accessible (touch target)
  static bool isAccessibleSize(double width, double height) {
    return width >= minTouchTargetSize && height >= minTouchTargetSize;
  }

  /// Make touch target accessible size
  static Widget makeAccessibleTouchTarget({
    required Widget child,
    double minWidth = minTouchTargetSize,
    double minHeight = minTouchTargetSize,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
      child: child,
    );
  }

  /// Check color contrast ratio (WCAG AA: 4.5:1 for normal text)
  static double calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if color contrast is accessible (WCAG AA)
  static bool isContrastAccessible(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= 4.5;
  }

  /// Get accessible color pair (adjust if needed)
  static Color getAccessibleForegroundColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Create focus node with semantic label
  static FocusNode createAccessibleFocusNode(String label) {
    return FocusNode(debugLabel: label);
  }

  /// Wrap widget with semantic container
  static Widget wrapWithSemanticContainer({
    required Widget child,
    required String label,
    bool isButton = false,
    bool isHeader = false,
    bool isLink = false,
    bool explicitChildNodes = false,
  }) {
    return Semantics(
      container: true,
      label: label,
      button: isButton,
      header: isHeader,
      link: isLink,
      explicitChildNodes: explicitChildNodes,
      child: child,
    );
  }

  /// Create semantic live region for dynamic content
  static Widget createLiveRegion({
    required Widget child,
    required String label,
    bool liveRegion = true,
  }) {
    return Semantics(liveRegion: liveRegion, label: label, child: child);
  }

  /// Get semantic hint for form field
  static String getFormFieldHint(String fieldName, bool required) {
    if (required) {
      return '$fieldName, required field';
    }
    return '$fieldName, optional field';
  }

  /// Create semantic label for progress indicator
  static String progressSemanticLabel(double progress) {
    final percentage = (progress * 100).round();
    return 'Progress: $percentage percent';
  }

  /// Create semantic label for loading state
  static String loadingSemanticLabel(String? message) {
    return message != null ? 'Loading: $message' : 'Loading';
  }

  /// Exclude widget from semantics tree
  static Widget excludeSemantics(Widget child) {
    return ExcludeSemantics(child: child);
  }

  /// Merge semantics of children
  static Widget mergeSemantics(Widget child) {
    return MergeSemantics(child: child);
  }

  /// Get accessible padding based on text scale
  static EdgeInsets getAccessiblePadding(
    BuildContext context,
    EdgeInsets basePadding,
  ) {
    final scaleFactor = getTextScaleFactor(context);
    if (scaleFactor <= 1.0) return basePadding;

    return EdgeInsets.fromLTRB(
      basePadding.left * scaleFactor,
      basePadding.top * scaleFactor,
      basePadding.right * scaleFactor,
      basePadding.bottom * scaleFactor,
    );
  }

  /// Get accessible spacing
  static double getAccessibleSpacing(BuildContext context, double baseSpacing) {
    final scaleFactor = getTextScaleFactor(context);
    return baseSpacing * scaleFactor.clamp(1.0, 1.5);
  }

  /// Create accessible icon button with label
  static Widget createAccessibleIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    double size = 24.0,
    Color? color,
    String? tooltip,
  }) {
    return Semantics(
      button: true,
      label: label,
      hint: 'Double tap to activate',
      child: Tooltip(
        message: tooltip ?? label,
        child: IconButton(
          icon: Icon(icon, size: size, color: color),
          onPressed: onPressed,
          iconSize: size,
        ),
      ),
    );
  }

  /// Create accessible text with proper scaling
  static Widget createAccessibleText(
    BuildContext context,
    String text, {
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign? textAlign,
    bool selectable = false,
  }) {
    final accessibleStyle = style?.copyWith(
      fontSize: style.fontSize != null
          ? getAccessibleTextSize(context, style.fontSize!)
          : null,
    );

    if (selectable) {
      return SelectableText(
        text,
        style: accessibleStyle,
        maxLines: maxLines,
        textAlign: textAlign,
      );
    }

    return Text(
      text,
      style: accessibleStyle,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }

  /// Get platform-specific semantic properties
  static Map<String, String> getPlatformSemantics(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.iOS:
        return {
          'activate': 'Double tap',
          'dismiss': 'Two-finger scrub',
          'navigate': 'Swipe',
        };
      case TargetPlatform.android:
        return {
          'activate': 'Double tap',
          'dismiss': 'Swipe down then left',
          'navigate': 'Swipe right or left',
        };
      default:
        return {
          'activate': 'Press Enter or Space',
          'dismiss': 'Press Escape',
          'navigate': 'Use Tab',
        };
    }
  }

  /// Create accessible form field
  static Widget createAccessibleTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLines = 1,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return Semantics(
      textField: true,
      label: label,
      hint: getFormFieldHint(label, required),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  /// Validate accessibility of widget tree
  static Future<void> validateAccessibility(BuildContext context) async {
    // Check text scale factor
    final textScale = getTextScaleFactor(context);
    if (textScale > 2.0) {
      debugPrint('Warning: Text scale factor is very high ($textScale)');
    }

    // Check if screen reader is enabled
    if (isScreenReaderEnabled(context)) {
      debugPrint('Screen reader is enabled');
    }

    // Additional validation can be added here
  }

  /// Get accessibility settings summary
  static Map<String, dynamic> getAccessibilitySettings(BuildContext context) {
    return {
      'screenReaderEnabled': isScreenReaderEnabled(context),
      'textScaleFactor': getTextScaleFactor(context),
      'boldText': isBoldTextEnabled(context),
      'reduceMotion': isReduceMotionEnabled(context),
      'accessibleNavigation': MediaQuery.of(context).accessibleNavigation,
      'highContrast': MediaQuery.of(context).highContrast,
      'invertColors': MediaQuery.of(context).invertColors,
    };
  }
}

/// Assertiveness levels for screen reader announcements
enum Assertiveness {
  /// Polite announcement (wait for current speech to finish)
  polite,

  /// Assertive announcement (interrupt current speech)
  assertive,
}
