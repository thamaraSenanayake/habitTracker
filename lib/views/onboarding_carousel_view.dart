import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../theme/theme_ext.dart';

class OnboardingCarouselView extends ConsumerStatefulWidget {
  const OnboardingCarouselView({super.key});

  @override
  ConsumerState<OnboardingCarouselView> createState() => _OnboardingCarouselViewState();
}

class _OnboardingCarouselViewState extends ConsumerState<OnboardingCarouselView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      _OnboardingSlideData(
        title: 'Track Daily Habits',
        description: 'Set custom targets, log logs, and check off tasks with fluid swipe gestures.',
        mockup: _buildMockupContainer(
          context,
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF8083FF),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMockItem(context, 'Drink Water', '2 / 3 Liters', 0.6, const Color(0xFF8083FF)),
              const SizedBox(height: 12),
              _buildMockItem(context, 'Read Books', '15 / 20 pages', 0.75, const Color(0xFFFFB783)),
            ],
          ),
        ),
      ),
      _OnboardingSlideData(
        title: 'Keep Streaks Alive',
        description: 'Establish consistent routines. Every completed log fuels your streaks.',
        mockup: _buildMockupContainer(
          context,
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF8551),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStreakDay(context, 'M', true),
                _buildStreakDay(context, 'T', true),
                _buildStreakDay(context, 'W', true),
                _buildStreakDay(context, 'T', true),
                _buildStreakDay(context, 'F', false),
              ],
            ),
          ),
        ),
      ),
      _OnboardingSlideData(
        title: 'Secure & Local First',
        description: 'Your habits data is stored locally. Choose to enable cloud synchronization anytime.',
        mockup: _buildMockupContainer(
          context,
          icon: Icons.security_rounded,
          color: const Color(0xFF10B981),
          child: Center(
            child: Icon(
              Icons.phonelink_lock_rounded,
              size: 72,
              color: const Color(0xFF10B981).withOpacity(0.8),
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'How it works',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8083FF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A quick look at HabitFlow features',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: context.secondaryTextColor,
                ),
              ),
              const Spacer(),

              // Page Slider
              SizedBox(
                height: 290,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Column(
                      children: [
                        slide.mockup,
                        const SizedBox(height: 24),
                        Text(
                          slide.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            slide.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: context.secondaryTextColor,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 8,
                    width: _currentPage == index ? 20 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF8083FF)
                          : context.textColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(height: 32),

              // Action Button (Start Tracking)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).completeOnboardingCarousel();
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
                    _currentPage == slides.length - 1 ? "Let's Go!" : 'Got It!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockupContainer(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.textColor.withOpacity(0.05),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Icon(
              icon,
              size: 96,
              color: color.withOpacity(0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildMockItem(
    BuildContext context,
    String title,
    String subtitle,
    double progress,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircularProgressIndicator(
          value: progress,
          strokeWidth: 4,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildStreakDay(BuildContext context, String label, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFF8551) : Colors.transparent,
        border: Border.all(
          color: active ? Colors.transparent : context.textColor.withOpacity(0.1),
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : context.secondaryTextColor,
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  final String title;
  final String description;
  final Widget mockup;

  _OnboardingSlideData({
    required this.title,
    required this.description,
    required this.mockup,
  });
}
