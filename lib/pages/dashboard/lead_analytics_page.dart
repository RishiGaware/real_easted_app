import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/services/dashboard/dashboardService.dart';
import 'package:inhabit_realties/services/lead/leadsService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:inhabit_realties/models/lead/LeadsModel.dart';
import 'package:inhabit_realties/pages/leads/leads_page.dart'
    show
        _buildLeadCard,
        _buildProfileAvatar,
        _buildStatusChip,
        _buildInfoRow,
        StatusUtils;
import 'package:inhabit_realties/constants/status_utils.dart';
import 'package:inhabit_realties/pages/leads/lead_details_page.dart';
import 'package:inhabit_realties/pages/widgets/horizontal_filter_bar.dart';

class LeadAnalyticsPage extends StatefulWidget {
  const LeadAnalyticsPage({super.key});

  @override
  State<LeadAnalyticsPage> createState() => _LeadAnalyticsPageState();
}

class _LeadAnalyticsPageState extends State<LeadAnalyticsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  String? _error;
  List<dynamic> _recentLeads = [];
  String _selectedTimeFrame = '12M'; // Default to 12 months
  final List<String> _timeFrames = ['1M', '3M', '6M', '12M', '1Y', '2Y'];

  final LeadsService _leadsService = LeadsService();

  @override
  void initState() {
    super.initState();
    _loadLeadAnalytics();
  }

  Future<void> _loadLeadAnalytics() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response =
          await DashboardService.getLeadAnalytics(token, _selectedTimeFrame);

      if (!mounted) return;
      if (response['statusCode'] == 200) {
        setState(() {
          _analyticsData = response['data'] is Map ? Map<String, dynamic>.from(response['data'] as Map) : {};
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load lead analytics');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onTimeFrameChanged(String timeFrame) {
    if (!mounted) return;
    setState(() {
      _selectedTimeFrame = timeFrame;
    });
    _loadLeadAnalytics();
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
          'Lead Analytics',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _loadLeadAnalytics,
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
      itemCount: 6,
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
            onPressed: _loadLeadAnalytics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return RefreshIndicator(
      onRefresh: _loadLeadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeFrameSelector(),
            const SizedBox(height: 20),
            _buildOverviewCards(),
            const SizedBox(height: 24),
            _buildConversionRateCard(),
            const SizedBox(height: 24),
            _buildStatusDistributionChart(),
            const SizedBox(height: 32), // Increased spacing
            _buildDesignationDistributionChart(),
            const SizedBox(height: 32), // Increased spacing
            _buildFollowUpDistributionChart(),
            const SizedBox(height: 24),
            _buildRecentLeadsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFrameSelector() {
    final displayTimeFrames =
        _timeFrames.map((tf) => _getTimeFrameDisplayName(tf)).toList();
    final selectedIndex = _timeFrames.indexOf(_selectedTimeFrame);

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
          HorizontalFilterBar(
            filters: displayTimeFrames,
            selectedIndex: selectedIndex,
            onFilterChanged: (index) {
              _onTimeFrameChanged(_timeFrames[index]);
            },
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Total Leads',
          (_analyticsData['totalLeads'] ?? 0).toString(),
          CupertinoIcons.person_2,
          AppColors.brandPrimary,
        ),
        _buildStatCard(
          'Recent Leads',
          (_analyticsData['recentLeads'] ?? 0).toString(),
          CupertinoIcons.clock,
          AppColors.lightSuccess,
        ),
        _buildStatCard(
          'Converted Leads',
          (_analyticsData['convertedLeads'] ?? 0).toString(),
          CupertinoIcons.checkmark_circle,
          AppColors.lightWarning,
        ),
        _buildStatCard(
          'Conversion Rate',
          '${double.tryParse((_analyticsData['conversionRate'] ?? 0).toString())?.toStringAsFixed(1) ?? "0.0"}%',
          CupertinoIcons.chart_bar,
          AppColors.brandTurnary,
        ),
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
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
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

  Widget _buildConversionRateCard() {
    final conversionRate = double.tryParse((_analyticsData['conversionRate'] ?? 0).toString()) ?? 0.0;
    final totalLeads = int.tryParse((_analyticsData['totalLeads'] ?? 0).toString()) ?? 0;
    final convertedLeads = int.tryParse((_analyticsData['convertedLeads'] ?? 0).toString()) ?? 0;

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
            'Lead Conversion Rate',
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
                    Text(
                      '${conversionRate.toStringAsFixed(1)}%',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandPrimary,
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
                    Text(
                      convertedLeads.toString(),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightSuccess,
                              ),
                    ),
                    Text(
                      'Converted',
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
                    Text(
                      totalLeads.toString(),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightWarning,
                              ),
                    ),
                    Text(
                      'Total Leads',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: conversionRate / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistributionChart() {
    final statusData = _getStatusDistribution();
    if (statusData.isEmpty) return const SizedBox.shrink();
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
            'Lead Status Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280, // Increased height to accommodate labels
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: statusData.length > 5 ? statusData.length * 80.0 : MediaQuery.of(context).size.width - 80,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: statusData.values.isNotEmpty
                        ? statusData.values
                            .reduce((a, b) => a > b ? a : b)
                            .toDouble()
                        : 1.0,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 80, // Increased reserved space for labels
                          getTitlesWidget: (value, meta) {
                            final labels = statusData.keys.toList();
                            if (value.toInt() < labels.length) {
                              final label = labels[value.toInt()];
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Transform.rotate(
                                  angle: -0.5, // Slight rotation to prevent overlap
                                  child: SizedBox(
                                    width: 80, // Fixed width for consistent spacing
                                    child: Text(
                                      _getChartLabel(label),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
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
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: statusData.entries
                        .map((entry) {
                          final index = statusData.keys.toList().indexOf(entry.key);
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.toDouble(),
                                color: _getStatusColor(entry.key),
                                width: 16, // Reduced bar width for better spacing
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        })
                        .toList()
                        .cast<BarChartGroupData>(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignationDistributionChart() {
    final designationData = _getDesignationDistribution();
    if (designationData.isEmpty) return const SizedBox.shrink();
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
            'Lead Designation Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: designationData.entries
                        .map((entry) {
                          final total = designationData.values
                              .fold(0, (sum, value) => sum + value);
                          final percentage =
                              total > 0 ? (entry.value / total) * 100 : 0;
                          return PieChartSectionData(
                            value: entry.value.toDouble(),
                            title: '${percentage.toStringAsFixed(1)}%',
                            radius: 60,
                            color: _getDesignationColor(entry.key),
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        })
                        .toList()
                        .cast<PieChartSectionData>(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Legend
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: designationData.keys.map((designation) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getDesignationColor(designation),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        designation,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesignationItem(String designation, int count) {
    final total = _analyticsData['designationDistribution']
            ?.values
            .fold(0, (sum, value) => sum + value) ??
        0;
    final percentage = total > 0 ? (count / total) * 100 : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              designation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightSuccess),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$count (${percentage.toStringAsFixed(1)}%)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpDistributionChart() {
    final followUpData = _getFollowUpStatusDistribution();
    if (followUpData.isEmpty) return const SizedBox.shrink();
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
            'Follow-up Status Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280, // Increased height to accommodate labels
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: followUpData.length > 5 ? followUpData.length * 80.0 : MediaQuery.of(context).size.width - 80,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: followUpData.values.isNotEmpty
                        ? followUpData.values
                            .reduce((a, b) => a > b ? a : b)
                            .toDouble()
                        : 1.0,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 80, // Increased reserved space for labels
                          getTitlesWidget: (value, meta) {
                            final labels = followUpData.keys.toList();
                            if (value.toInt() < labels.length) {
                              final label = labels[value.toInt()];
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Transform.rotate(
                                  angle: -0.5, // Slight rotation to prevent overlap
                                  child: SizedBox(
                                    width: 80, // Fixed width for consistent spacing
                                    child: Text(
                                      _getChartLabel(label),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
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
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: followUpData.entries
                        .map((entry) {
                          final index =
                              followUpData.keys.toList().indexOf(entry.key);
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.toDouble(),
                                color: _getFollowUpStatusColor(entry.key),
                                width: 16, // Reduced bar width for better spacing
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        })
                        .toList()
                        .cast<BarChartGroupData>(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLeadsList() {
    final recentLeadsList = _analyticsData['recentLeadsList'] is List 
        ? _analyticsData['recentLeadsList'] as List 
        : [];
    
    // Fall back to empty list if not valid

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recent Leads',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Text(
                '${recentLeadsList.length} leads',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentLeadsList.isEmpty)
            Text(
              'No recent leads found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            )
          else
            Column(
              children: List.generate(
                recentLeadsList.length,
                (index) {
                  final leadData = recentLeadsList[index];
                  if (leadData is! Map) return const SizedBox.shrink();
                  
                  final leadJson = Map<String, dynamic>.from(leadData);
                  final leadModel = LeadsModel.fromJson(leadJson);
                  return _buildLeadCard(leadModel, index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeadCard(LeadsModel lead, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;
    final secondaryTextColor =
        isDark ? AppColors.greyColor : AppColors.greyColor2;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeadDetailsPage(lead: lead),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardBackground
                  : AppColors.lightCardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildProfileAvatar(lead, index),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lead.fullName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                            ),
                          ),
                          _buildStatusChip(lead.leadStatus),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.email_outlined, lead.leadEmail,
                          secondaryTextColor),
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.phone_outlined, lead.leadPhoneNumber,
                          secondaryTextColor),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getFollowUpStatusColor(lead.followUpStatus)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getFollowUpStatusColor(lead.followUpStatus)
                                .withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getFollowUpStatusDisplayName(lead.followUpStatus),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _getFollowUpStatusColor(
                                        lead.followUpStatus),
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(LeadsModel lead, int index) {
    final avatarColors = [
      AppColors.lightPrimary,
      AppColors.brandPrimary,
      AppColors.lightSuccess,
      AppColors.lightWarning,
      AppColors.lightDanger,
    ];
    final colorIndex = index % avatarColors.length;
    final avatarColor = avatarColors[colorIndex];
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: avatarColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: avatarColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          lead.fullName.isNotEmpty ? lead.fullName[0].toUpperCase() : 'L',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: avatarColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusDisplayName(status),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.darkWhiteText,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    return StatusUtils.getLeadStatusColor(status);
  }

  Color _getFollowUpStatusColor(String status) {
    return StatusUtils.getFollowUpStatusColor(status);
  }

  String _getFollowUpStatusDisplayName(String status) {
    return StatusUtils.getFollowUpStatusDisplayName(status);
  }

  String _getStatusDisplayName(String status) {
    return StatusUtils.getLeadStatusDisplayName(status);
  }

  Color _getDesignationColor(String designation) {
    switch (designation.toUpperCase()) {
      case 'BUYER':
        return AppColors.lightSuccess;
      case 'SELLER':
        return AppColors.lightWarning;
      case 'INVESTOR':
        return AppColors.lightPrimary;
      case 'TENANT':
        return AppColors.brandTurnary;
      case 'LANDLORD':
        return AppColors.brandSecondary;
      case 'DEVELOPER':
        return Colors.teal;
      case 'AGENT':
        return Colors.orange;
      case 'BROKER':
        return Colors.cyan;
      case 'CONSULTANT':
        return Colors.indigo;
      default:
        // Generate a deterministic color based on the string name if not caught above
        final int hash = designation.hashCode;
        final List<Color> palette = [
          AppColors.brandPrimary,
          AppColors.brandSecondary,
          AppColors.brandTurnary,
          AppColors.lightPrimary,
          AppColors.lightSuccess,
          AppColors.lightWarning,
          Colors.amber,
          Colors.deepOrange,
          Colors.pink,
          Colors.purple,
          Colors.indigo,
          Colors.blue,
          Colors.cyan,
          Colors.teal,
          Colors.green,
          Colors.lightGreen,
          Colors.lime,
        ];
        return palette[hash.abs() % palette.length];
    }
  }

  // --- Use distributions from dashboard analytics ---
  Map<String, int> _getStatusDistribution() {
    if (_analyticsData.containsKey('statusDistribution') && _analyticsData['statusDistribution'] is Map) {
      final dist = _analyticsData['statusDistribution'] as Map;
      return Map<String, int>.fromEntries(
        dist.entries
            .where((e) => (e.value as num).toInt() > 0)
            .map((e) => MapEntry(e.key.toString(), (e.value as num).toInt())),
      );
    }
    return {};
  }

  Map<String, int> _getDesignationDistribution() {
    if (_analyticsData.containsKey('designationDistribution') && _analyticsData['designationDistribution'] is Map) {
      final dist = _analyticsData['designationDistribution'] as Map;
      return Map<String, int>.fromEntries(
        dist.entries
            .where((e) => (e.value as num).toInt() > 0)
            .map((e) => MapEntry(e.key.toString(), (e.value as num).toInt())),
      );
    }
    return {};
  }

  Map<String, int> _getFollowUpStatusDistribution() {
    if (_analyticsData.containsKey('followUpDistribution') && _analyticsData['followUpDistribution'] is Map) {
      final dist = _analyticsData['followUpDistribution'] as Map;
      return Map<String, int>.fromEntries(
        dist.entries
            .where((e) => (e.value as num).toInt() > 0)
            .map((e) => MapEntry(e.key.toString(), (e.value as num).toInt())),
      );
    }
    return {};
  }

  /// Truncates long labels to prevent overlap in charts
  String _truncateLabel(String label, {int maxLength = 15}) {
    if (label.length <= maxLength) return label;
    return '${label.substring(0, maxLength)}...';
  }

  /// Creates shorter, more readable labels for chart display
  String _getChartLabel(String label) {
    // Handle common long status names
    final shortLabels = {
      'NEW LEAD': 'NEW',
      'ACTIVE URGENT WARNING': 'URGENT',
      'HIGH BUDGET': 'HIGH BUDGET',
      'UNKNOWN BUDGET': 'UNKNOWN',
      'COMPLETED': 'COMPLETED',
      'FOLLOW UP REQUIRED': 'FOLLOW UP',
      'NO ACTION REQUIRED': 'NO ACTION',
      'CALL BACK REQUIRED': 'CALL BACK',
    };

    final upperLabel = label.toUpperCase();
    return shortLabels[upperLabel] ?? _truncateLabel(label, maxLength: 12);
  }
}
