import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/services/dashboard/dashboardService.dart';
import 'package:inhabit_realties/constants/role_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';

class SalesAnalyticsPage extends StatefulWidget {
  const SalesAnalyticsPage({super.key});

  @override
  State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  String? _error;
  String? _userRole;
  String _selectedTimeFrame = '12M'; // Default to 12 months
  final List<String> _timeFrames = ['1M', '3M', '6M', '12M', '1Y', '2Y'];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadPerformanceAnalytics();
  }

  Future<void> _loadUserRole() async {
    await RoleUtils.initializeCurrentUser();
    setState(() {
      _userRole = RoleUtils.getCurrentUserRoleName();
    });
  }

  Future<void> _loadPerformanceAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      Map<String, dynamic> response;

      // Load role-based analytics with time frame
      if (_userRole?.toLowerCase() == 'admin') {
        response = await DashboardService.getAdminPerformanceAnalytics(
            token, _selectedTimeFrame);
      } else if (_userRole?.toLowerCase() == 'sales') {
        response = await DashboardService.getSalesPerformanceAnalytics(
            token, _selectedTimeFrame);
      } else {
        // Fallback to regular sales analytics for other roles
        response =
            await DashboardService.getSalesAnalytics(token, _selectedTimeFrame);
      }

      if (response['statusCode'] == 200) {
        setState(() {
          _analyticsData = response['data'];
          _isLoading = false;
        });
      } else {
        throw Exception(
            response['message'] ?? 'Failed to load performance analytics');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onTimeFrameChanged(String timeFrame) {
    setState(() {
      _selectedTimeFrame = timeFrame;
    });
    _loadPerformanceAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userRole?.toLowerCase() == 'admin'
              ? 'Company Performance'
              : _userRole?.toLowerCase() == 'sales'
                  ? 'My Performance'
                  : 'Sales Analytics',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _loadPerformanceAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildAnalyticsContent(),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 200,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading analytics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPerformanceAnalytics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return RefreshIndicator(
      onRefresh: _loadPerformanceAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeFrameSelector(),
            const SizedBox(height: 20),
            _buildOverviewCards(),
            const SizedBox(height: 24),
            _buildPerformanceChart(),
            const SizedBox(height: 24),
            _buildPerformanceSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFrameSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Frame',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeFrames.map((timeFrame) {
              final isSelected = _selectedTimeFrame == timeFrame;
              return GestureDetector(
                onTap: () => _onTimeFrameChanged(timeFrame),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brandPrimary
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getTimeFrameDisplayName(timeFrame),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getTimeFrameDisplayName(String timeFrame) {
    switch (timeFrame) {
      case '1M':
        return '1 Month';
      case '3M':
        return '3 Months';
      case '6M':
        return '6 Months';
      case '12M':
        return '12 Months';
      case '1Y':
        return '1 Year';
      case '2Y':
        return '2 Years';
      default:
        return timeFrame;
    }
  }

  Widget _buildOverviewCards() {
    final isAdmin = _userRole?.toLowerCase() == 'admin';
    final isSales = _userRole?.toLowerCase() == 'sales';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        if (isAdmin) ...[
          _buildStatCard(
            'Properties Sold',
            _analyticsData['totalPropertiesSold']?.toString() ?? '0',
            CupertinoIcons.home,
            AppColors.brandPrimary,
          ),
          _buildStatCard(
            'Total Revenue',
            _formatCurrency((_analyticsData['totalRevenue'] ?? 0).toDouble()),
            Icons.currency_rupee,
            AppColors.lightSuccess,
          ),
          _buildStatCard(
            'Average Sale Price',
            _formatCurrency(
                (_analyticsData['averageSalePrice'] ?? 0).toDouble()),
            CupertinoIcons.chart_bar,
            AppColors.lightWarning,
          ),
        ] else if (isSales) ...[
          _buildStatCard(
            'Leads Assigned',
            _analyticsData['totalLeadsAssigned']?.toString() ?? '0',
            CupertinoIcons.person_2,
            AppColors.brandPrimary,
          ),
          _buildStatCard(
            'Properties Sold',
            _analyticsData['totalPropertiesSold']?.toString() ?? '0',
            CupertinoIcons.home,
            AppColors.lightSuccess,
          ),
          _buildStatCard(
            'Conversion Rate',
            '${(_analyticsData['conversionRate'] ?? 0).toStringAsFixed(1)}%',
            CupertinoIcons.chart_bar,
            AppColors.lightWarning,
          ),
          _buildStatCard(
            'Total Revenue',
            _formatCurrency((_analyticsData['totalRevenue'] ?? 0).toDouble()),
            Icons.currency_rupee,
            AppColors.brandTurnary,
          ),
        ] else ...[
          // Fallback for other roles
          _buildStatCard(
            'Total Sales',
            _analyticsData['totalSales']?.toString() ?? '0',
            CupertinoIcons.money_dollar,
            AppColors.brandPrimary,
          ),
          _buildStatCard(
            'Properties Sold',
            _analyticsData['totalSales']?.toString() ?? '0',
            CupertinoIcons.home,
            AppColors.lightSuccess,
          ),
          _buildStatCard(
            'Average Sale Price',
            _formatCurrency(
                (_analyticsData['averageSalePrice'] ?? 0).toDouble()),
            CupertinoIcons.chart_bar,
            AppColors.lightWarning,
          ),
          _buildStatCard(
            'Monthly Revenue',
            _formatCurrency(_getCurrentMonthRevenue()),
            CupertinoIcons.calendar,
            AppColors.brandTurnary,
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final monthlyPerformance = _analyticsData['monthlyPerformance'] ?? {};
    if (monthlyPerformance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No data available for the selected time frame',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final sortedMonths = monthlyPerformance.keys.toList()..sort();
    final isAdmin = _userRole?.toLowerCase() == 'admin';
    final isSales = _userRole?.toLowerCase() == 'sales';

    List<double> performanceData = [];
    String chartTitle = '';
    String yAxisLabel = '';

    try {
      if (isAdmin) {
        // Admin: Show properties sold per month
        performanceData = <double>[
          for (String month in sortedMonths)
            (monthlyPerformance[month]['propertiesSold'] ?? 0).toDouble()
        ];
        chartTitle = 'Company Performance - Properties Sold';
        yAxisLabel = 'Properties Sold';
      } else if (isSales) {
        // Sales: Show leads converted per month
        performanceData = <double>[
          for (String month in sortedMonths)
            (monthlyPerformance[month]['leadsConverted'] ?? 0).toDouble()
        ];
        chartTitle = 'My Performance - Leads Converted';
        yAxisLabel = 'Leads Converted';
      } else {
        // Fallback: Show revenue trend
        performanceData = <double>[
          for (String month in sortedMonths)
            (monthlyPerformance[month]['revenue'] ?? 0.0).toDouble()
        ];
        chartTitle = 'Revenue Trend';
        yAxisLabel = 'Revenue';
      }
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Error loading chart data: $e',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red[600],
                    ),
              ),
            ),
          ],
        ),
      );
    }

    if (performanceData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chartTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No data available for the selected time frame',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chartTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < sortedMonths.length) {
                          final month = sortedMonths[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _formatMonth(month),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        if (isAdmin || isSales) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        } else {
                          return Text(
                            _formatCurrency(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: performanceData
                        .asMap()
                        .entries
                        .map((entry) =>
                            FlSpot(entry.key.toDouble(), entry.value))
                        .toList()
                        .cast<FlSpot>(),
                    isCurved: true,
                    color: AppColors.brandPrimary,
                    barWidth: 3,
                    dotData: FlDotData(show: false), // No dots as requested
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final monthIndex = barSpot.x.toInt();
                        if (monthIndex < sortedMonths.length) {
                          final month = sortedMonths[monthIndex];
                          final value = barSpot.y;

                          String tooltipText = '';
                          if (isAdmin) {
                            tooltipText = '${value.toInt()} properties sold';
                          } else if (isSales) {
                            tooltipText = '${value.toInt()} leads converted';
                          } else {
                            tooltipText = _formatCurrency(value);
                          }

                          return LineTooltipItem(
                            '${_formatMonth(month)}\n$tooltipText',
                            const TextStyle(color: Colors.white),
                          );
                        }
                        return LineTooltipItem(
                          'No data',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    final isAdmin = _userRole?.toLowerCase() == 'admin';
    final isSales = _userRole?.toLowerCase() == 'sales';

    if (isAdmin) {
      final totalPropertiesSold =
          (_analyticsData['totalPropertiesSold'] ?? 0) as num;
      final totalRevenue = (_analyticsData['totalRevenue'] ?? 0.0) as num;
      final averageSalePrice =
          (_analyticsData['averageSalePrice'] ?? 0.0) as num;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company Performance Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          totalPropertiesSold.toInt().toString(),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandPrimary,
                              ),
                        ),
                      ),
                      Text(
                        'Properties Sold',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatCurrency(totalRevenue.toDouble()),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightSuccess,
                              ),
                        ),
                      ),
                      Text(
                        'Total Revenue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          averageSalePrice == 0.0
                              ? '-'
                              : _formatCurrency(averageSalePrice.toDouble()),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightWarning,
                              ),
                        ),
                      ),
                      Text(
                        'Average Sale',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (isSales) {
      final totalLeadsAssigned =
          (_analyticsData['totalLeadsAssigned'] ?? 0) as num;
      final totalPropertiesSold =
          (_analyticsData['totalPropertiesSold'] ?? 0) as num;
      final conversionRate = (_analyticsData['conversionRate'] ?? 0.0) as num;
      final totalRevenue = (_analyticsData['totalRevenue'] ?? 0.0) as num;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Performance Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          totalLeadsAssigned.toInt().toString(),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandPrimary,
                              ),
                        ),
                      ),
                      Text(
                        'Leads Assigned',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          totalPropertiesSold.toInt().toString(),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightSuccess,
                              ),
                        ),
                      ),
                      Text(
                        'Properties Sold',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${conversionRate.toStringAsFixed(1)}%',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightWarning,
                              ),
                        ),
                      ),
                      Text(
                        'Conversion Rate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatCurrency(totalRevenue.toDouble()),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandTurnary,
                              ),
                        ),
                      ),
                      Text(
                        'Total Revenue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Fallback for other roles
      final totalRevenue = (_analyticsData['totalRevenue'] ?? 0.0) as num;
      final averageSalePrice =
          (_analyticsData['averageSalePrice'] ?? 0.0) as num;
      final totalSales = (_analyticsData['totalSales'] ?? 0) as num;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatCurrency(totalRevenue.toDouble()),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandPrimary,
                              ),
                        ),
                      ),
                      Text(
                        'Total Revenue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          totalSales.toInt().toString(),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightSuccess,
                              ),
                        ),
                      ),
                      Text(
                        'Properties Sold',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          averageSalePrice == 0.0
                              ? '-'
                              : _formatCurrency(averageSalePrice.toDouble()),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightWarning,
                              ),
                        ),
                      ),
                      Text(
                        'Average Sale',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  double _getCurrentMonthRevenue() {
    final monthlyPerformance = _analyticsData['monthlyPerformance'] ?? {};
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final revenue = monthlyPerformance[currentMonth]?['revenue'];
    if (revenue is int) {
      return revenue.toDouble();
    } else if (revenue is double) {
      return revenue;
    }
    return 0.0;
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  String _formatMonth(String monthKey) {
    try {
      final date = DateTime.parse('$monthKey-01');
      return '${date.month}/${date.year.toString().substring(2)}';
    } catch (e) {
      return monthKey;
    }
  }
}
