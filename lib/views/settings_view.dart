import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/habit_viewmodel.dart';
import '../models/user_profile_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../services/database_helper.dart';
import '../theme/theme_ext.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  void _showEditProfileDialog(BuildContext context, UserProfileModel profile, HabitViewModel vm) {
    final controller = TextEditingController(text: profile.name);
    Uint8List? selectedImageBytes = profile.avatarData;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: context.isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: context.textColor.withOpacity(0.1)),
              ),
              title: Text(
                'Edit Profile',
                style: GoogleFonts.plusJakartaSans(
                  color: context.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        final XFile? file = await openFile(
                          acceptedTypeGroups: <XTypeGroup>[
                            const XTypeGroup(
                              label: 'images',
                              extensions: <String>['jpg', 'png', 'jpeg'],
                            ),
                          ],
                        );
                        if (file != null) {
                          final bytes = await file.readAsBytes();
                          setState(() {
                            selectedImageBytes = bytes;
                          });
                        }
                      } catch (e) {
                        print('Failed to pick profile picture: $e');
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: selectedImageBytes != null
                              ? MemoryImage(selectedImageBytes!)
                              : (profile.avatarUrl.isNotEmpty
                                  ? NetworkImage(profile.avatarUrl) as ImageProvider
                                  : null),
                          backgroundColor: context.isDark ? const Color(0xFF34343D) : const Color(0xFFE2E8F0),
                          child: (selectedImageBytes == null && profile.avatarUrl.isEmpty)
                              ? Icon(Icons.person, size: 40, color: context.secondaryTextColor)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF8083FF),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    style: GoogleFonts.plusJakartaSans(color: context.textColor),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: GoogleFonts.plusJakartaSans(color: context.secondaryTextColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.textColor.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8083FF), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(color: context.secondaryTextColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newName = controller.text.trim();
                    if (newName.isNotEmpty) {
                      vm.updateProfile(profile.copyWith(
                        name: newName,
                        avatarData: selectedImageBytes,
                      ));
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8083FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF8083FF),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.05),
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
                                  ? NetworkImage(profile.avatarUrl) as ImageProvider
                                  : null),
                          backgroundColor: context.isDark ? const Color(0xFF34343D) : const Color(0xFFE2E8F0),
                          child: (profile == null || (profile.avatarData == null && profile.avatarUrl.isEmpty))
                              ? Icon(Icons.person, size: 36, color: context.secondaryTextColor)
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
                                profile?.name ?? "Alex",
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
                            authState.email ?? 'alex@example.com',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (profile != null) {
                          _showEditProfileDialog(context, profile, vm);
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
                      onChanged: (val) {
                        ref.read(authProvider.notifier).toggleCloudSync(val);
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
                        try {
                          final habits = state.habits;
                          final List<Map<String, dynamic>> maps = habits.map((h) => h.toMap()).toList();
                          final String jsonContent = jsonEncode(maps);

                          if (Platform.isAndroid || Platform.isIOS) {
                            final tempDir = await getTemporaryDirectory();
                            final file = File('${tempDir.path}/habit_flow_export.json');
                            await file.writeAsString(jsonContent);

                            await Share.shareXFiles(
                              [XFile(file.path)],
                              subject: 'HabitFlow Data Export',
                            );
                          } else {
                            final FileSaveLocation? result = await getSaveLocation(
                              suggestedName: 'habit_flow_export.json',
                              acceptedTypeGroups: const <XTypeGroup>[
                                XTypeGroup(label: 'JSON', extensions: <String>['json']),
                              ],
                            );
                            if (result != null) {
                              final file = File(result.path);
                              await file.writeAsString(jsonContent);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF22C55E),
                                    content: Text(
                                      'Data exported successfully!',
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFFEF4444),
                                content: Text(
                                  'Export failed: $e',
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                                ),
                              ),
                            );
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
                        ref.read(themeProvider.notifier).setThemeMode(
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
                        ref.read(settingsProvider.notifier).setNotificationsEnabled(val);
                      },
                    ),
                    Divider(
                      color: context.textColor.withOpacity(0.05),
                      height: 1,
                    ),
                    _buildSwitchTile(
                      icon: Icons.volume_up_rounded,
                      iconColor: const Color(0xFFF472B6),
                      title: 'Sound Effects',
                      value: settings.soundEnabled,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).setSoundEnabled(val);
                      },
                    ),
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
                    ),
                    Divider(
                      color: context.textColor.withOpacity(0.05),
                      height: 1,
                    ),
                    _buildLinkTile(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Rate App on Play Store',
                      isExternal: true,
                    ),
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

              // Sign Out Button
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
                          'Sign Out',
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
            inactiveTrackColor: context.isDark ? const Color(0xFF34343D) : const Color(0xFFE2E8F0),
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
              isExternal ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
              color: context.secondaryTextColor.withOpacity(0.8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
