import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/habit_viewmodel.dart';
import 'add_habit_view.dart';
import 'habit_detail_view.dart';

class TodayView extends ConsumerWidget {
  const TodayView({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitViewModelProvider);
    final vm = ref.read(habitViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${state.userProfile?.name ?? "Alex Morgan"} 👋',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE4E1ED),
                        ),
                      ),
                      Text(
                        'Tuesday, Oct 24',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFFC7C4D7),
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: state.userProfile?.avatarUrl != null && state.userProfile!.avatarUrl.isNotEmpty
                        ? NetworkImage(state.userProfile!.avatarUrl)
                        : null,
                    backgroundColor: const Color(0xFF34343D),
                    child: state.userProfile?.avatarUrl == null || state.userProfile!.avatarUrl.isEmpty
                        ? const Icon(Icons.person, color: Color(0xFFC7C4D7))
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Highlight Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Completion',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFFC7C4D7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.completionPercentage}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE4E1ED),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: Color(0xFFF97316),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${state.userProfile?.overallStreak ?? 12}-Day Streak',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF97316),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Progress Ring
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: state.completionPercentage / 100,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFF34343D).withOpacity(0.5),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF22C55E),
                            ),
                          ),
                          const Icon(
                            Icons.trending_up,
                            color: Color(0xFF22C55E),
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Calendar Row
              SizedBox(
                height: 65,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    final dateNum = 23 + index;
                    final isActive = dateNum == 24;

                    return Column(
                      children: [
                        Text(
                          days[index],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isActive
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFC7C4D7),
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF22C55E)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF22C55E).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            '$dateNum',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFC7C4D7),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Today's Habits Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Habits",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE4E1ED),
                    ),
                  ),
                  Text(
                    "View All",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF8083FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Habit Cards
              if (state.habits.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'No habits created yet. Tap + to start!',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFC7C4D7),
                      fontSize: 14,
                    ),
                  ),
                )
              else
                ...state.habits.map((habit) {
                  final isDone = habit.isCompletedOn(state.selectedDate);
                  final catColor = _getCategoryColor(habit.category);
                  final iconData = _getIconData(habit.icon);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HabitDetailView(habit: habit),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                            child: Icon(
                              iconData,
                              color: catColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFE4E1ED),
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                Text(
                                  habit.subtitle,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFFC7C4D7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => vm.toggleHabit(habit.id),
                            icon: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone
                                    ? const Color(0xFF22C55E)
                                    : Colors.transparent,
                                border: isDone
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFF464554),
                                        width: 2,
                                      ),
                                boxShadow: isDone
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF22C55E).withOpacity(0.2),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isDone
                                  ? const Icon(
                                      Icons.check,
                                      color: Color(0xFF0F172A),
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddHabitView(),
            ),
          );
        },
        backgroundColor: const Color(0xFF8083FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, color: Color(0xFF0D0096), size: 30),
      ),
    );
  }
}
