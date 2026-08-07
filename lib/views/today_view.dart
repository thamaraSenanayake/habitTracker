import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_flow/widgets/habitCard.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:animations/animations.dart';
import '../viewmodels/habit_viewmodel.dart';
import '../theme/theme_ext.dart';
import 'add_habit_view.dart';

class TodayView extends ConsumerWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitViewModelProvider);
    final vm = ref.read(habitViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: context.bgColor,
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
                        'Hello, ${state.userProfile?.name ?? ""} 👋',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMM d').format(DateTime.now()),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: state.userProfile?.avatarData != null
                        ? MemoryImage(state.userProfile!.avatarData!)
                        : (state.userProfile?.avatarUrl != null &&
                                state.userProfile!.avatarUrl.isNotEmpty
                            ? NetworkImage(state.userProfile!.avatarUrl) as ImageProvider
                            : null),
                    backgroundColor: context.isDark ? const Color(0xFF34343D) : const Color(0xFFE2E8F0),
                    child: (state.userProfile == null || (state.userProfile!.avatarData == null && state.userProfile!.avatarUrl.isEmpty))
                        ? Icon(Icons.person, color: context.secondaryTextColor)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Highlight Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Completion',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: context.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.completionPercentage}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
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
                            backgroundColor: context.isDark
                                ? const Color(0xFF34343D).withOpacity(0.5)
                                : const Color(0xFFE2E8F0),
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
                    DateTime now = DateTime.now();
                    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    int dateNum =
                        now.subtract(Duration(days: now.weekday - 1)).day +
                        index;
                    final isActive = dateNum == now.day;
                    final lastDate = DateTime(now.year, now.month + 1, 0);
                    if (dateNum > lastDate.day) {
                      dateNum = dateNum - lastDate.day;
                    }
                    return Column(
                      children: [
                        Text(
                          days[index],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isActive
                                ? const Color(0xFF22C55E)
                                : context.secondaryTextColor,
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
                                  ? (context.isDark ? const Color(0xFF0F172A) : Colors.white)
                                  : context.textColor,
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
                      color: context.textColor,
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
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: Text(
                    'No habits created yet. Tap + to start!',
                    style: GoogleFonts.plusJakartaSans(
                      color: context.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                AnimationLimiter(
                  child: Column(
                    children: List.generate(state.habits.length, (index) {
                      final habit = state.habits[index];
                      final isDone = habit.isCompletedOn(state.selectedDate);

                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: HabitCard(
                              habit: habit,
                              isDone: isDone,
                              onDone: () async {
                                await vm.toggleHabit(habit.id);
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
      floatingActionButton: OpenContainer(
        transitionType: ContainerTransitionType.fade,
        openBuilder: (context, _) => const AddHabitView(),
        closedElevation: 6.0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        closedColor: const Color(0xFF22C55E),
        openColor: context.bgColor,
        closedBuilder: (context, openContainer) {
          return SizedBox(
            width: 56,
            height: 56,
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          );
        },
      ),
    );
  }
}
