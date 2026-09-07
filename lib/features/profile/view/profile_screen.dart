// lib/features/profile/view/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_task_manager/core/theme/theme_provider.dart';
import 'package:smart_task_manager/core/utils/date_formatter.dart';
import 'package:smart_task_manager/core/utils/validators.dart';
import 'package:smart_task_manager/features/auth/controller/auth_controller.dart';
import 'package:smart_task_manager/features/profile/controller/profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).fetchProfile();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;

    // Populate name when profile loads
    if (profileState.profile != null && _nameCtrl.text.isEmpty) {
      _nameCtrl.text = profileState.profile!.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit profile',
            ),
        ],
      ),
      body: profileState.isLoading && profileState.profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  _Avatar(
                    name: profileState.profile?.name ??
                        authState.user?.displayName ??
                        '?',
                  ).animate().scale(
                        begin: const Offset(0.5, 0.5),
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      ),
                  const SizedBox(height: 8),

                  if (!_isEditing) ...[
                    Text(
                      profileState.profile?.name ?? authState.user?.displayName ?? '',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 4),
                    Text(
                      profileState.profile?.email ?? authState.user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ).animate().fadeIn(delay: 150.ms),
                    if (profileState.profile?.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Member since ${DateFormatter.formatDate(profileState.profile!.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ],

                  const SizedBox(height: 32),

                  // Edit Form
                  if (_isEditing)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Edit Profile',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameCtrl,
                                validator: Validators.validateName,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          setState(() => _isEditing = false),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: profileState.isLoading
                                          ? null
                                          : _saveProfile,
                                      child: profileState.isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Save'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(),

                  // Settings card
                  Card(
                    child: Column(
                      children: [
                        // Dark mode toggle
                        SwitchListTile.adaptive(
                          value: themeMode == ThemeMode.dark,
                          onChanged: (_) => ref
                              .read(themeControllerProvider.notifier)
                              .toggleTheme(),
                          secondary: Icon(
                            themeMode == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: scheme.primary,
                          ),
                          title: const Text('Dark Mode'),
                          subtitle: Text(
                            themeMode == ThemeMode.dark
                                ? 'Currently dark'
                                : 'Currently light',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        const Divider(height: 1),

                        // Logout
                        ListTile(
                          leading: Icon(
                            Icons.logout_rounded,
                            color: scheme.error,
                          ),
                          title: Text(
                            'Sign Out',
                            style: TextStyle(color: scheme.error),
                          ),
                          onTap: _confirmLogout,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(profileControllerProvider.notifier).updateProfile(
          name: _nameCtrl.text,
        );
    if (mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('You will be logged out of your account.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

// ── Avatar ────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
