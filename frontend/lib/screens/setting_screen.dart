import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../theme/app_colors.dart';
import '../widgets/aurora_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ---------- App Bar ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: textColor),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------- Settings List ----------
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    // Account
                    _SectionLabel('ACCOUNT', subtleColor),
                    _SettingTile(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      subtitle: 'Change your username',
                      surface: surface,
                      subtleColor: subtleColor,
                      textColor: textColor,
                      onTap: () {},
                    ),
                    _SettingTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      surface: surface,
                      subtleColor: subtleColor,
                      textColor: textColor,
                      onTap: () {},
                    ),
                    _SettingTile(
                      icon: Icons.email_outlined,
                      title: 'Email Preferences',
                      subtitle: 'Manage notifications',
                      surface: surface,
                      subtleColor: subtleColor,
                      textColor: textColor,
                      onTap: () {},
                    ),

                    const SizedBox(height: 20),

                    // App
                    _SectionLabel('APP', subtleColor),
                    const _ThemeToggleTile(),
                    _SettingTile(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Push, sound, vibration',
                      surface: surface,
                      subtleColor: subtleColor,
                      textColor: textColor,
                      onTap: () {},
                    ),
                    _SettingTile(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'English (US)',
                      surface: surface,
                      subtleColor: subtleColor,
                      textColor: textColor,
                      onTap: () {},
                    ),

                    const SizedBox(height: 20),

                    // Privacy
                    _SectionLabel('PRIVACY', subtleColor),
                    _SettingTile(
                      icon: Icons.visibility_outlined,
                      title: 'Who can join my rooms',
                      subtitle: 'Everyone',
                      surface: surface,
                      subtleColor: subtleColor,
                      textColor: textColor,
                      onTap: () {},
                    ),
                    _SettingTile(
                      icon: Icons.block_outlined,
                      title: 'Blocked Users',
                      subtitle: 'Manage your block list',
                      surface: surface,
                      subtleColor: subtleColor,
                      textColor: textColor,
                      onTap: () {},
                    ),

                    const SizedBox(height: 20),

                    // About
                    _SectionLabel('ABOUT', subtleColor),
                    _SettingTile(
                      icon: Icons.info_outline,
                      title: 'About Nebularc',
                      subtitle: 'Version 1.0.0',
                      surface: surface,
                      subtleColor: subtleColor,
                      textColor: textColor,
                      onTap: () {},
                    ),
                    _SettingTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      surface: surface,
                      subtleColor: subtleColor,
                      textColor: textColor,
                      onTap: () {},
                    ),
                    _SettingTile(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      surface: surface,
                      subtleColor: subtleColor,
                      textColor: textColor,
                      onTap: () {},
                    ),

                    const SizedBox(height: 30),

                    // Logout
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmLogout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.danger.withOpacity(0.12),
                          foregroundColor: AppColors.danger,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: AppColors.danger.withOpacity(0.3),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        title: const Text('Log Out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final socketService = context.read<SocketService>();
              if (socketService.currentRoom != null) {
                socketService.leaveRoom();
                await Future.delayed(const Duration(milliseconds: 300));
              }

              if (context.mounted) {
                await context.read<AuthService>().logout();
              }
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================================
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color surface;
  final Color subtleColor;
  final Color textColor;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.surface,
    required this.subtleColor,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tileColor: surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: subtleColor, size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(fontSize: 11, color: subtleColor),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: subtleColor, size: 20),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================================
class _ThemeToggleTile extends StatelessWidget {
  const _ThemeToggleTile();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtleColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tileColor: surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          themeProvider.mode == ThemeMode.dark
              ? Icons.dark_mode_outlined
              : themeProvider.mode == ThemeMode.light
                  ? Icons.light_mode_outlined
                  : Icons.brightness_auto_outlined,
          color: subtleColor,
          size: 22,
        ),
        title: Text(
          'Appearance',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(
          themeProvider.mode == ThemeMode.light
              ? 'Light'
              : themeProvider.mode == ThemeMode.dark
                  ? 'Dark'
                  : 'Auto (System)',
          style: TextStyle(fontSize: 11, color: subtleColor),
        ),
        trailing: SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode, size: 14),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto, size: 14),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode, size: 14),
            ),
          ],
          selected: {themeProvider.mode},
          onSelectionChanged: (s) =>
              context.read<ThemeProvider>().setMode(s.first),
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return subtleColor;
            }),
          ),
        ),
      ),
    );
  }
}