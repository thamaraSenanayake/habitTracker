import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/habit_viewmodel.dart';
import '../models/user_profile_model.dart';
import '../viewmodels/auth_viewmodel.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  void _showEditProfileDialog(BuildContext context, UserProfileModel profile, HabitViewModel vm) {
    final controller = TextEditingController(text: profile.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: Text(
            'Edit Profile Name',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFE4E1ED),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFFC7C4D7)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
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
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFFC7C4D7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  vm.updateProfile(UserProfileModel(
                    name: newName,
                    avatarUrl: profile.avatarUrl,
                    overallStreak: profile.overallStreak,
                    joinedDate: profile.joinedDate,
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
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitViewModelProvider);
    final vm = ref.read(habitViewModelProvider.notifier);
    final authState = ref.watch(authProvider);
    final profile = state.userProfile ?? UserProfileModel(
      name: 'Alex Morgan',
      avatarUrl: '',
      overallStreak: 12,
      joinedDate: 'October 2024',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF8083FF), // Primary Container color
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person,
              color: Color(0xFF0D0096),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Color(0xFFC7C4D7)),
            onPressed: () {},
          ),
        ],
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
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
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
                          backgroundImage: profile.avatarUrl.isNotEmpty
                              ? NetworkImage(profile.avatarUrl)
                              : null,
                          backgroundColor: const Color(0xFF34343D),
                          child: profile.avatarUrl.isEmpty
                              ? const Icon(Icons.person, size: 36, color: Color(0xFFC7C4D7))
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
                              border: Border.all(color: const Color(0xFF1E293B), width: 2),
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
                                profile.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE4E1ED),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8083FF).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'FREE PLAN',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF8083FF),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authState.email ?? 'alex@example.com',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFFC7C4D7).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showEditProfileDialog(context, profile, vm),
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
                  color: const Color(0xFF1F1F27),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildLinkTile(
                      icon: Icons.cloud_sync_rounded,
                      iconColor: const Color(0xFF60A5FA),
                      title: 'Account & Cloud Sync',
                      trailingText: 'Firebase Synced',
                      trailingTextColor: const Color(0xFF22C55E),
                    ),
                    Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    _buildLinkTile(
                      icon: Icons.ios_share_rounded,
                      iconColor: const Color(0xFFFFB783),
                      title: 'Export Data (CSV/JSON)',
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
                  color: const Color(0xFF1F1F27),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildLinkTile(
                      icon: Icons.dark_mode_rounded,
                      iconColor: const Color(0xFF8083FF),
                      title: 'App Theme',
                      trailingText: 'Dark',
                      trailingTextColor: const Color(0xFFC7C4D7),
                    ),
                    Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    _buildSwitchTile(
                      icon: Icons.notifications_active_rounded,
                      iconColor: const Color(0xFFFFB690),
                      title: 'Daily Push Notifications',
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() {
                          _notificationsEnabled = val;
                        });
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    _buildSwitchTile(
                      icon: Icons.volume_up_rounded,
                      iconColor: const Color(0xFFF472B6),
                      title: 'Sound Effects',
                      value: _soundEnabled,
                      onChanged: (val) {
                        setState(() {
                          _soundEnabled = val;
                        });
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
                  color: const Color(0xFF1F1F27),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildLinkTile(
                      icon: Icons.policy_rounded,
                      iconColor: const Color(0xFF908FA0),
                      title: 'Privacy Policy',
                    ),
                    Divider(color: Colors.white.withOpacity(0.05), height: 1),
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
                    color: const Color(0xFFC7C4D7).withOpacity(0.4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFffb4ab).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.logout_rounded, color: Color(0xFFffb4ab), size: 20),
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
          color: const Color(0xFFC7C4D7).withOpacity(0.6),
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
                color: const Color(0xFFE4E1ED),
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF22C55E),
            activeTrackColor: const Color(0xFF22C55E).withOpacity(0.3),
            inactiveThumbColor: const Color(0xFFC7C4D7),
            inactiveTrackColor: const Color(0xFF34343D),
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
  }) {
    return InkWell(
      onTap: () {},
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
                  color: const Color(0xFFE4E1ED),
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: trailingTextColor ?? const Color(0xFFC7C4D7),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              isExternal ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
              color: const Color(0xFFC7C4D7).withOpacity(0.8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
