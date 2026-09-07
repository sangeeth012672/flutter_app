// lib/core/constants/app_strings.dart

class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Smart Task Manager';

  // Auth
  static const String login = 'Sign In';
  static const String register = 'Create Account';
  static const String logout = 'Sign Out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String forgotPassword = 'Forgot password?';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';

  // Tasks
  static const String tasks = 'Tasks';
  static const String myTasks = 'My Tasks';
  static const String addTask = 'Add Task';
  static const String editTask = 'Edit Task';
  static const String deleteTask = 'Delete Task';
  static const String taskTitle = 'Title';
  static const String taskDescription = 'Description';
  static const String dueDate = 'Due Date';
  static const String priority = 'Priority';
  static const String category = 'Category';
  static const String search = 'Search tasks...';
  static const String all = 'All';
  static const String completed = 'Completed';
  static const String pending = 'Pending';
  static const String sortBy = 'Sort By';
  static const String sortDueDate = 'Due Date';
  static const String sortPriority = 'Priority';
  static const String sortCreatedDate = 'Created Date';

  // Empty states
  static const String noTasks = 'No tasks yet';
  static const String noTasksSubtitle = 'Tap the + button to add your first task';
  static const String noResultsFound = 'No results found';
  static const String noResultsSubtitle = 'Try a different search or filter';

  // Offline
  static const String offlineBanner = 'You\'re offline • Showing cached data';

  // Profile
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String darkMode = 'Dark Mode';
  static const String updateProfile = 'Update Profile';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection. Please check your network.';
  static const String sessionExpired = 'Session expired. Please log in again.';

  // Confirmations
  static const String confirmDelete = 'Delete Task?';
  static const String confirmDeleteBody = 'This action cannot be undone.';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String save = 'Save';
  static const String update = 'Update';
}
