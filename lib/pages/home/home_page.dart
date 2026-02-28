// ignore_for_file: unused_local_variable

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/pages/home/widgets/appAppbar.dart';
import 'package:inhabit_realties/pages/widgets/appDrawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:inhabit_realties/controllers/dashboard/dashboardController.dart';
import 'package:inhabit_realties/pages/dashboard/property_analytics_page.dart';
import 'package:inhabit_realties/pages/dashboard/lead_analytics_page.dart';
import 'package:inhabit_realties/pages/dashboard/sales_analytics_page.dart';
import 'package:inhabit_realties/pages/dashboard/user_analytics_page.dart';
import 'package:inhabit_realties/services/dashboard/dashboardService.dart';
import 'package:inhabit_realties/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inhabit_realties/controllers/notification/notificationController.dart';
import 'package:inhabit_realties/controllers/lead/leadsController.dart';
import 'package:inhabit_realties/services/meeting_schedule_service.dart';
import 'package:inhabit_realties/pages/meetingSchedule/meeting_details_page.dart';
import 'package:inhabit_realties/models/meeting_schedule_model.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final Function(int)? onSwitchTab;

  const HomePage({super.key, required this.onToggleTheme, this.onSwitchTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late DashboardController _dashboardController;

  @override
  void initState() {
    super.initState();
    _dashboardController = DashboardController();
    _setupAnimations();
    _loadDashboard();

    // Debug SharedPreferences
    _dashboardController.debugTokenAndPreferences();

    // Lead Analytics API debug print
    _debugLeadAnalyticsApi();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh dashboard when dependencies change (like when returning to this page)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshDashboard();
      }
    });
  }

  // Method to refresh dashboard data
  Future<void> _refreshDashboard() async {
    await _dashboardController.refresh();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _loadDashboard() async {
    await _dashboardController.loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
    Color color,
    bool isLoading, {
    String? subtitle,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon and title row
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Value
                          Container(
                            height: 32,
                            width: 70,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          // Subtitle
                          Container(
                            height: 16,
                            width: 90,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon and title row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkWhiteText
                                          : AppColors.lightDarkText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Value
                        Text(
                          value,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkWhiteText.withOpacity(0.7)
                                      : AppColors.lightDarkText
                                          .withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChart(bool isLoading) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Performance',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: _dashboardController.weekDays.length - 1,
                              minY: 0,
                              maxY: _dashboardController.weeklyData.isNotEmpty
                                  ? _dashboardController.weeklyData
                                          .reduce((a, b) => a > b ? a : b) +
                                      2
                                  : 10,
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      if (value >= 0 &&
                                          value <
                                              _dashboardController
                                                  .weekDays.length) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            _dashboardController
                                                .weekDays[value.toInt()],
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipBgColor:
                                      AppColors.brandPrimary.withOpacity(0.15),
                                  tooltipRoundedRadius: 12,
                                  tooltipPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  tooltipMargin: 0,
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  getTooltipItems:
                                      (List<LineBarSpot> touchedSpots) {
                                    return touchedSpots
                                        .map((LineBarSpot touchedSpot) {
                                      final weekDay = _dashboardController
                                          .weekDays[touchedSpot.x.toInt()];
                                      return LineTooltipItem(
                                        '$weekDay: ${touchedSpot.y.toStringAsFixed(1)}',
                                        const TextStyle(
                                          color: AppColors.brandPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '\nValue',
                                            style: TextStyle(
                                              color: AppColors.brandPrimary
                                                  .withOpacity(0.7),
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList();
                                  },
                                ),
                                handleBuiltInTouches: true,
                                getTouchedSpotIndicator:
                                    (LineChartBarData barData,
                                        List<int> spotIndexes) {
                                  return spotIndexes.map((index) {
                                    return TouchedSpotIndicatorData(
                                      FlLine(
                                        color: AppColors.brandPrimary
                                            .withOpacity(0.15),
                                        strokeWidth: 2,
                                        dashArray: [5, 5],
                                      ),
                                      FlDotData(
                                        getDotPainter:
                                            (spot, percent, barData, index) =>
                                                FlDotCirclePainter(
                                          radius: 6,
                                          color: AppColors.brandPrimary,
                                          strokeWidth: 2,
                                          strokeColor: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList();
                                },
                                touchCallback: (FlTouchEvent event,
                                    LineTouchResponse? touchResponse) {
                                  // Optional callback for touch events
                                },
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    _dashboardController.weeklyData.length,
                                    (index) => FlSpot(
                                      index.toDouble(),
                                      _dashboardController.weeklyData[index],
                                    ),
                                  ),
                                  isCurved: true,
                                  color: AppColors.brandPrimary,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 4,
                                        color: AppColors.brandPrimary,
                                        strokeWidth: 2,
                                        strokeColor: Colors.white,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.brandPrimary.withOpacity(0.3),
                                        AppColors.brandPrimary.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(bool isLoading) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  ..._dashboardController.recentActivities
                      .map(
                        (activity) => _buildActivityItem(
                          isLoading,
                          icon: activity['icon'] as IconData,
                          title: activity['title'] as String,
                          subtitle: _dashboardController
                              .getTimeAgo(activity['time'] as DateTime),
                          color: activity['color'] as Color,
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(
    bool isLoading, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return isLoading
        ? Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              height: 70,
            ),
          )
        : Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Future<void> _debugLeadAnalyticsApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await DashboardService.getLeadAnalytics(token);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.currentTheme == 'dark';

        // Use AppColors based on theme
        final backgroundColor =
            isDark ? AppColors.darkBackground : AppColors.lightBackground;
        final cardColor = isDark
            ? AppColors.darkCardBackground
            : AppColors.lightCardBackground;
        final primaryColor =
            isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
        final textColor =
            isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppAppbar(onToggleTheme: widget.onToggleTheme),
          body: RefreshIndicator(
            onRefresh: _loadDashboard,
            child: AnimatedBuilder(
              animation: _dashboardController,
              builder: (context, child) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard Overview',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome back! Here\'s what\'s happening with your real estate business.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                        ),
                        const SizedBox(height: 24),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.75,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PropertyAnalyticsPage(),
                                  ),
                                );
                              },
                              child: _buildStatCard(
                                CupertinoIcons.home,
                                'Properties',
                                _dashboardController.totalProperties.toString(),
                                AppColors.brandPrimary,
                                _dashboardController.isLoading,
                                subtitle:
                                    '${_dashboardController.soldProperties} sold, ${_dashboardController.unsoldProperties} available',
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LeadAnalyticsPage(),
                                  ),
                                );
                              },
                              child: _buildStatCard(
                                CupertinoIcons.person_2,
                                'Leads',
                                _dashboardController.totalLeads.toString(),
                                isDark
                                    ? AppColors.darkSuccess
                                    : AppColors.lightSuccess,
                                _dashboardController.isLoading,
                                subtitle:
                                    '${_dashboardController.activeLeads} active',
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SalesAnalyticsPage(),
                                  ),
                                );
                              },
                              child: _buildStatCard(
                                CupertinoIcons.chart_bar,
                                'Sales',
                                _dashboardController.formatCurrencySync(
                                    _dashboardController.totalSales),
                                isDark
                                    ? AppColors.darkWarning
                                    : AppColors.lightWarning,
                                _dashboardController.isLoading,
                                subtitle: 'Total revenue',
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UserAnalyticsPage(),
                                  ),
                                );
                              },
                              child: _buildStatCard(
                                CupertinoIcons.star,
                                'Rating',
                                _dashboardController.averageRating
                                    .toStringAsFixed(1),
                                AppColors.brandTurnary,
                                _dashboardController.isLoading,
                                subtitle: 'Average rating',
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LeadAnalyticsPage(),
                                  ),
                                );
                              },
                              child: _buildStatCard(
                                CupertinoIcons.arrow_2_circlepath,
                                'Followups',
                                _dashboardController.pendingFollowups
                                    .toString(),
                                isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary,
                                _dashboardController.isLoading,
                                subtitle: 'Pending tasks',
                              ),
                            ),
                            // Today's Notifications
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/notifications');
                              },
                              child: Consumer<NotificationController>(
                                builder:
                                    (context, notificationController, child) {
                                  return _buildStatCard(
                                    CupertinoIcons.bell,
                                    'Today\'s Notifications',
                                    notificationController.todayNotificationsCount
                                        .toString(),
                                    AppColors.brandPrimary,
                                    false,
                                    subtitle: 'New notifications',
                                  );
                                },
                              ),
                            ),
                            // Today's Inquiries
                            GestureDetector(
                              onTap: () {
                                widget.onSwitchTab?.call(2); // 2 is the index for Leads tab
                              },
                              child: Consumer<LeadsController>(
                                builder: (context, leadsController, child) {
                                  return _buildStatCard(
                                    CupertinoIcons.question_circle,
                                    'Today\'s Inquiries',
                                    leadsController.todayInquiriesCount
                                        .toString(),
                                    AppColors.lightSuccess,
                                    false,
                                    subtitle: 'New leads',
                                  );
                                },
                              ),
                            ),
                            // Today's & Tomorrow's Schedules
                            GestureDetector(
                              onTap: () {
                                widget.onSwitchTab?.call(3); // 3 is the index for Meetings tab
                              },
                              child: _buildStatCard(
                                CupertinoIcons.calendar,
                                'Today\'s Schedules',
                                _dashboardController.todaySchedulesCount
                                    .toString(),
                                AppColors.lightWarning,
                                _dashboardController.isLoading,
                                subtitle: 'Meetings scheduled',
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                widget.onSwitchTab?.call(3); // 3 is the index for Meetings tab
                              },
                              child: _buildStatCard(
                                CupertinoIcons.calendar_today,
                                'Tomorrow\'s Schedules',
                                _dashboardController.tomorrowSchedulesCount
                                    .toString(),
                                AppColors.lightPrimary,
                                _dashboardController.isLoading,
                                subtitle: 'Upcoming meetings',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SalesAnalyticsPage(),
                              ),
                            );
                          },
                          child: _buildChart(_dashboardController.isLoading),
                        ),
                        const SizedBox(height: 30),
                        _buildTodaySchedules(_dashboardController.isLoading),
                        const SizedBox(height: 30),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          drawer: const AppDrawer(),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () async {
                  Navigator.pushNamed(context, '/create_meeting');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Add Meeting',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaySchedules(bool isLoading) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Schedules',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Icon(
                        CupertinoIcons.calendar,
                        color: AppColors.brandPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isLoading)
                    ...List.generate(3, (index) => _buildScheduleItemShimmer())
                  else if (_dashboardController.todaySchedules.isEmpty)
                    _buildNoSchedulesMessage()
                  else
                    ..._dashboardController.todaySchedules
                        .map((schedule) => _buildScheduleItem(schedule))
                        .toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleItemShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        height: 80,
      ),
    );
  }

  Widget _buildNoSchedulesMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Icon(
              CupertinoIcons.calendar_badge_plus,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No meetings scheduled for today',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> schedule) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkCardBackground : Colors.white;

    // Extract schedule data
    final title = schedule['title'] ?? 'Meeting';
    final startTime = schedule['startTime'] ?? '';
    final customerName = schedule['customerId'] is Map
        ? '${schedule['customerId']['firstName'] ?? ''} ${schedule['customerId']['lastName'] ?? ''}'
            .trim()
        : 'Customer';
    final propertyName = schedule['propertyId'] is Map
        ? schedule['propertyId']['name'] ?? 'Property'
        : 'Property';
    final status = schedule['status'] is Map
        ? schedule['status']['name'] ?? 'Scheduled'
        : 'Scheduled';

    return GestureDetector(
        onTap: () {
          try {
            final meetingSchedule = MeetingSchedule.fromJson(schedule);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MeetingDetailsPage(
                  meeting: meetingSchedule,
                ),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unable to open meeting details'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.brandPrimary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      startTime,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customerName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                  ),
                ],
              ),
              if (propertyName != 'Property') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.home,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        propertyName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.circle_fill,
                    size: 8,
                    color: _getStatusColor(status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return AppColors.lightSuccess;
      case 'completed':
        return AppColors.lightPrimary;
      case 'cancelled':
      case 'canceled':
        return AppColors.lightDanger;
      case 'rescheduled':
        return AppColors.lightWarning;
      default:
        return AppColors.brandPrimary;
    }
  }
}
