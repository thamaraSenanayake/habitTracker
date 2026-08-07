import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/user_profile_model.dart';
import '../services/database_helper.dart';
import '../theme/theme_ext.dart';
import 'sign_in_view.dart';

class WelcomeView extends ConsumerStatefulWidget {
  const WelcomeView({super.key});

  @override
  ConsumerState<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends ConsumerState<WelcomeView> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<UserProfileModel> _localProfiles = [];
  bool _hasLocalProfile = false;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _checkLocalProfile();
  }

  Future<void> _checkLocalProfile() async {
    try {
      final localProfileCreated = await DatabaseHelper.instance.getSetting('local_profile_created', 'false');
      if (localProfileCreated == 'true') {
        final profiles = await DatabaseHelper.instance.getAllLocalProfiles();
        if (mounted) {
          setState(() {
            _localProfiles = profiles;
            _hasLocalProfile = profiles.isNotEmpty;
            _isLoadingProfile = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: _isLoadingProfile
                ? const CircularProgressIndicator(
                    color: Color(0xFF8083FF),
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Branding Header
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF8083FF).withOpacity(0.1),
                            ),
                            child: const Icon(
                              Icons.track_changes_rounded,
                              size: 64,
                              color: Color(0xFF8083FF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'HabitFlow',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8083FF),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Build consistency, offline first.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: context.secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // Render Card dynamically depending on profile existence
                        _hasLocalProfile ? _buildQuickLoginCard() : _buildSetupCard(),
                        
                        const SizedBox(height: 32),

                        // Already a member? Log In Link
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignInView(isFromSettings: false),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Already a member? ',
                                style: GoogleFonts.plusJakartaSans(
                                  color: context.secondaryTextColor,
                                  fontSize: 14,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Log In',
                                    style: TextStyle(
                                      color: Color(0xFF8083FF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.textColor.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Continue with local profile',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 16),
          // List each profile
          ..._localProfiles.map((profile) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () {
                  ref.read(authProvider.notifier).loginAsLocalUser(profile.id?.toString() ?? '1');
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.textColor.withOpacity(0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF8083FF).withOpacity(0.1),
                        child: const Icon(Icons.person_rounded, color: Color(0xFF8083FF), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          profile.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF8083FF)),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _hasLocalProfile = false;
              });
            },
            child: Text(
              'Create a new local profile',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF8083FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.textColor.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us your name',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We will store your name locally to personalize your habit logs.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: context.secondaryTextColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.plusJakartaSans(color: context.textColor),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: context.secondaryTextColor.withOpacity(0.4),
              ),
              fillColor: context.bgColor,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Get Started Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ref
                      .read(authProvider.notifier)
                      .completeLocalSetup(_nameController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8083FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Get Started',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
