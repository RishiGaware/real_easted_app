import 'package:flutter/material.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/controllers/user/userController.dart';
import 'package:inhabit_realties/controllers/role/roleController.dart';
import 'package:inhabit_realties/pages/widgets/appSpinner.dart';

class UserNameandLeads extends StatefulWidget {
  const UserNameandLeads({super.key});

  @override
  State<UserNameandLeads> createState() => _UserNameandLeadsState();
}

class _UserNameandLeadsState extends State<UserNameandLeads> {
  bool isPageLoading = false;
  String? roleName;
  final UserController _userController = UserController();
  final RoleController _roleController = RoleController();
  var _currentUser;
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
    if (_currentUser != null && _currentUser.role != null) {
      await _loadRoleName();
    }
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

  Future<void> _loadRoleName() async {
    try {
      final roleData = await _roleController.getRoleById(_currentUser.role);
      setState(() {
        roleName = roleData['data']['name'] ?? 'User';
      });
    } catch (e) {
      setState(() {
        roleName = 'User';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isPageLoading) {
      return const AppSpinner();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;
    final brandColor =
        isDark ? AppColors.brandSecondary : AppColors.brandPrimary;
    final cardColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${_currentUser?.firstName ?? ""} ${_currentUser?.lastName ?? ""}'
                .trim(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              roleName ?? 'User',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: brandColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     _buildStatItem(context, '${_userStats['totalLeads']}',
          //         'Total Leads', brandColor),
          //     Container(
          //       height: 24,
          //       width: 1,
          //       margin: const EdgeInsets.symmetric(horizontal: 16),
          //       color: textColor.withOpacity(0.1),
          //     ),
          //     _buildStatItem(context, '${_userStats['activeLeads']}', 'Active',
          //         brandColor),
          //     Container(
          //       height: 24,
          //       width: 1,
          //       margin: const EdgeInsets.symmetric(horizontal: 16),
          //       color: textColor.withOpacity(0.1),
          //     ),
          //     _buildStatItem(context, '${_userStats['completedLeads']}',
          //         'Completed', brandColor),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    Color brandColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: brandColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: textColor.withOpacity(0.7)),
        ),
      ],
    );
  }
}
