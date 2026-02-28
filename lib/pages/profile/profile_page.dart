// ignore_for_file: prefer_final_fields, avoid_init_to_null, use_build_context_synchronously, await_only_futures
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/controllers/user/userController.dart';
import 'package:inhabit_realties/pages/profile/widgets/profileMenuListView.dart';
import 'package:inhabit_realties/pages/profile/widgets/userNameAndLeads.dart';
import 'package:inhabit_realties/pages/profile/widgets/userProfileDetails.dart';
import 'package:inhabit_realties/pages/profile/widgets/userProfileImageView.dart';
import 'package:inhabit_realties/pages/widgets/appSpinner.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isPageLoading = false;
  UserController _userController = UserController();
  var _currentUser = null;
  Map<String, dynamic> _userStats = {
    'totalLeads': 0,
    'activeLeads': 0,
    'completedLeads': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isPageLoading = true;
    });
    await getCurrentUserFromLocalStorage();
    await _loadUserStatistics();
    setState(() {
      isPageLoading = false;
    });
  }

  Future<void> _loadUserStatistics() async {
    try {
      final stats = await _userController.getUserStatistics();
      setState(() {
        _userStats = stats;
      });
    } catch (e) {
      // Error handled silently
    }
  }

  Future<void> getCurrentUserFromLocalStorage() async {
    final currentUser = await _userController.getCurrentUserFromLocalStorage();
    setState(() {
      _currentUser = currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackgroundColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final brandColor =
        isDark ? AppColors.brandSecondary : AppColors.brandPrimary;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;
    final successColor =
        isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
    final warningColor =
        isDark ? AppColors.darkWarning : AppColors.lightWarning;

    if (isPageLoading) {
      return const Scaffold(body: Center(child: AppSpinner()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section with Curved Design
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brandTurnary,
                    AppColors.brandTurnary.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandTurnary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profile',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge!.copyWith(
                                  color: isDark
                                      ? AppColors.darkWhiteText
                                      : AppColors.lightCardBackground,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(
                              CupertinoIcons.settings_solid,
                              color: AppColors.darkWhiteText,
                            ),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/settings'),
                          ),
                        ],
                      ),
                    ),
                    // Profile Info
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Profile Image
                          const UserProfileImageView(),
                          const SizedBox(height: 20),
                          // User Name and Leads
                          const UserNameandLeads(),
                          const SizedBox(height: 20),
                          // User Details with Card
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: cardBackgroundColor,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.greyColor.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const UserProfileDetails(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Stats Section with Modern Cards
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      if (_userStats['isAdmin'] != true) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showActivityDetails(context,
                                'Total Leads', _userStats['totalLeads'] ?? 0),
                            child: _buildStatCard(
                              context,
                              '${_userStats['totalLeads']}',
                              'Total Leads (Assigned to you)',
                              brandColor,
                              CupertinoIcons.person_2_square_stack_fill,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showActivityDetails(context,
                              'Active Leads', _userStats['activeLeads'] ?? 0),
                          child: _buildStatCard(
                            context,
                            '${_userStats['activeLeads']}',
                            'Active Leads',
                            successColor,
                            Icons.trending_up_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showActivityDetails(
                              context,
                              'Completed Leads',
                              _userStats['completedLeads'] ?? 0),
                          child: _buildStatCard(
                            context,
                            '${_userStats['completedLeads']}',
                            'Completed',
                            warningColor,
                            CupertinoIcons.checkmark_circle_fill,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Menu List with Enhanced Design
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.greyColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(height: 1),
                  ProfileMenuListView(
                      assignedLeadsCount: _userStats['totalLeads'] ?? 0,
                      isAdmin: _userStats['isAdmin'] ?? false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: color),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  void _showActivityDetails(BuildContext context, String title, int count) {
    Navigator.pushNamed(context, '/activity_details', arguments: {
      'title': title,
      'count': count,
    });
  }
}
