import 'package:flutter/material.dart';
import '../../../widgets/textured_background.dart';
import '../../../widgets/metal_tab_switcher.dart';
import '../../../design/ninja_spacing.dart';
import 'achievements/achievements_screen.dart';
import 'statistics/statistics_screen.dart';

class AchievementsAndStatisticsScreen extends StatefulWidget {
  const AchievementsAndStatisticsScreen({super.key});

  @override
  State<AchievementsAndStatisticsScreen> createState() =>
      _AchievementsAndStatisticsScreenState();
}

class _AchievementsAndStatisticsScreenState
    extends State<AchievementsAndStatisticsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(NinjaSpacing.lg),
                child: MetalTabSwitcher(
                  tabs: const ['Статистика', 'Достижения'],
                  initialIndex: _selectedTabIndex,
                  onTabChanged: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: const [
                    StatisticsScreen(),
                    AchievementsScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
