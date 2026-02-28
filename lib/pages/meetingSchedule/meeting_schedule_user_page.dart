import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/models/meeting_schedule_model.dart';
import 'package:inhabit_realties/models/auth/UsersModel.dart';
import 'package:inhabit_realties/models/property/PropertyModel.dart';
import 'package:inhabit_realties/models/meetingSchedule/MeetingScheduleStatusModel.dart';
import 'package:inhabit_realties/services/meeting_schedule_service.dart';
import 'package:inhabit_realties/controllers/user/userController.dart';
import 'package:inhabit_realties/controllers/role/roleController.dart';
import 'package:inhabit_realties/controllers/meeting_schedule_status/meeting_schedule_status_controller.dart';
import 'package:inhabit_realties/services/property/propertyService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'widgets/meeting_type_container.dart';
import 'package:shimmer/shimmer.dart';
import 'package:inhabit_realties/pages/properties/widgets/property_image_display.dart';
import 'dart:async';

class MeetingScheduleUserPage extends StatefulWidget {
  const MeetingScheduleUserPage({super.key});

  @override
  State<MeetingScheduleUserPage> createState() =>
      _MeetingScheduleUserPageState();
}

class _MeetingScheduleUserPageState extends State<MeetingScheduleUserPage>
    with TickerProviderStateMixin {
  final MeetingScheduleService _meetingService = MeetingScheduleService();
  final UserController _userController = UserController();
  final PropertyService _propertyService = PropertyService();
  final RoleController _roleController = RoleController();
  final MeetingScheduleStatusController _meetingScheduleStatusController =
      MeetingScheduleStatusController();

  List<MeetingSchedule> _meetings = [];
  List<MeetingSchedule> _filteredMeetings = [];
  Map<String, Map<String, dynamic>> _userCache = {};
  Map<String, Map<String, dynamic>> _propertyCache = {};
  Map<String, MeetingScheduleStatusModel> _statusCache = {};
  bool _isLoading = true;
  String? _error;
  bool _showScheduledMeetings = false;

  // Meeting type filter
  List<String> _meetingTypes = [
    'ALL',
    'SCHEDULED',
    'COMPLETED',
    'CANCELLED',
    'RESCHEDULED',
    'MISSED'
  ];
  int _selectedTypeIndex = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Search and Sort
  String _searchQuery = '';
  // 'DESC' = Newest first (default), 'ASC' = Oldest first
  String _sortOrder = 'DESC';

  // Timer for checking missed meetings
  Timer? _missedMeetingTimer;

  // Pagination variables
  final ScrollController _scrollController = ScrollController();
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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

    _animationController.forward();
    _loadMyMeetings();
    _startMissedMeetingTimer();
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

      // Get next batch of meetings
      final nextBatch = _getNextBatch();
      if (nextBatch.isNotEmpty) {
        setState(() {
          _meetings.addAll(nextBatch);
          _filteredMeetings = _applyFilters(_meetings);
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

  // Get next batch of meetings (simulated pagination)
  List<MeetingSchedule> _getNextBatch() {
    // This is a simulation - in real app, you'd make an API call
    // For now, we'll just return empty to show the pagination structure
    return [];
  }

  // Apply filters to the meetings list
  List<MeetingSchedule> _applyFilters(List<MeetingSchedule> allMeetings) {
    List<MeetingSchedule> filtered = List.from(allMeetings);

    // Apply any existing filters here
    // For now, just return all meetings
    return filtered;
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
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
              'Loading more meetings...',
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
    _missedMeetingTimer?.cancel();
    super.dispose();
  }

  void _startMissedMeetingTimer() {
    // Check for missed meetings every 5 minutes
    _missedMeetingTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _checkMissedMeetings();
      }
    });
  }

  Future<void> _checkMissedMeetings() async {
    try {
      await _meetingService.checkAndUpdateMissedMeetings();
      // Refresh the meetings list to show updated statuses
      if (mounted) {
        _loadMyMeetings();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Widget _buildMeetingTypesList() {
    if (_meetingTypes.isEmpty) {
      return Container(
        height: 65,
        alignment: Alignment.center,
        child: Text(
          'No meeting types available',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.greyColor),
        ),
      );
    }

    return SizedBox(
      height: 65,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(
              _meetingTypes.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 8,
                  right: index == _meetingTypes.length - 1 ? 0 : 8,
                  top: 12,
                  bottom: 12,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTypeIndex = index;
                    });
                    _filterMeetingsByType();
                  },
                  child: _buildMeetingTypeContainer(
                    isActive: index == _selectedTypeIndex,
                    type: _meetingTypes[index],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingTypeContainer(
      {required bool isActive, required String type}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBackgroundColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final brandShadowColor =
        isDark ? AppColors.brandSecondary : AppColors.brandPrimary;
    final brandSecondaryShadowColor =
        isDark ? AppColors.darkShadowColor : AppColors.lightShadowColor;
    final activePropertyTypeContainerBackgroundColor =
        isDark ? AppColors.darkCardBackground : AppColors.darkCardBackground;
    const activePropertyTypeContainerTextColor = AppColors.darkWhiteText;

    return Container(
      padding: const EdgeInsets.only(top: 10, right: 10, bottom: 10, left: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: isActive
            ? activePropertyTypeContainerBackgroundColor
            : backgroundColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 2,
            color: isActive ? brandSecondaryShadowColor : backgroundColor,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Text(
        type,
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: isActive ? activePropertyTypeContainerTextColor : null,
            ),
      ),
    );
  }

  Widget _buildToggleButtonContainer(
      {required bool isActive, required String text}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBackgroundColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final brandShadowColor =
        isDark ? AppColors.brandSecondary : AppColors.brandPrimary;
    final brandSecondaryShadowColor =
        isDark ? AppColors.darkShadowColor : AppColors.lightShadowColor;
    final activePropertyTypeContainerBackgroundColor =
        isDark ? AppColors.darkCardBackground : AppColors.darkCardBackground;
    const activePropertyTypeContainerTextColor = AppColors.darkWhiteText;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: isActive
            ? activePropertyTypeContainerBackgroundColor
            : backgroundColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 2,
            color: isActive ? brandSecondaryShadowColor : backgroundColor,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: isActive ? activePropertyTypeContainerTextColor : null,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  void _filterMeetingsByType() {
    setState(() {
      if (_selectedTypeIndex == 0) {
        // Show all meetings
        _filteredMeetings = List.from(_meetings);
      } else {
        // Filter by status
        final selectedType = _meetingTypes[_selectedTypeIndex];
        _filteredMeetings = _meetings.where((meeting) {
          // Handle status properly - it can be a string ID or an object
          String statusKey;
          if (meeting.status is Map<String, dynamic>) {
            final statusObj = meeting.status as Map<String, dynamic>;
            statusKey = statusObj['_id'] ?? statusObj['id'] ?? '';
          } else {
            statusKey = meeting.status.toString();
          }

          final status = _statusCache[statusKey];
          if (status != null) {
            final matches = status.name.toUpperCase() == selectedType;
            return matches;
          }
          return false;
        }).toList();
      }

      // Apply Search Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        _filteredMeetings = _filteredMeetings.where((meeting) {
          final titleMatches = meeting.title.toLowerCase().contains(query);
          final propertyName = _getPropertyName(meeting.propertyId).toLowerCase();
          final customerName = _getUserName(meeting.customerId).toLowerCase();
          
          return titleMatches || propertyName.contains(query) || customerName.contains(query);
        }).toList();
      }

      // Apply Date Sort by newly added (createdAt)
      _filteredMeetings.sort((a, b) {
        DateTime dateA;
        try {
          dateA = a.createdAt != null ? DateTime.parse(a.createdAt!) : DateTime.fromMillisecondsSinceEpoch(0);
        } catch (e) {
          dateA = DateTime.fromMillisecondsSinceEpoch(0);
        }

        DateTime dateB;
        try {
          dateB = b.createdAt != null ? DateTime.parse(b.createdAt!) : DateTime.fromMillisecondsSinceEpoch(0);
        } catch (e) {
          dateB = DateTime.fromMillisecondsSinceEpoch(0);
        }

        if (_sortOrder == 'ASC') {
          return dateA.compareTo(dateB);
        } else {
          return dateB.compareTo(dateA); // DESC default (newest first)
        }
      });
    });
  }

  Future<void> _loadMyMeetings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final currentUserJson = prefs.getString('currentUser');

      if (currentUserJson == null) {
        throw Exception('User not authenticated');
      }

      final currentUserData = jsonDecode(currentUserJson);
      final currentUserId = currentUserData['_id'] ?? currentUserData['id'];
      final currentUserRole = currentUserData['role'];

      if (currentUserId == null) {
        throw Exception('User ID not found in user data');
      }

      // Use getMyMeetings() for customer meetings and getAllMeetings() for scheduled meetings
      List<MeetingSchedule> meetings;
      if (_showScheduledMeetings) {
        // For scheduled meetings, get all meetings and filter by scheduledByUserId
        final allMeetings = await _meetingService.getAllMeetings();
        meetings = allMeetings
            .where((meeting) => meeting.scheduledByUserId == currentUserId)
            .toList();
      } else {
        // For customer meetings, use the optimized getMyMeetings() method
        meetings = await _meetingService.getMyMeetings();
      }

      // Check and update missed meetings
      await _meetingService.checkAndUpdateMissedMeetings();

      setState(() {
        _meetings = meetings;
        _filteredMeetings = List.from(meetings);
        _isLoading = false;
        totalItems = meetings.length;
        hasMoreData = meetings.length >= itemsPerPage;
      });

      // Load associated data and then apply current filter
      await _loadAssociatedData();
      _filterMeetingsByType(); // Re-apply the current filter
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAssociatedData() async {
    try {
      final Set<String> userIdsToFetch = {};
      final Set<String> propertyIdsToFetch = {};

      for (final meeting in _meetings) {
        if (meeting.customerId.isNotEmpty) {
          if (meeting.customer != null) {
            _userCache[meeting.customerId] = meeting.customer!;
          } else if (!_userCache.containsKey(meeting.customerId)) {
            userIdsToFetch.add(meeting.customerId);
          }
        }

        if (meeting.scheduledByUserId.isNotEmpty) {
          if (meeting.scheduledByUser != null) {
            _userCache[meeting.scheduledByUserId] = meeting.scheduledByUser!;
          } else if (!_userCache.containsKey(meeting.scheduledByUserId)) {
            userIdsToFetch.add(meeting.scheduledByUserId);
          }
        }

        if (meeting.propertyId != null && meeting.propertyId!.isNotEmpty) {
          if (meeting.propertyDetails != null) {
            _propertyCache[meeting.propertyId!] = meeting.propertyDetails!;
          } else if (!_propertyCache.containsKey(meeting.propertyId!)) {
            propertyIdsToFetch.add(meeting.propertyId!);
          }
        }
      }

      final List<Future<void>> futures = [];

      for (final userId in userIdsToFetch) {
        futures.add(_meetingService.getUserDetails(userId).then((userDetails) {
          if (userDetails != null) {
            _userCache[userId] = userDetails;
          }
        }));
      }

      for (final propertyId in propertyIdsToFetch) {
        futures.add(_meetingService.getPropertyDetails(propertyId).then((propertyDetails) {
          if (propertyDetails != null) {
            _propertyCache[propertyId] = propertyDetails;
          }
        }));
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      // Load meeting status data
      final statusesResponse = await _meetingScheduleStatusController
          .getAllMeetingScheduleStatuses();
      if (statusesResponse['statusCode'] == 200 &&
          statusesResponse['data'] != null) {
        final statuses = statusesResponse['data'] as List<dynamic>;
        for (final statusData in statuses) {
          final status = MeetingScheduleStatusModel.fromJson(statusData);
          _statusCache[status.id] = status;
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  String _getUserName(String userId) {
    final user = _userCache[userId];
    if (user != null) {
      final firstName = user['firstName'] ?? '';
      final lastName = user['lastName'] ?? '';
      return '$firstName $lastName'.trim();
    }
    return 'User $userId';
  }

  String _getPropertyName(String? propertyId) {
    if (propertyId == null || propertyId.isEmpty) return 'No Property';

    final property = _propertyCache[propertyId];
    if (property != null) {
      return property['name'] ?? 'Property $propertyId';
    }
    return 'Property $propertyId';
  }

  String _getStatusName(dynamic status) {
    if (status is Map<String, dynamic>) {
      return status['name'] ?? 'Unknown';
    }

    final statusModel = _statusCache[status.toString()];
    if (statusModel != null) {
      return statusModel.name;
    }

    return status.toString();
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
      case 'missed':
        return AppColors.lightDanger;
      default:
        return AppColors.brandPrimary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return CupertinoIcons.calendar;
      case 'completed':
        return CupertinoIcons.checkmark_circle;
      case 'cancelled':
        return CupertinoIcons.xmark_circle;
      case 'rescheduled':
        return CupertinoIcons.arrow_2_circlepath;
      case 'missed':
        return CupertinoIcons.xmark_circle_fill;
      default:
        return CupertinoIcons.calendar;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.darkCardBackground
            : AppColors.lightCardBackground,
        foregroundColor:
            isDark ? AppColors.darkWhiteText : AppColors.lightDarkText,
        title: Text(
          'My Meetings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkWhiteText : AppColors.lightDarkText,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.refresh,
              color: AppColors.brandPrimary,
            ),
            onPressed: _loadMyMeetings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyMeetings,
        color: AppColors.brandPrimary,
        child: Column(
          children: [
            // Meeting type filter
            _buildMeetingTypesList(),

            // Toggle button for meeting types
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showScheduledMeetings = false;
                        });
                        _loadMyMeetings();
                      },
                      child: _buildToggleButtonContainer(
                        isActive: !_showScheduledMeetings,
                        text: 'My Meetings',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showScheduledMeetings = true;
                        });
                        _loadMyMeetings();
                      },
                      child: _buildToggleButtonContainer(
                        isActive: _showScheduledMeetings,
                        text: 'Scheduled by Me',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search and Sort Control
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBackground : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterMeetingsByType();
                        },
                        style: TextStyle(
                          color: isDark ? AppColors.darkWhiteText : AppColors.lightDarkText,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search meetings...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            CupertinoIcons.search,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBackground : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortOrder,
                          isExpanded: true,
                          icon: Icon(
                            CupertinoIcons.sort_down,
                            size: 20,
                            color: isDark ? AppColors.darkWhiteText : AppColors.lightDarkText,
                          ),
                          dropdownColor: isDark ? AppColors.darkCardBackground : Colors.white,
                          style: TextStyle(
                            color: isDark ? AppColors.darkWhiteText : AppColors.lightDarkText,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _sortOrder = newValue;
                                _filterMeetingsByType();
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'DESC', child: Text('Newest')),
                            DropdownMenuItem(value: 'ASC', child: Text('Oldest')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Meetings list
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _filteredMeetings.isEmpty
                          ? _buildEmptyState()
                          : _buildMeetingsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightDanger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 64,
                color: AppColors.lightDanger,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Meetings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadMyMeetings,
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.calendar_badge_plus,
                size: 64,
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Meetings Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _showScheduledMeetings
                  ? 'You haven\'t scheduled any meetings yet'
                  : 'No meetings are assigned to you',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result =
                    await Navigator.pushNamed(context, '/create_meeting');
                if (result == true) {
                  _loadMyMeetings();
                }
              },
              icon: const Icon(CupertinoIcons.add),
              label: const Text('Create Meeting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingsList() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          itemCount: _filteredMeetings.length + (hasMoreData ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the bottom
            if (index == _filteredMeetings.length) {
              return _buildLoadingIndicator();
            }

            final meeting = _filteredMeetings[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildMeetingCard(meeting, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMeetingCard(MeetingSchedule meeting, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;
    final statusName = _getStatusName(meeting.status);
    final statusColor = _getStatusColor(statusName);

    return GestureDetector(
      onTap: () {
        // Navigate to meeting details page
        Navigator.pushNamed(
          context,
          '/meeting_details',
          arguments: {'meeting': meeting},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              (isDark ? Colors.black : Colors.white).withOpacity(0.95),
            ],
          ),
          border: Border.all(
            color: statusColor.withOpacity(0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey).withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: statusColor.withOpacity(0.20),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      meeting.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Schedule Card
            _buildScheduleCard(meeting),

            // Details Card (only if there's content)
            if (meeting.description.isNotEmpty || meeting.notes.isNotEmpty)
              _buildDetailsCard(meeting),

            // People & Property Card
            _buildPeoplePropertyCard(meeting),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.brandPrimary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.brandPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Schedule Card
  Widget _buildScheduleCard(MeetingSchedule meeting) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Schedule', CupertinoIcons.calendar),
          const SizedBox(height: 16),

          // Date row
          _buildInfoRow('Date', meeting.meetingDate, CupertinoIcons.calendar),

          // Time details all in one row
          Row(
            children: [
              Expanded(
                child: _buildCompactInfoRow(
                    'Start Time', meeting.startTime, CupertinoIcons.time),
              ),
              if (meeting.endTime != null && meeting.endTime!.isNotEmpty) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow(
                      'End Time', meeting.endTime!, CupertinoIcons.time_solid),
                ),
              ],
              if (meeting.duration != null && meeting.duration!.isNotEmpty) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow(
                      'Duration', meeting.duration!, CupertinoIcons.clock),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Details Card
  Widget _buildDetailsCard(MeetingSchedule meeting) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Details', CupertinoIcons.text_bubble),
          const SizedBox(height: 12),

          // Description and Notes side by side if both exist
          if (meeting.description.isNotEmpty && meeting.notes.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfoRow('Description',
                      meeting.description, CupertinoIcons.text_bubble),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow(
                      'Notes', meeting.notes, CupertinoIcons.doc_text),
                ),
              ],
            ),
          ] else ...[
            if (meeting.description.isNotEmpty)
              _buildInfoRow('Description', meeting.description,
                  CupertinoIcons.text_bubble),
            if (meeting.notes.isNotEmpty)
              _buildInfoRow('Notes', meeting.notes, CupertinoIcons.doc_text),
          ],
        ],
      ),
    );
  }

  // People & Property Card
  Widget _buildPeoplePropertyCard(MeetingSchedule meeting) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('People & Property', CupertinoIcons.person_2),
          const SizedBox(height: 12),

          // Show the appropriate person based on meeting type
          if (!_showScheduledMeetings)
            _buildCompactPersonRow(
                'Scheduled By',
                _getUserName(meeting.scheduledByUserId),
                meeting.scheduledByUserId,
                CupertinoIcons.person_crop_circle),
          if (_showScheduledMeetings)
            _buildCompactPersonRow('Customer', _getUserName(meeting.customerId),
                meeting.customerId, CupertinoIcons.person),

          // Property with image
          if (meeting.propertyId != null && meeting.propertyId!.isNotEmpty)
            _buildPropertyRow(meeting.propertyId!),
        ],
      ),
    );
  }

  // Person row with image/initial
  Widget _buildPersonRow(
      String label, String name, String userId, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Avatar/Initial
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Property row with image
  Widget _buildPropertyRow(String propertyId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;
    final propertyName = _getPropertyName(propertyId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Property image using PropertyImageDisplay
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: PropertyImageDisplay(
                propertyId: propertyId,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Property',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  propertyName,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Compact info row for side-by-side layout
  Widget _buildCompactInfoRow(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Compact person row for side-by-side layout
  Widget _buildCompactPersonRow(
      String label, String name, String userId, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar/Initial
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
