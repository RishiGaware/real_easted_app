import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/constants/drawerMenuList.dart';
import 'package:inhabit_realties/models/auth/UsersModel.dart';
import 'package:inhabit_realties/pages/widgets/listTile.dart';
import 'package:inhabit_realties/pages/widgets/loader.dart';
import 'package:inhabit_realties/controllers/file/userProfilePictureController.dart';
import 'package:inhabit_realties/controllers/role/roleController.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String userName = "";
  String userEmail = "";
  String? userProfileImage;
  bool isImageLoading = false;
  final UserProfilePictureController _profilePictureController =
      UserProfilePictureController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isImageLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = prefs.getString('currentUser') ?? "";
      if (currentUser.isNotEmpty) {
        final decodedCurrentUser = jsonDecode(currentUser);
        UsersModel usersModel = UsersModel.fromJson(decodedCurrentUser);

        // Get profile image using the controller
        try {
          final imageResponse = await _profilePictureController.get();
          String? imageUrl;

          if (imageResponse['statusCode'] == 200 &&
              imageResponse['data'] != null) {
            imageUrl = imageResponse['data']['url'];
          }

          setState(() {
            userName = "${usersModel.firstName} ${usersModel.lastName}";
            userEmail = usersModel.email;
            userProfileImage = imageUrl;
          });
        } catch (e) {
          // If profile image fails, still show user data
          setState(() {
            userName = "${usersModel.firstName} ${usersModel.lastName}";
            userEmail = usersModel.email;
            userProfileImage = null;
          });
        }
      }
    } catch (e) {
      // Error handled silently
    } finally {
      setState(() {
        isImageLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;
    final brandColor =
        isDark ? AppColors.brandSecondary : AppColors.brandPrimary;

    return Drawer(
      backgroundColor: cardColor,
      child: Column(
        children: [
          DrawerHeader(
            padding: EdgeInsets.zero,
            decoration: const BoxDecoration(color: AppColors.lightBackground),
            child: Image.asset(
              'assets/images/applogo2.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          if (userName.isNotEmpty || userEmail.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: isDark
                      ? [
                          AppColors.darkPrimary.withOpacity(0.1),
                          AppColors.brandSecondary.withOpacity(0.05),
                        ]
                      : [
                          AppColors.lightPrimary.withOpacity(0.1),
                          AppColors.brandPrimary.withOpacity(0.05),
                        ],
                ),
              ),
              child: Row(
                children: [
                  isImageLoading
                      ? const SizedBox(
                          width: 50,
                          height: 50,
                          child: Center(child: Loader()),
                        )
                      : CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          backgroundImage: userProfileImage != null
                              ? NetworkImage(
                                  userProfileImage!,
                                  headers: {
                                    'Cache-Control': 'no-cache',
                                    'Pragma': 'no-cache',
                                  },
                                )
                              : null,
                          onBackgroundImageError: userProfileImage != null
                              ? (exception, stackTrace) {
                                  // Handle image loading error silently
                                }
                              : null,
                          child: userProfileImage == null
                              ? Icon(
                                  CupertinoIcons.person_fill,
                                  size: 25,
                                  color: brandColor,
                                )
                              : null,
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (userName.isNotEmpty)
                          Text(
                            userName,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (userEmail.isNotEmpty)
                          Text(
                            userEmail,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: textColor.withOpacity(0.7)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder(
              future: _loadUserRole(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userRole = snapshot.data as String?;
                print('DEBUG: User role loaded: $userRole'); // Debug log
                final filteredMenuItems = _getFilteredMenuItems(userRole);
                print(
                    'DEBUG: Total menu items: ${DrawerMenuList.list.length}'); // Debug log
                print(
                    'DEBUG: Filtered menu items: ${filteredMenuItems.length}'); // Debug log
                print('DEBUG: Menu items:'); // Debug log
                for (final item in filteredMenuItems) {
                  print(
                      'DEBUG: - ${item['title']} (${item['path']})'); // Debug log
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredMenuItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredMenuItems[index];
                    final isLogout = item['path'] == '/auth/logout';

                    return Column(
                      children: [
                        DrawerListTile(
                          path: item['path'],
                          icon: item['icon'],
                          title: item['title'],
                        ),
                        if (isLogout || index == filteredMenuItems.length - 1)
                          const SizedBox(height: 8)
                        else if (index == 6) // Add divider after Meetings
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Divider(
                              color: textColor.withOpacity(0.1),
                              height: 1,
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor.withOpacity(0.5),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = prefs.getString('currentUser') ?? '';

      if (currentUser.isNotEmpty) {
        final userData = jsonDecode(currentUser);
        final roleData = userData['role'];

        // If role is already populated as an object (Map)
        if (roleData is Map && roleData.containsKey('name')) {
          return roleData['name']?.toString() ?? '';
        }

        // If role is just an ID string, fetch it from backend
        if (roleData is String && roleData.isNotEmpty) {
          try {
            final roleController = RoleController();
            final response = await roleController.getRoleById(roleData);

            // Robust extraction: check both response['data'] and top-level response
            if (response['data'] != null && response['data'] is Map) {
              return response['data']['name']?.toString() ?? '';
            } else if (response['name'] != null) {
              return response['name'].toString();
            }
          } catch (e) {
            // Handle error silently
          }
        }
      }
    } catch (e) {
      // Handle error silently
    }
    return null;
  }

  List<Map<String, dynamic>> _getFilteredMenuItems(String? userRole) {
    // Debug print for troubleshooting
    print('DEBUG: Filtering menu for detected role string: "$userRole"');

    final String roleLower = userRole?.toLowerCase().trim() ?? '';
    
    // Check if user is Admin (handle "admin" or "administrator")
    final bool isAdmin = roleLower == 'admin' || roleLower == 'administrator';
    
    final bool isExecutiveLine = roleLower == 'executive';
    final bool isSalesLine = roleLower == 'sales person' || roleLower == 'sales';

    return DrawerMenuList.list.where((item) {
      final path = item['path'] as String;

      // Admin-only routes
      if (path == '/users' || path == '/auth/register') {
        return isAdmin;
      }

      // Hide "All Documents" from Executive and Sales
      if (path == '/documents/all') {
        if (isExecutiveLine || isSalesLine) {
          return false;
        }
      }

      // Default: show item
      return true;
    }).toList();
  }

}
