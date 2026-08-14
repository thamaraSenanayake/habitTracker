import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_flow/dialog/settings_edit.dart';
import '../viewmodels/habit_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'privacy_policy_view.dart';
import 'sign_in_view.dart';
import '../theme/theme_ext.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitViewModelProvider);
    final vm = ref.read(habitViewModelProvider.notifier);
    final authState = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final profile = state.userProfile;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // leading: Padding(
        //   padding: const EdgeInsets.all(12.0),
        //   child: Container(
        //     decoration: const BoxDecoration(
        //       shape: BoxShape.circle,
        //       color: Color(0xFF8083FF),
        //     ),
        //     alignment: Alignment.center,
        //     child: const Icon(
        //       Icons.person,
        //       color: Colors.white,
        //       size: 16,
        //     ),
        //   ),
        // ),
        titleSpacing: 0,
        title: Text(
          'HabitFlow',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF8083FF),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 32.0),
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 200),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(
                  child: widget,
                ),
              ),
                  children: [
                    // Profile Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              context.isDark ? 0.2 : 0.05,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundImage: profile?.avatarData != null
                                    ? MemoryImage(profile!.avatarData!)
                                    : (profile != null && profile.avatarUrl.isNotEmpty
                                          ? NetworkImage(profile.avatarUrl)
                                                as ImageProvider
                                          : null),
                                backgroundColor: context.isDark
                                    ? const Color(0xFF34343D)
                                    : const Color(0xFFE2E8F0),
                                child:
                                    (profile == null ||
                                        (profile.avatarData == null &&
                                            profile.avatarUrl.isEmpty))
                                    ? Icon(
                                        Icons.person,
                                        size: 36,
                                        color: context.secondaryTextColor,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF22C55E),
                                    border: Border.all(
                                      color: context.cardColor,
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      profile?.name ?? "",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: context.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authState.email ?? 'account not linked',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: context.secondaryTextColor,
                                    fontStyle: authState.email == null ? FontStyle.italic : FontStyle.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (profile != null) {
                                showEditProfileDialog(context, profile, vm);
                              }
                            },
                            icon: const Icon(
                              Icons.edit_rounded,
                              color: Color(0xFF8083FF),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                          
                    // Settings List Section 1: Account
                    _buildSectionHeader('Account'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            icon: Icons.cloud_sync_rounded,
                            iconColor: const Color(0xFF60A5FA),
                            title: 'Account & Cloud Sync',
                            value: ref.watch(authProvider).isCloudSyncEnabled,
                            onChanged: (val) async {
                              if (val && ref.read(authProvider).email == null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignInView(isFromSettings: true),
                                  ),
                                );
                              } else {
                                // Show loader dialog to prevent input while syncing
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: context.isDark
                                            ? const Color(0xFF1E293B)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF22C55E),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                                try {
                                  await ref.read(authProvider.notifier).toggleCloudSync(val);
                                } finally {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              }
                            },
                          ),
                          Divider(
                            color: context.textColor.withOpacity(0.05),
                            height: 1,
                          ),
                          _buildLinkTile(
                            icon: Icons.ios_share_rounded,
                            iconColor: const Color(0xFFFFB783),
                            title: 'Export Data (CSV/JSON)',
                            onTap: () async {
                              // Show loader dialog
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: context.isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF8083FF),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                              try {
                                await ref
                                    .read(settingsProvider.notifier)
                                    .exportJson(state, context);
                              } finally {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                          
                    // Settings List Section 2: Preferences
                    _buildSectionHeader('Preferences'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            icon: Icons.dark_mode_rounded,
                            iconColor: const Color(0xFF8083FF),
                            title: 'Dark Mode',
                            value: ref.watch(themeProvider) == ThemeMode.dark,
                            onChanged: (val) {
                              ref
                                  .read(themeProvider.notifier)
                                  .setThemeMode(
                                    val ? ThemeMode.dark : ThemeMode.light,
                                  );
                            },
                          ),
                          Divider(
                            color: context.textColor.withOpacity(0.05),
                            height: 1,
                          ),
                          _buildSwitchTile(
                            icon: Icons.notifications_active_rounded,
                            iconColor: const Color(0xFFFFB690),
                            title: 'Daily Push Notifications',
                            value: settings.notificationsEnabled,
                            onChanged: (val) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setNotificationsEnabled(val);
                            },
                          ),
                          // Divider(
                          //   color: context.textColor.withOpacity(0.05),
                          //   height: 1,
                          // ),
                          // _buildSwitchTile(
                          //   icon: Icons.volume_up_rounded,
                          //   iconColor: const Color(0xFFF472B6),
                          //   title: 'Sound Effects',
                          //   value: settings.soundEnabled,
                          //   onChanged: (val) {
                          //     ref
                          //         .read(settingsProvider.notifier)
                          //         .setSoundEnabled(val);
                          //   },
                          // ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                          
                    // Settings List Section 3: About
                    _buildSectionHeader('About & Support'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildLinkTile(
                            icon: Icons.policy_rounded,
                            iconColor: const Color(0xFF908FA0),
                            title: 'Privacy Policy',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PrivacyPolicyView(),
                                ),
                              );
                            },
                          ),
                          // Divider(
                          //   color: context.textColor.withOpacity(0.05),
                          //   height: 1,
                          // ),
                          // _buildLinkTile(
                          //   icon: Icons.star_rounded,
                          //   iconColor: const Color(0xFFF59E0B),
                          //   title: 'Rate App on Play Store',
                          //   onTap: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (context) => const PrivacyPolicyView(),
                          //       ),
                          //     );
                          //   },
                          // ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                          
                    // App Version
                    Center(
                      child: Text(
                        'App Version 1.0.0',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: context.secondaryTextColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                          
                    // Sign Out / Reset Profile Button
                    Center(
                      child: InkWell(
                        onTap: () => ref.read(authProvider.notifier).signOut(),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFFffb4ab).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFffb4ab),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                authState.email != null ? 'Sign Out' : 'Sign Out / Reset Profile',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFFffb4ab),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: context.secondaryTextColor.withOpacity(0.6),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.textColor,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF22C55E),
            activeTrackColor: const Color(0xFF22C55E).withOpacity(0.3),
            inactiveThumbColor: context.secondaryTextColor,
            inactiveTrackColor: context.isDark
                ? const Color(0xFF34343D)
                : const Color(0xFFE2E8F0),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? trailingText,
    Color? trailingTextColor,
    bool isExternal = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.textColor,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: trailingTextColor ?? context.secondaryTextColor,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              isExternal
                  ? Icons.open_in_new_rounded
                  : Icons.chevron_right_rounded,
              color: context.secondaryTextColor.withOpacity(0.8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
