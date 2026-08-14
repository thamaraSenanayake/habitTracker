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
  Map<String, String?> _profileEmails = {};
  bool _hasLocalProfile = false;
  bool _isLoadingProfile = true;
  bool _displayNewLocalProfile = false;

  @override
  void initState() {
    super.initState();
    _checkLocalProfile();
  }

  Future<void> _checkLocalProfile() async {
    try {
      final profiles = await DatabaseHelper.instance.getAllLocalProfiles();
      final emails = <String, String?>{};
      for (final p in profiles) {
        if (int.tryParse(p.userId) == null) {
          final email = await DatabaseHelper.instance.getEmailForUid(p.userId);
          emails[p.userId] = email;
        }
      }
      if (mounted) {
        setState(() {
          _localProfiles = profiles;
          _profileEmails = emails;
          _hasLocalProfile = profiles.isNotEmpty;
          _isLoadingProfile = false;
        });
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
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 24.0,
                ),
                child: _isLoadingProfile
                    ? const CircularProgressIndicator(color: Color(0xFF22C55E))
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // App Branding Header
                            Center(
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF22C55E).withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'HabitFlow',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                            _hasLocalProfile
                                ? _buildQuickLoginCard()
                                : _buildSetupCard(),

                            const SizedBox(height: 32),

                            // Already a member? Log In Link
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignInView(
                                        isFromSettings: false,
                                      ),
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
                                          color: Color(0xFF22C55E),
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

            if (_displayNewLocalProfile && !_hasLocalProfile)
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: IconButton(
                    icon: Container(
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        shape: BoxShape.circle,
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
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: context.textColor,
                        ),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _displayNewLocalProfile = false;
                        _hasLocalProfile = true;
                      });
                    },
                  ),
                ),
              ),
          ],
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
        border: Border.all(color: context.textColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Continue with profile',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 16),
          // List each profile
          ..._localProfiles.map((profile) {
            final isSynced = int.tryParse(profile.userId) == null;
            final email = _profileEmails[profile.userId];
            final subtitle = isSynced
                ? (email ?? 'Synced Account')
                : 'Local Profile';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () {
                  if (isSynced) {
                    _showPasswordDialog(context, email ?? '');
                  } else {
                    ref
                        .read(authProvider.notifier)
                        .loginAsLocalUser(profile.userId);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                        backgroundColor: const Color(0xFF22C55E).withOpacity(0.1),
                        backgroundImage: profile.avatarData != null
                            ? MemoryImage(profile.avatarData!)
                            : (profile.avatarUrl.isNotEmpty
                                ? NetworkImage(profile.avatarUrl)
                                : null),
                        child: (profile.avatarData == null && profile.avatarUrl.isEmpty)
                            ? Icon(
                                isSynced
                                    ? Icons.cloud_done_rounded
                                    : Icons.person_rounded,
                                color: const Color(0xFF22C55E),
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: context.secondaryTextColor.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF22C55E),
                      ),
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
                _displayNewLocalProfile = true;
              });
            },
            child: Text(
              'Create a new local profile',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF22C55E),
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
        border: Border.all(color: context.textColor.withOpacity(0.05)),
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
                backgroundColor: const Color(0xFF22C55E),
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

  Future<void> _showPasswordDialog(BuildContext context, String email) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _PasswordVerificationDialog(email: email);
      },
    );
  }
}

class _PasswordVerificationDialog extends ConsumerStatefulWidget {
  final String email;
  const _PasswordVerificationDialog({required this.email});

  @override
  ConsumerState<_PasswordVerificationDialog> createState() =>
      _PasswordVerificationDialogState();
}

class _PasswordVerificationDialogState
    extends ConsumerState<_PasswordVerificationDialog> {
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Password is required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(authProvider.notifier)
        .signIn(widget.email, password);
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        final errorMsg =
            ref.read(authProvider).errorMessage ??
            'Invalid password. Please try again.';
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.containerColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Verify Password',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: context.textColor,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logging in as ${widget.email}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            enabled: !_isLoading,
            style: GoogleFonts.plusJakartaSans(color: context.textColor),
            decoration: InputDecoration(
              hintText: 'Enter password',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: context.secondaryTextColor.withOpacity(0.4),
              ),
              fillColor: context.bgColor,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: context.secondaryTextColor.withOpacity(0.6),
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.plusJakartaSans(
              color: context.secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Log In',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
