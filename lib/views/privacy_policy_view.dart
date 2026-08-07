import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_ext.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.plusJakartaSans(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Privacy Matters',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8083FF),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Last Updated: August 2026',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: context.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: '1. Local-First Data Storage',
                content:
                    'HabitFlow prioritizes your privacy by keeping your data on your device. All habits, completion history, streaks, and settings are saved locally using an encrypted SQLite database. We do not require passwords to be stored locally to ensure maximum security.',
              ),
              _buildSection(
                context,
                title: '2. Optional Cloud Sync',
                content:
                    'You have full control over your data. By enabling "Account & Cloud Sync" in the settings, your profile picture, username, and habit logs will sync with Google Firebase Firestore. Toggling this option off immediately stops cloud uploads, keeping your logs entirely offline.',
              ),
              _buildSection(
                context,
                title: '3. Local Notifications',
                content:
                    'Reminder notifications are scheduled locally on your device via the flutter_local_notifications plugin. We do not use remote push servers or trackers to deliver these reminders, and all scheduling is calculated locally using timezone offsets.',
              ),
              _buildSection(
                context,
                title: '4. Data Export & Rights',
                content:
                    'You own your data. At any time, you can export your entire habit list and completion history in JSON format via the "Export Data" button in your settings to save it or share it elsewhere.',
              ),
              _buildSection(
                context,
                title: '5. Information Security',
                content:
                    'We employ standard device sandboxing and safety measures. No analytical trackers, third-party advertisement scripts, or behavioral tracking SDKs are present in HabitFlow.',
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'HabitFlow • Built Secure',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.secondaryTextColor.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: context.secondaryTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
