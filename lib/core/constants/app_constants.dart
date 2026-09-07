// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // API
  static const String baseUrl = 'https://taskmanager.uat-lplusltd.com';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Pagination
  static const int pageLimit = 10;

  // Hive Boxes
  static const String tasksBox = 'tasks_box';
  static const String settingsBox = 'settings_box';

  // Hive Keys
  static const String tasksKey = 'cached_tasks';
  static const String themeModeKey = 'theme_mode';

  // Search debounce
  static const int searchDebounceMs = 400;
}
