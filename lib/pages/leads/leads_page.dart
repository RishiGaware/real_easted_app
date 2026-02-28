import 'package:flutter/material.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/controllers/lead/leadsController.dart';
import 'package:inhabit_realties/models/lead/LeadsModel.dart';
import 'package:inhabit_realties/models/lead/LeadStatusModel.dart';
import 'package:inhabit_realties/models/lead/FollowUpStatusModel.dart';
import 'package:inhabit_realties/models/lead/ReferenceSourceModel.dart';
import 'package:inhabit_realties/models/auth/UsersModel.dart';
import 'package:inhabit_realties/services/lead/leadsService.dart';
import 'package:inhabit_realties/services/user/userService.dart';
import 'package:inhabit_realties/pages/leads/widgets/appAppBar.dart';
import 'package:inhabit_realties/pages/widgets/appSpinner.dart';
import 'package:inhabit_realties/pages/widgets/app_search_bar.dart';
import 'package:inhabit_realties/pages/widgets/horizontal_filter_bar.dart';
import 'package:inhabit_realties/pages/leads/lead_details_page.dart';
import 'package:inhabit_realties/pages/leads/widgets/addNewLeadButton.dart';
import 'package:inhabit_realties/constants/status_utils.dart';
import 'package:inhabit_realties/controllers/notification/notificationController.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> with TickerProviderStateMixin {
  final LeadsController _leadsController = LeadsController();
  final LeadsService _leadsService = LeadsService();
  final UserService _userService = UserService();
  late final AnimationController _animationController;
  late final AnimationController _staggerController;
  late final Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isPageLoading = false;
  bool isInitialLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  List<LeadsModel> leads = [];
  List<LeadsModel> filteredLeads = [];

  // Pagination settings
  static const int itemsPerPage = 20;
  int currentPage = 0;
  int totalItems = 0;

  // Filter data
  List<LeadStatusModel> leadStatuses = [];
  List<FollowUpStatusModel> followUpStatuses = [];
  List<ReferenceSourceModel> referenceSources = [];
  List<UsersModel> users = [];

  // Filter values
  String? selectedLeadStatus;
  String? selectedFollowUpStatus;
  String? selectedReferenceSource;
  String? selectedAssignedBy;
  String? selectedAssignedTo;
  String searchQuery = '';
  bool isFilterVisible = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _staggerController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll listener for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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

      // Get next batch of leads
      final nextBatch = _getNextBatch();
      if (nextBatch.isNotEmpty) {
        setState(() {
          leads.addAll(nextBatch);
          filteredLeads = _applyFilters(leads);
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

  // Get next batch of leads (simulated pagination)
  List<LeadsModel> _getNextBatch() {
    // This is a simulation - in real app, you'd make an API call
    // For now, we'll just return empty to show the pagination structure
    return [];
  }

  // Apply filters to the leads list
  List<LeadsModel> _applyFilters(List<LeadsModel> allLeads) {
    List<LeadsModel> filtered = List.from(allLeads);

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((lead) =>
              lead.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              lead.leadEmail
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              lead.leadPhoneNumber.contains(searchQuery))
          .toList();
    }

    if (selectedLeadStatus != null) {
      filtered = filtered
          .where((lead) => lead.leadStatus == selectedLeadStatus)
          .toList();
    }

    if (selectedFollowUpStatus != null) {
      filtered = filtered
          .where((lead) => lead.followUpStatus == selectedFollowUpStatus)
          .toList();
    }

    if (selectedReferenceSource != null) {
      filtered = filtered
          .where((lead) => lead.referanceFrom?.id == selectedReferenceSource)
          .toList();
    }

    if (selectedAssignedBy != null) {
      filtered = filtered
          .where((lead) => lead.assignedByUserId == selectedAssignedBy)
          .toList();
    }

    if (selectedAssignedTo != null) {
      filtered = filtered
          .where((lead) => lead.assignedToUserId == selectedAssignedTo)
          .toList();
    }

    return filtered;
  }

  Future<void> _loadData() async {
    setState(() {
      isPageLoading = true;
      isInitialLoading = true;
    });
    await getAllLeadStatuses();
    await getAllFollowUpStatuses();
    await getAllReferenceSources();
    await getAllUsers();
    await loadLeads();

    setState(() {
      isPageLoading = false;
      isInitialLoading = false;
    });
    _animationController.forward();
  }

  Future<void> loadLeads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final currentUser = prefs.getString('currentUser') ?? '';
      final decodedCurrentUser = jsonDecode(currentUser);
      final userId = decodedCurrentUser['_id'] ?? '';

      final response = await _leadsService.getAllLeads(token, userId);
      if (response['statusCode'] == 200 && mounted) {
        final data = response['data'];
        List<dynamic> leadsData = [];

        if (data is Map && data.containsKey('value')) {
          leadsData = data['value'] ?? [];
        } else if (data is List) {
          leadsData = data;
        } else {
          leadsData = [];
        }

        setState(() {
          leads = leadsData.map((item) => LeadsModel.fromJson(item)).toList();
          filteredLeads = _applyFilters(leads);
          totalItems = leads.length;
          hasMoreData = leads.length >= itemsPerPage;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> getAllLeadStatuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final currentUser = prefs.getString('currentUser') ?? '';
      final decodedCurrentUser = jsonDecode(currentUser);
      final userId = decodedCurrentUser['_id'] ?? '';

      final response = await _leadsService.getAllLeadStatuses(token, userId);
      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          leadStatuses = (response['data'] as List)
              .map((item) => LeadStatusModel.fromJson(item))
              .toList();
        });
        // Update StatusUtils with the loaded statuses
        StatusUtils.setLeadStatuses(leadStatuses);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> getAllFollowUpStatuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final currentUser = prefs.getString('currentUser') ?? '';
      final decodedCurrentUser = jsonDecode(currentUser);
      final userId = decodedCurrentUser['_id'] ?? '';

      final response =
          await _leadsService.getAllFollowUpStatuses(token, userId);
      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          followUpStatuses = (response['data'] as List)
              .map((item) => FollowUpStatusModel.fromJson(item))
              .toList();
        });
        // Update StatusUtils with the loaded statuses
        StatusUtils.setFollowUpStatuses(followUpStatuses);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> getAllReferenceSources() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final currentUser = prefs.getString('currentUser') ?? '';
      final decodedCurrentUser = jsonDecode(currentUser);
      final userId = decodedCurrentUser['_id'] ?? '';

      final response =
          await _leadsService.getAllReferenceSources(token, userId);
      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          referenceSources = (response['data'] as List)
              .map((item) => ReferenceSourceModel.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await _userService.getAllUsers(token);
      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          users = (response['data'] as List)
              .map((item) => UsersModel.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _handleSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredLeads = _applyFilters(leads);
    });
  }

  void _handleLeadStatusFilter(String? status) {
    setState(() {
      selectedLeadStatus = status;
      filteredLeads = _applyFilters(leads);
    });
  }

  void _handleFollowUpStatusFilter(String? status) {
    setState(() {
      selectedFollowUpStatus = status;
      filteredLeads = _applyFilters(leads);
    });
  }

  void _handleReferenceSourceFilter(String? source) {
    setState(() {
      selectedReferenceSource = source;
      filteredLeads = _applyFilters(leads);
    });
  }

  void _handleAssignedByFilter(String? userId) {
    setState(() {
      selectedAssignedBy = userId;
      filteredLeads = _applyFilters(leads);
    });
  }

  void _handleAssignedToFilter(String? userId) {
    setState(() {
      selectedAssignedTo = userId;
      filteredLeads = _applyFilters(leads);
    });
  }

  void _clearFilters() {
    setState(() {
      selectedLeadStatus = null;
      selectedFollowUpStatus = null;
      selectedReferenceSource = null;
      selectedAssignedBy = null;
      selectedAssignedTo = null;
      searchQuery = '';
      filteredLeads = _applyFilters(leads);
    });
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
              'Loading more leads...',
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

  // Helper methods to extract user information from the lead
  String _getLeadFirstName(LeadsModel lead) {
    return lead.leadFirstName;
  }

  String _getLeadLastName(LeadsModel lead) {
    return lead.leadLastName;
  }

  String _getLeadEmail(LeadsModel lead) {
    return lead.leadEmail;
  }

  String _getLeadPhone(LeadsModel lead) {
    return lead.leadPhoneNumber;
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;
    final secondaryTextColor =
        isDark ? AppColors.greyColor : AppColors.greyColor2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leads',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
              ),
              Text(
                '${filteredLeads.length} leads found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeadStatusFilter() {
    if (leadStatuses.isEmpty) return const SizedBox.shrink();

    final filters = [
      'ALL',
      ...leadStatuses.map((status) => status.name).toList()
    ];
    final selectedIndex = selectedLeadStatus == null
        ? 0
        : leadStatuses
                .indexWhere((status) => status.name == selectedLeadStatus) +
            1;

    return HorizontalFilterBar(
      filters: filters,
      selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
      onFilterChanged: (index) {
        if (index == 0) {
          setState(() {
            selectedLeadStatus = null;
            filteredLeads = _applyFilters(leads);
          });
        } else {
          setState(() {
            selectedLeadStatus = leadStatuses[index - 1].name;
            filteredLeads = _applyFilters(leads);
          });
        }
      },
    );
  }

  Widget _buildFilterSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final secondaryTextColor =
        isDark ? AppColors.greyColor : AppColors.greyColor2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          AppSearchBar(
            controller: _searchController,
            onChanged: _handleSearch,
            hintText: 'Search by name, email, phone...',
          ),
          const SizedBox(height: 12),
          // Filter dropdowns in a grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterDropdown(
                'Lead Status',
                selectedLeadStatus,
                leadStatuses.map((status) => status.name).toList(),
                (value) {
                  _handleLeadStatusFilter(value);
                },
                secondaryTextColor,
              ),
              _buildFilterDropdown(
                'Follow-up Status',
                selectedFollowUpStatus,
                followUpStatuses.map((status) => status.name).toList(),
                (value) {
                  _handleFollowUpStatusFilter(value);
                },
                secondaryTextColor,
              ),
              _buildFilterDropdown(
                'Reference Source',
                selectedReferenceSource,
                referenceSources.map((source) => source.name).toList(),
                (value) {
                  _handleReferenceSourceFilter(value);
                },
                secondaryTextColor,
              ),
              _buildFilterDropdown(
                'Assigned By',
                selectedAssignedBy,
                users
                    .map((user) => '${user.firstName} ${user.lastName}')
                    .toList(),
                (value) {
                  _handleAssignedByFilter(value);
                },
                secondaryTextColor,
              ),
              _buildFilterDropdown(
                'Assigned To',
                selectedAssignedTo,
                users
                    .map((user) => '${user.firstName} ${user.lastName}')
                    .toList(),
                (value) {
                  _handleAssignedToFilter(value);
                },
                secondaryTextColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Clear filters button (only show when filters are active)
          if (selectedLeadStatus != null ||
              selectedFollowUpStatus != null ||
              selectedReferenceSource != null ||
              selectedAssignedBy != null ||
              selectedAssignedTo != null ||
              searchQuery.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: 14),
                label:
                    const Text('Clear Filters', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.lightDanger,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? selectedValue,
    List<String> options,
    Function(String?) onChanged,
    Color textColor,
  ) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: textColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButton<String>(
              value: selectedValue,
              hint: Text(
                'All',
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withOpacity(0.6),
                ),
              ),
              isExpanded: true,
              underline: Container(),
              icon: Icon(Icons.arrow_drop_down, size: 16, color: textColor),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All', style: TextStyle(fontSize: 11)),
                ),
                ...options
                    .map((option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsList() {
    if (isPageLoading) {
      return const Center(child: AppSpinner());
    }

    if (filteredLeads.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.greyColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people_outline,
                        size: 64,
                        color: AppColors.greyColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No leads found',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.greyColor2,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first lead to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.greyColor,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: filteredLeads.length + (hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the bottom
          if (index == filteredLeads.length) {
            return _buildLoadingIndicator();
          }

          final lead = filteredLeads[index];
          final animationDelay = index * 0.1;

          return AnimatedBuilder(
            animation: _staggerController,
            builder: (context, child) {
              final animationValue = Curves.easeOutCubic.transform(
                (_staggerController.value - animationDelay).clamp(0.0, 1.0),
              );

              return Transform.translate(
                offset: Offset(0, 50 * (1 - animationValue)),
                child: _buildLeadCard(lead, index),
              );
            },
          );
        },
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
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeadDetailsPage(lead: lead),
              ),
            );
            
            // If the lead was edited successfully, reload data
            if (result == true && mounted) {
              _loadData();
            }
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
                // Profile Image/Avatar
                _buildProfileAvatar(lead, index),
                const SizedBox(width: 16),

                // Lead Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Status
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
                          const SizedBox(width: 8),
                          // Notification indicator
                          Consumer<NotificationController>(
                            builder: (context, notificationController, child) {
                              final hasUnreadNotifications =
                                  notificationController.notifications
                                      .where((notification) =>
                                          notification.relatedId == lead.id &&
                                          !notification.isRead)
                                      .isNotEmpty;

                              if (hasUnreadNotifications) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.brandPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Email
                      _buildInfoRow(
                        Icons.email_outlined,
                        lead.leadEmail,
                        secondaryTextColor,
                      ),
                      const SizedBox(height: 4),

                      // Phone
                      _buildInfoRow(
                        Icons.phone_outlined,
                        lead.leadPhoneNumber,
                        secondaryTextColor,
                      ),
                      const SizedBox(height: 8),

                      // Follow-up Status and Designation
                      Row(
                        children: [
                          // Follow-up Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  _getFollowUpStatusColor(lead.followUpStatus)
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    _getFollowUpStatusColor(lead.followUpStatus)
                                        .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getFollowUpStatusDisplayName(
                                  lead.followUpStatus),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: _getFollowUpStatusColor(
                                        lead.followUpStatus),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Designation
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.brandPrimary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getDesignationDisplayName(lead.leadDesignation),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.brandPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

  String _getDesignationDisplayName(String designation) {
    // Handle common designations
    switch (designation.toUpperCase()) {
      case 'BUYER':
        return 'Buyer';
      case 'SELLER':
        return 'Seller';
      case 'INVESTOR':
        return 'Investor';
      case 'TENANT':
        return 'Tenant';
      case 'LANDLORD':
        return 'Landlord';
      default:
        // If it's an ObjectId or unknown, return a default
        if (designation.length == 24 &&
            RegExp(r'^[a-fA-F0-9]+$').hasMatch(designation)) {
          return 'Unknown';
        }
        return designation.isNotEmpty ? designation : 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: LeadsAppBar(
        actions: [
          // Filter button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isFilterVisible
                  ? AppColors.brandPrimary
                  : AppColors.brandPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  isFilterVisible = !isFilterVisible;
                });
              },
              icon: Icon(
                Icons.filter_list,
                color: isFilterVisible
                    ? AppColors.darkWhiteText
                    : AppColors.brandPrimary,
                size: 20,
              ),
              tooltip: 'Toggle Filters',
            ),
          ),
          // Add Lead button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AddNewLeadButton(
              onLeadAdded: _loadData,
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            _buildLeadStatusFilter(),
            if (isFilterVisible) _buildFilterSection(),
            Expanded(child: _buildLeadsList()),
          ],
        ),
      ),
    );
  }
}
