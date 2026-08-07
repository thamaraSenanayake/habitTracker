import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
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
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (
          Widget child,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: _getView(currentIndex),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(currentTabProvider.notifier).state = index;
        },
      ),
    );
  }

  Widget _getView(int index) {
    switch (index) {
      case 0:
        return const TodayView();
      case 1:
        return const AnalyticsView();
      case 2:
        return const SettingsView();
      default:
        return const TodayView();
    }
  }
}
