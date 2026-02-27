// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/controllers/role/roleController.dart';
import 'package:inhabit_realties/controllers/user/userController.dart';
import 'package:inhabit_realties/models/auth/UsersModel.dart';
import 'package:inhabit_realties/models/role/RolesModel.dart';
import 'package:inhabit_realties/pages/users/widgets/appAppbar.dart';
import 'package:inhabit_realties/pages/users/widgets/role.dart';
import 'package:inhabit_realties/pages/widgets/appSpinner.dart';
import 'package:inhabit_realties/pages/widgets/app_search_bar.dart';
import 'package:inhabit_realties/pages/widgets/profile_avatar.dart';
import 'package:inhabit_realties/providers/users_page_provider.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with SingleTickerProviderStateMixin {
  final RoleController _rolesController = RoleController();
  final UserController _userController = UserController();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool isPageLoading = true;
  List<RolesModel> roles = [];
  List<UsersModel> users = [];
  List<UsersModel> filteredUsers = [];
  int choosedRole = -1;
  int _roleIndex = 0;

  // Pagination variables
  bool isLoadingMore = false;
  bool hasMoreData = true;
  static const int itemsPerPage = 20;
  int currentPage = 0;
  int totalItems = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    roles.add(
      RolesModel(
        id: '0',
        name: 'ALL',
        description: 'All types',
        createdByUserId: '0',
        updatedByUserId: '0',
        published: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

    _loadData();
  }

  // Scroll listener for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMoreData) {
        _loadMoreData();
      }
    }
  }

  // Load more data for pagination
  Future<void> _loadMoreData() async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      // Simulate loading more data (in real app, this would be an API call)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get next batch of users
      final nextBatch = _getNextBatch();
      if (nextBatch.isNotEmpty) {
        setState(() {
          users.addAll(nextBatch);
          filteredUsers = _applyFilters(users);
          currentPage++;
        });
      } else {
        setState(() {
          hasMoreData = false;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  // Get next batch of users (simulated pagination)
  List<UsersModel> _getNextBatch() {
    // This is a simulation - in real app, you'd make an API call
    // For now, we'll just return empty to show the pagination structure
    return [];
  }

  // Apply filters to the users list
  List<UsersModel> _applyFilters(List<UsersModel> allUsers) {
    List<UsersModel> filtered = List.from(allUsers);
    
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((user) =>
          user.firstName.toLowerCase().contains(query) ||
          user.lastName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query)).toList();
    }

    return filtered;
  }

  Future<void> _loadData() async {
    setState(() => isPageLoading = true);
    await Future.wait([getAllRoles(), getUsersByRoleId('0')]);
    
    setState(() {
      totalItems = users.length;
      hasMoreData = users.length >= itemsPerPage;
    });
    
    _animationController.forward();
  }

  Future<void> getAllRoles() async {
    try {
      final response = await _rolesController.getAllRoles();
      if (response['statusCode'] == 200 && mounted) {
        final data = response['data'];
        if (data.isNotEmpty) {
          setState(() {
            // Re-initialize roles to prevent duplicates on refresh
            roles = [
              RolesModel(
                id: '0',
                name: 'ALL',
                description: 'All types',
                createdByUserId: '0',
                updatedByUserId: '0',
                published: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              )
            ];
            roles.addAll(
              data
                  .map<RolesModel>((item) => RolesModel.fromJson(item))
                  .toList(),
            );
          });

          // Debug: Print loaded roles
          // print('DEBUG: Loaded ${roles.length} roles:');
          // for (var role in roles) {
          //   print('DEBUG: Role - Name: ${role.name}, ID: ${role.id}');
          // }
        }
      }
    } catch (e) {
      // print('DEBUG: Error loading roles: $e');
      // Handle error appropriately
    }
  }

  Future<void> getUsersByRoleId(String roleId) async {
    try {
      final response = roleId == '0'
          ? await _userController.getAllUsers()
          : await _userController.getUsersByRoleId(roleId);

      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          users = (response['data'] as List)
              .map((item) => UsersModel.fromJson(item))
              .toList();
          filteredUsers = List.from(users);
        });

        // Debug: Print user role information
        // print('DEBUG: Loaded ${users.length} users:');
        // for (var user in users) {
        //   print(
        //       'DEBUG: User ${user.firstName} ${user.lastName} has role ID: ${user.role}');
        // }
      }
    } catch (e) {
      // print('DEBUG: Error loading users: $e');
      // Handle error appropriately
    } finally {
      if (mounted) {
        setState(() => isPageLoading = false);
      }
    }
  }

  void _handleSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(users);
      } else {
        filteredUsers = users.where((user) {
          final name = '${user.firstName} ${user.lastName}'.toLowerCase();
          final email = user.email.toLowerCase();
          final role = roles
              .firstWhere(
                (r) => r.id == user.role,
                orElse: () => RolesModel(
                  id: '',
                  name: 'Unknown',
                  description: '',
                  createdByUserId: '',
                  updatedByUserId: '',
                  published: false,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              )
              .name
              .toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) ||
              email.contains(searchLower) ||
              role.contains(searchLower);
        }).toList();
      }
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Column(
        children: [
          Text(
            UsersPageProvider.mainTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your team members',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesList() {
    if (roles.isEmpty) return const AppSpinner(size: 24.0, strokeWidth: 2.0);

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 24),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: roles.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 20 : 8,
              right: index == roles.length - 1 ? 20 : 8,
            ),
            child: InkWell(
              onTap: () async {
                setState(() {
                  choosedRole = index;
                  _roleIndex = index;
                  isPageLoading = true;
                });
                await getUsersByRoleId(roles[index].id);
              },
              child: RoleContainer(
                isActive: index == _roleIndex,
                role: roles[index].name,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: AppSearchBar(
        controller: _searchController,
        onChanged: _handleSearch,
        hintText: 'Search users...',
        onClear: () => _handleSearch(''),
      ),
    );
  }

  Widget _buildUsersList(BuildContext context) {
    if (filteredUsers.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No users found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Show loading indicator at the bottom
          if (index == filteredUsers.length) {
            return _buildLoadingIndicator();
          }
          
          final user = filteredUsers[index];
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardBackgroundColor = isDark
              ? AppColors.darkCardBackground
              : AppColors.lightCardBackground;
          final brandColor =
              isDark ? AppColors.brandSecondary : AppColors.brandPrimary;
          final shadowColor = isDark
              ? AppColors.lightCardBackground
              : AppColors.darkCardBackground;
          final dangerColor =
              isDark ? AppColors.darkDanger : AppColors.lightDanger;

          return Container(
            margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                  color: shadowColor.withOpacity(0.08),
                ),
              ],
              color: user.published
                  ? cardBackgroundColor
                  : dangerColor.withOpacity(0.3),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pushNamed(context, '/users/edit', arguments: user);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'avatar_${user.id}',
                        child: ProfileAvatar(
                          userId: user.id,
                          userName: '${user.firstName} ${user.lastName}',
                          size: 50,
                          showBorder: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${user.firstName} ${user.lastName}",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.greyColor2),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: brandColor),
                          borderRadius: BorderRadius.circular(20),
                          color: brandColor.withOpacity(0.1),
                        ),
                        child: Text(
                          roles.isNotEmpty
                              ? (() {
                                  try {
                                    final foundRole = roles.firstWhere(
                                      (role) => role.id == user.role,
                                      orElse: () => RolesModel(
                                        id: '',
                                        name: 'Unknown',
                                        description: '',
                                        createdByUserId: '',
                                        updatedByUserId: '',
                                        published: false,
                                        createdAt: DateTime.now(),
                                        updatedAt: DateTime.now(),
                                      ),
                                    );

                                    return foundRole.name;
                                  } catch (e) {
                                    return 'Unknown';
                                  }
                                })()
                              : "",
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                                color: brandColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: filteredUsers.length + (hasMoreData ? 1 : 0),
      ),
    );
  }

  // Build loading indicator for pagination
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading more users...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const AppAppbar(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(children: [_buildHeader(), _buildRolesList()]),
                ),
                SliverToBoxAdapter(child: _buildSearchBar()),
                _buildUsersList(context),
                // Add bottom padding to prevent overflow
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ),
            if (isPageLoading)
              Container(
                color: AppColors.greyColor,
                child: const Center(
                  child: AppSpinner(size: 32.0, strokeWidth: 3.0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
