// lib/core/utils/date_formatter.dart
import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _display = DateFormat('MMM d, yyyy');
  static final DateFormat _displayWithTime = DateFormat('MMM d, yyyy • h:mm a');

  /// Format: "Sep 7, 2026"
  static String formatDate(DateTime? date) {
    if (date == null) return 'No due date';
    return _display.format(date.toLocal());
  }

  /// Format: "Sep 7, 2026 • 3:00 PM"
  static String formatDateTime(DateTime? date) {
    if (date == null) return 'No due date';
    return _displayWithTime.format(date.toLocal());
  }

  /// Relative label: "Today", "Tomorrow", "Overdue", or "Sep 7, 2026"
  static String formatRelative(DateTime? date) {
    if (date == null) return 'No due date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return 'Overdue';
    return _display.format(date.toLocal());
  }

  /// Check if a date is overdue
  static bool isOverdue(DateTime? date) {
    if (date == null) return false;
    return date.toLocal().isBefore(DateTime.now());
  }

  /// Parse ISO 8601 string to DateTime
  static DateTime? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Convert to ISO 8601 for API
  static String? toIsoString(DateTime? date) {
    if (date == null) return null;
    return date.toUtc().toIso8601String();
  }
}
