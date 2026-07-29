import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../theme/theme_ext.dart';
import 'today_view.dart';
import 'analytics_view.dart';
import 'settings_view.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: IndexedStack(
        index: currentIndex,
        children: const [
          TodayView(),
          AnalyticsView(),
          SettingsView(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(currentTabProvider.notifier).state = index;
        },
      ),
    );
  }
}
