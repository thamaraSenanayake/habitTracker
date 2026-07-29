import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_flow/models/habit_model.dart';
import 'package:habit_flow/views/habit_detail_view.dart';
import '../theme/theme_ext.dart';

class HabitCard extends StatefulWidget {
  final HabitModel habit;
  final Future<void> Function() onDone;
  final bool isDone;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onDone,
    required this.isDone,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(widget.habit.category);
    final iconData = _getIconData(widget.habit.icon);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HabitDetailView(habit: widget.habit),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: catColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.habit.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                      decoration: widget.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    widget.habit.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        await widget.onDone();
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isDone ? const Color(0xFF22C55E) : Colors.transparent,
                  border: widget.isDone
                      ? null
                      : Border.all(
                          color: context.isDark
                              ? const Color(0xFF464554)
                              : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                  boxShadow: widget.isDone
                      ? [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.isDone
                                ? (context.isDark ? const Color(0xFF0F172A) : Colors.white)
                                : const Color(0xFF22C55E),
                          ),
                        ),
                      )
                    : (widget.isDone
                        ? Icon(
                            Icons.check,
                            color: context.isDark ? const Color(0xFF0F172A) : Colors.white,
                            size: 20,
                          )
                        : null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hydration':
        return const Color(0xFF8083FF); // Primary Purple
      case 'reading':
        return const Color(0xFFFFB783); // Tertiary Light Orange
      case 'fitness':
        return const Color(0xFFFFB690); // Secondary Coral
      case 'mindfulness':
        return const Color(0xFFFFDCC5); // Muted Beige/Pink
      default:
        return const Color(0xFFC0C1FF);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'menu_book':
      case 'book':
        return Icons.menu_book_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'self_improvement':
      case 'psychology':
        return Icons.self_improvement_rounded;
      case 'directions_run':
        return Icons.directions_run_rounded;
      case 'restaurant':
      case 'nutrition':
        return Icons.restaurant_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}
