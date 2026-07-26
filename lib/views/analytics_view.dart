import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:habit_flow/widgets/buildCards.dart';
import 'package:intl/intl.dart';
import '../viewmodels/habit_viewmodel.dart';
import '../models/habit_model.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitViewModelProvider);

    // Calculate dates of the last 7 days
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });

    final totalHabits = state.habits.length;

    // Calculate completion rate for each day
    final weeklyCompletionRates = last7Days.map((date) {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      if (totalHabits == 0) return 0.0;
      final completedCount = state.habits.where((h) => h.completedDates.contains(dateStr)).length;
      return (completedCount / totalHabits) * 100.0;
    }).toList();

    // Calculate total completions this week
    int totalCompletionsThisWeek = 0;
    for (var date in last7Days) {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      totalCompletionsThisWeek += state.habits.where((h) => h.completedDates.contains(dateStr)).length;
    }

    // Category progress calculations
    final categories = <String, List<HabitModel>>{};
    for (var habit in state.habits) {
      categories.putIfAbsent(habit.category, () => []).add(habit);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Analytics',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE4E1ED),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Weekly Performance & Insights',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFFC7C4D7),
                ),
              ),
              const SizedBox(height: 24),

              // Stats row
              IntrinsicHeight(
                child: IntrinsicWidth(
                  child: Row(
                    
                    children: [
                      Expanded(
                        child: BuildCards(
                          title: 'Today\'s Rate',
                          value: '${state.completionPercentage}%',
                          icon: Icons.done_all_rounded,
                          iconColor: const Color(0xFF22C55E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BuildCards(
                          title: 'Streak',
                          value: '${state.userProfile?.overallStreak ?? 12}d',
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFF97316),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BuildCards(
                          title: 'This Week',
                          value: '$totalCompletionsThisWeek',
                          icon: Icons.calendar_month_rounded,
                          iconColor: const Color(0xFF8083FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Chart Header
              Text(
                'Weekly Activity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE4E1ED),
                ),
              ),
              const SizedBox(height: 12),

              // Bar Chart Card
              Container(
                height: 240,
                padding: const EdgeInsets.fromLTRB(12, 24, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: const Color(0xFF0F172A),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.round()}%',
                            GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < 7) {
                              final date = last7Days[idx];
                              final label = DateFormat('E').format(date).substring(0, 1);
                              final isToday = date.day == now.day && date.month == now.month;

                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8,
                                child: Text(
                                  label,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isToday
                                        ? const Color(0xFF8083FF)
                                        : const Color(0xFFC7C4D7),
                                    fontSize: 12,
                                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 25,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(
                                '${value.toInt()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFFC7C4D7).withOpacity(0.7),
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withOpacity(0.04),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(7, (index) {
                      final rate = weeklyCompletionRates[index];
                      final isToday = last7Days[index].day == now.day;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: rate,
                            gradient: LinearGradient(
                              colors: isToday
                                  ? [const Color(0xFF8083FF), const Color(0xFF5A5CFF)]
                                  : [const Color(0xFF8083FF).withOpacity(0.6), const Color(0xFF5A5CFF).withOpacity(0.6)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 14,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 100,
                              color: const Color(0xFF34343D).withOpacity(0.3),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Categories Header
              Text(
                'Category Progress',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE4E1ED),
                ),
              ),
              const SizedBox(height: 12),

              // Categories List
              if (categories.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'No habits created yet.',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFC7C4D7),
                      fontSize: 14,
                    ),
                  ),
                )
              else
                ...categories.entries.map((entry) {
                  final cat = entry.key;
                  final habits = entry.value;
                  final totalInCat = habits.length;

                  // Find how many completed on selectedDate
                  final completedInCat = habits.where((h) => h.completedDates.contains(state.selectedDate)).length;
                  final ratio = totalInCat > 0 ? (completedInCat / totalInCat) : 0.0;

                  // Styling helper based on category name
                  IconData iconData;
                  Color catColor;

                  switch (cat.toLowerCase()) {
                    case 'hydration':
                      iconData = Icons.water_drop_rounded;
                      catColor = const Color(0xFF60A5FA);
                      break;
                    case 'reading':
                      iconData = Icons.menu_book_rounded;
                      catColor = const Color(0xFFF59E0B);
                      break;
                    case 'fitness':
                      iconData = Icons.fitness_center_rounded;
                      catColor = const Color(0xFFEF4444);
                      break;
                    case 'mindfulness':
                      iconData = Icons.self_improvement_rounded;
                      catColor = const Color(0xFF10B981);
                      break;
                    default:
                      iconData = Icons.star_rounded;
                      catColor = const Color(0xFFC0C1FF);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(iconData, color: catColor, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat[0].toUpperCase() + cat.substring(1),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE4E1ED),
                                    ),
                                  ),
                                  Text(
                                    '$totalInCat active ${totalInCat == 1 ? "habit" : "habits"}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFFC7C4D7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$completedInCat/$totalInCat Done',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: catColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: const Color(0xFF34343D),
                            valueColor: AlwaysStoppedAnimation<Color>(catColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  
}
