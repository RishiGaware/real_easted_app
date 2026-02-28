import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/services/dashboard/dashboardService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PropertyAnalyticsPage extends StatefulWidget {
  const PropertyAnalyticsPage({super.key});

  @override
  State<PropertyAnalyticsPage> createState() => _PropertyAnalyticsPageState();
}

class _PropertyAnalyticsPageState extends State<PropertyAnalyticsPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  String? _error;
  String _selectedTimeFrame = '12M'; // Default to 12 months
  final List<String> _timeFrames = ['1M', '3M', '6M', '12M', '1Y', '2Y'];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _loadPropertyAnalytics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPropertyAnalytics() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';



      if (token.isEmpty) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final response = await DashboardService.getPropertyAnalytics(
          token, _selectedTimeFrame);

      if (!mounted) return;
      if (response['statusCode'] == 200) {
        setState(() {
          _analyticsData = response['data'];
          _isLoading = false;
        });
        _animationController.forward();
      } else {

        throw Exception(
            response['message'] ?? 'Failed to load property analytics');
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
    _loadPropertyAnalytics();
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
          'Property Analytics',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _loadPropertyAnalytics,
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
            onPressed: _loadPropertyAnalytics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return RefreshIndicator(
      onRefresh: _loadPropertyAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeFrameSelector(),
                const SizedBox(height: 20),
                _buildOverviewCards(),
                const SizedBox(height: 24),
                _buildDetailedStats(),
                const SizedBox(height: 24),
                _buildStatusDistributionChart(),
                const SizedBox(height: 24),
                _buildTypeDistributionChart(),
                const SizedBox(height: 24),
                _buildLocationDistributionChart(),
                const SizedBox(height: 24),
                _buildBedroomDistributionChart(),
                const SizedBox(height: 24),
                _buildPriceRangeChart(),
                const SizedBox(height: 24),
                _buildPropertyTypeSalesAnalysis(),
              ],
            ),
          ),
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildAnimatedStatCard(
          'Total Properties',
          _analyticsData['totalProperties']?.toString() ?? '0',
          CupertinoIcons.home,
          AppColors.brandPrimary,
          0,
        ),
        _buildAnimatedStatCard(
          'Sold Properties',
          _analyticsData['soldProperties']?.toString() ?? '0',
          CupertinoIcons.checkmark_circle,
          AppColors.lightSuccess,
          1,
        ),
        _buildAnimatedStatCard(
          'Active Properties',
          _analyticsData['activeProperties']?.toString() ?? '0',
          CupertinoIcons.clock,
          AppColors.lightWarning,
          2,
        ),
        _buildAnimatedStatCard(
          'Total Value',
          _formatCurrency(_analyticsData['totalValue'] ?? 0),
          CupertinoIcons.money_dollar,
          AppColors.brandTurnary,
          3,
        ),
      ],
    );
  }

  Widget _buildAnimatedStatCard(
      String title, String value, IconData icon, Color color, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.scale(
          scale: animation,
          child: Container(
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
          ),
        );
      },
    );
  }

  Widget _buildDetailedStats() {
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
            'Detailed Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Average Price',
                  _formatCurrency(_analyticsData['averagePrice'] ?? 0),
                  Icons.attach_money,
                  AppColors.brandPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  'Recent Properties',
                  '${_analyticsData['recentProperties'] ?? 0}',
                  Icons.new_releases,
                  AppColors.lightSuccess,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistributionChart() {
    final statusData = _analyticsData['statusDistribution'] ?? {};
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
            'Property Status Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: List<PieChartSectionData>.from(
                  statusData.entries.map((entry) {
                    final total =
                        statusData.values.fold(0, (sum, value) => sum + value);
                    final percentage =
                        total > 0 ? (entry.value / total) * 100 : 0;
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: 60,
                      color: _getStatusColor(entry.key),
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: statusData.keys
                .map((status) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status as String),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  );
                })
                .toList()
                .cast<Widget>(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDistributionChart() {
    final typeData = _analyticsData['typeDistribution'] ?? {};
    if (typeData.isEmpty) return const SizedBox.shrink();

    final total = typeData.values.fold(0, (sum, value) => sum + value);
    final typeKeys = typeData.keys.toList();

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
            'Property Type Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: List<PieChartSectionData>.from(
                  typeData.entries.map((entry) {
                    final percentage =
                        total > 0 ? (entry.value / total) * 100 : 0;
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${percentage.toStringAsFixed(1)}%',
                      color: _getTypeColor(entry.key),
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: typeKeys
                .map((type) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getTypeColor(type),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  );
                })
                .toList()
                .cast<Widget>(),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'APARTMENT':
        return AppColors.brandPrimary;
      case 'HOUSE':
        return AppColors.lightSuccess;
      case 'VILLA':
        return AppColors.lightWarning;
      case 'COMMERCIAL':
        return AppColors.brandTurnary;
      case 'LANDS':
        return AppColors.lightPrimary;
      case 'DS':
        return Colors.purple;
      default:
        // Stable fallback color based on string hash
        final int hash = type.hashCode;
        // Generate a vibrant color
        return Color.fromARGB(
          255,
          (hash & 0xFF0000) >> 16 | 0x40,
          (hash & 0x00FF00) >> 8 | 0x40,
          (hash & 0x0000FF) | 0x40,
        );
    }
  }

  Widget _buildLocationDistributionChart() {
    final locationData = _analyticsData['locationDistribution'] ?? {};
    if (locationData.isEmpty) return const SizedBox.shrink();

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
            'Location Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          ...locationData.entries
              .map((entry) => _buildLocationItem(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildBedroomDistributionChart() {
    final bedroomData = _analyticsData['bedroomDistribution'] ?? {};
    if (bedroomData.isEmpty) return const SizedBox.shrink();

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
            'Bedroom Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          ...bedroomData.entries
              .map((entry) => _buildBedroomItem(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildTypeItem(String type, int count) {
    final total = _analyticsData['typeDistribution']
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
              type,
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
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
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

  Widget _buildLocationItem(String location, int count) {
    final total = _analyticsData['locationDistribution']
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
              location,
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

  Widget _buildBedroomItem(dynamic bedrooms, dynamic count) {
    final total = _analyticsData['bedroomDistribution']?.values.fold(
            0,
            (sum, value) =>
                sum +
                (value is int ? value : int.tryParse(value.toString()) ?? 0)) ??
        0;
    final countInt = count is int ? count : int.tryParse(count.toString()) ?? 0;
    final percentage = total > 0 ? (countInt / total) * 100 : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '${bedrooms.toString()} BHK',
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
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightWarning),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$countInt (${percentage.toStringAsFixed(1)}%)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeChart() {
    final priceData = _analyticsData['priceRanges'] ?? {};
    if (priceData.isEmpty) return const SizedBox.shrink();

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
            'Price Range Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: priceData.values
                    .fold(0, (max, value) => value > max ? value : max)
                    .toDouble(),
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
                      getTitlesWidget: (value, meta) {
                        const labels = [
                          '0-50L',
                          '50L-1Cr',
                          '1Cr-2Cr',
                          '2Cr-5Cr',
                          '5Cr+'
                        ];
                        if (value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt()],
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
                barGroups: List<BarChartGroupData>.from(
                  priceData.entries.map((entry) {
                    final index = _getPriceRangeIndex(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: AppColors.brandPrimary,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeSalesAnalysis() {
    final propertyTypeSales = _analyticsData['propertyTypeSales'] ?? {};
    final salesEntries = propertyTypeSales.entries.toList();

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
                  'Property Type Sales Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${salesEntries.length}',
                  style: TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (salesEntries.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No sales data available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: salesEntries.length,
              itemBuilder: (context, index) {
                final entry = salesEntries[index];
                final type = entry.key;
                final salesData = entry.value;
                return _buildPropertyTypeSalesCard(type, salesData, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeSalesCard(
      String type, Map<String, dynamic> salesData, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation)),
          child: Opacity(
            opacity: animation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  // Property Type Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getTypeColor(type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getPropertyTypeIcon(type),
                      color: _getTypeColor(type),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Sales Data
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Sales',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  Text(
                                    _formatCurrency(
                                        salesData['totalSales'] ?? 0),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.brandPrimary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Properties',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  Text(
                                    '${salesData['count'] ?? 0}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.lightSuccess,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Avg Price',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  Text(
                                    _formatCurrency(
                                        salesData['averagePrice'] ?? 0),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.lightWarning,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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

  IconData _getPropertyTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'APARTMENT':
        return Icons.apartment;
      case 'HOUSE':
        return Icons.home;
      case 'VILLA':
        return Icons.villa;
      case 'COMMERCIAL':
        return Icons.business;
      case 'LANDS':
        return Icons.landscape;
      case 'DS':
        return Icons.category;
      default:
        return Icons.home;
    }
  }

  Widget _buildPropertyCard(Map<String, dynamic> property, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation)),
          child: Opacity(
            opacity: animation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  // Property Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: property['imageUrl'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: property['imageUrl'],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child:
                                    const Icon(Icons.home, color: Colors.grey),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child:
                                    const Icon(Icons.error, color: Colors.grey),
                              ),
                            ),
                          )
                        : const Icon(Icons.home, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  // Property Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property['name'] ?? 'Unknown Property',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          property['propertyType'] ?? 'Unknown Type',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          property['propertyAddress']?['city'] ??
                              'Unknown Location',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                        property['propertyStatus'] ?? '')
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                property['propertyStatus'] ?? 'Unknown',
                                style: TextStyle(
                                  color: _getStatusColor(
                                      property['propertyStatus'] ?? ''),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatCurrency(property['price'] ?? 0),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brandPrimary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // View Button
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to property details
                      // You can implement navigation here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Viewing ${property['name']}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'FOR SALE':
      case 'ACTIVE':
        return AppColors.lightSuccess;
      case 'FOR RENT':
        return AppColors.brandPrimary;
      case 'SOLD':
        return AppColors.lightWarning;
      case 'PENDING':
        return AppColors.lightPrimary;
      case 'INACTIVE':
        return Colors.grey;
      default:
        // Stable fallback color based on string hash
        final int hash = status.hashCode;
        return Color.fromARGB(
          255,
          (hash & 0xFF0000) >> 16 | 0x80,
          (hash & 0x00FF00) >> 8 | 0x80,
          (hash & 0x0000FF) | 0x80,
        );
    }
  }

  int _getPriceRangeIndex(String range) {
    switch (range) {
      case '0-50L':
        return 0;
      case '50L-1Cr':
        return 1;
      case '1Cr-2Cr':
        return 2;
      case '2Cr-5Cr':
        return 3;
      case '5Cr+':
        return 4;
      default:
        return 0;
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0';

    double numAmount;
    if (amount is int) {
      numAmount = amount.toDouble();
    } else if (amount is double) {
      numAmount = amount;
    } else {
      numAmount = double.tryParse(amount.toString()) ?? 0.0;
    }

    if (numAmount >= 10000000) {
      return '₹${(numAmount / 10000000).toStringAsFixed(1)}Cr';
    } else if (numAmount >= 100000) {
      return '₹${(numAmount / 100000).toStringAsFixed(1)}L';
    } else if (numAmount >= 1000) {
      return '₹${(numAmount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${numAmount.toStringAsFixed(0)}';
    }
  }
}
