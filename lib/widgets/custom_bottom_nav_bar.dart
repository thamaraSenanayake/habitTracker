import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_ext.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: context.cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: context.isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.4 : 0.05),
            blurRadius: 20.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            index: 0,
            icon: Icons.home_rounded,
            label: 'Today',
          ),
          _buildNavItem(
            context: context,
            index: 1,
            icon: Icons.bar_chart_rounded,
            label: 'Analytics',
          ),
          _buildNavItem(
            context: context,
            index: 2,
            icon: Icons.settings_rounded,
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF8083FF)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18.0),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF94A3B8),
              size: 24.0,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.0,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF8083FF)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
