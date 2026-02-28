import 'package:flutter/material.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/constants/profileMenuList.dart';
import 'package:inhabit_realties/pages/profile/widgets/profileListTile.dart';
import 'package:provider/provider.dart';
import 'package:inhabit_realties/controllers/notification/notificationController.dart';

class ProfileMenuListView extends StatefulWidget {
  final int assignedLeadsCount;
  final bool isAdmin;
  const ProfileMenuListView({
    super.key,
    required this.assignedLeadsCount,
    this.isAdmin = false,
  });

  @override
  State<ProfileMenuListView> createState() => _ProfileMenuListViewState();
}

class _ProfileMenuListViewState extends State<ProfileMenuListView> {
  @override
  Widget build(BuildContext context) {
    // Filter menu items based on user role
    List<Map<String, dynamic>> menuItems = List.from(ProfileMenuList.list);
    if (widget.isAdmin) {
      menuItems.removeWhere((item) => item['title'] == 'Assigned Leads');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: menuItems.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isLastItem = index == menuItems.length - 1;
        final isLogout = item['path'] == '/auth/logout';
        final defaultColor = isDark ? Colors.white70 : Colors.black87;

        // If this is the Assigned Leads item, use the real count
        int? trailingNumberLabel = item['title'] == 'Assigned Leads'
            ? widget.assignedLeadsCount
            : item['trailingNumberLabel'];
            
        // If this is the Notifications item, use the unread count
        if (item['title'] == 'Notifications') {
          return Consumer<NotificationController>(
            builder: (context, notificationController, child) {
              // Load unread count if not already loaded
              if (notificationController.unreadCount == 0 && !notificationController.isLoading) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  notificationController.getUnreadCount();
                });
              }
              
              return ProfileListTile(
                path: item['path'],
                icon: item['icon'],
                title: item['title'],
                trailingNumberLabel: notificationController.unreadCount > 0 ? notificationController.unreadCount : null,
                color: isLogout
                    ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                    : defaultColor,
                showBottomRadius: isLastItem,
              );
            },
          );
        }

        return ProfileListTile(
          path: item['path'],
          icon: item['icon'],
          title: item['title'],
          trailingNumberLabel: trailingNumberLabel,
          color: isLogout
              ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
              : defaultColor,
          showBottomRadius: isLastItem,
        );
      },
    );
  }
}
