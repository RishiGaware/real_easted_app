import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/services/meeting_schedule_service.dart';
import 'package:inhabit_realties/models/meeting_schedule_model.dart';
import 'package:inhabit_realties/pages/widgets/appSnackBar.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class MyScheduledMeetingsPage extends StatefulWidget {
  const MyScheduledMeetingsPage({super.key});

  @override
  State<MyScheduledMeetingsPage> createState() =>
      _MyScheduledMeetingsPageState();
}

class _MyScheduledMeetingsPageState extends State<MyScheduledMeetingsPage>
    with TickerProviderStateMixin {
  final MeetingScheduleService _meetingService = MeetingScheduleService();
  List<MeetingSchedule> _meetings = [];
  List<MeetingSchedule> _filteredMeetings = [];
  bool _isLoading = true;
  String? _error;

  // Search and Sort
  String _searchQuery = '';
  // 'DESC' = Newest first (default), 'ASC' = Oldest first
  String _sortOrder = 'DESC';

  // Cache for user and property details
  Map<String, Map<String, dynamic>> _userCache = {};
  Map<String, Map<String, dynamic>> _propertyCache = {};

  // Current user role for permission checking
  String? _currentUserRole;

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

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadCurrentUserRole();
    _loadMyScheduledMeetings();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserJson = prefs.getString('currentUser');



      if (currentUserJson != null) {
        final userData = json.decode(currentUserJson);


        // Try different possible role field structures
        _currentUserRole = userData['role']?['name'] ??
            userData['role'] ??
            userData['roleId']?['name'] ??
            userData['roleId'];



        // Force a rebuild to update the UI
        if (mounted) {
          setState(() {});
        }
      } else {

      }
    } catch (e) {
      // Handle error silently
    }
  }

  bool _canCreateMeetings() {
    if (_currentUserRole == null) {
      return false;
    }

    final role = _currentUserRole!.toLowerCase();
    final canCreate = role == 'admin' || role == 'sales' || role == 'executive';

    return canCreate;
  }

  Future<void> _loadMyScheduledMeetings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get all meetings and filter by scheduledByUserId
      final allMeetings = await _meetingService.getAllMeetings();
      final myScheduledMeetings = allMeetings
          .where((meeting) => meeting.scheduledByUserId == currentUserId)
          .toList();

      // Load associated data for all meetings
      await _loadAssociatedData(myScheduledMeetings);

      setState(() {
        _meetings = myScheduledMeetings;
        _isLoading = false;
      });

      _applyFilters();

      // Start animation after data is loaded
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAssociatedData(List<MeetingSchedule> meetings) async {
    final Set<String> userIdsToFetch = {};
    final Set<String> propertyIdsToFetch = {};

    for (final meeting in meetings) {
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

    if (mounted) {
      setState(() {});
    }
  }

  void _applyFilters() {
    setState(() {
      List<MeetingSchedule> filtered = _meetings;

      if (_selectedTypeIndex != 0) {
        final selectedType = _meetingTypes[_selectedTypeIndex];
        final now = DateTime.now();

        filtered = filtered.where((meeting) {
          final status = meeting.getStatusName().toUpperCase();

          if (selectedType == 'SCHEDULED') {
            if (status == 'SCHEDULED') {
              try {
                final meetingDate = DateTime.parse(meeting.meetingDate);
                final endTime = meeting.endTime ?? meeting.startTime;

                final meetingEndDateTime = DateTime(
                  meetingDate.year,
                  meetingDate.month,
                  meetingDate.day,
                  int.parse(endTime.split(':')[0]),
                  int.parse(endTime.split(':')[1]),
                );

                return meetingEndDateTime.isAfter(now);
              } catch (e) {
                return true;
              }
            }
            return false;
          }

          return status == selectedType;
        }).toList();
      }

      // Apply Search Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered.where((meeting) {
          final titleMatches = meeting.title.toLowerCase().contains(query);
          final propertyName = _getPropertyName(meeting.propertyId).toLowerCase();
          final customerName = _getUserName(meeting.customerId).toLowerCase();
          
          return titleMatches || propertyName.contains(query) || customerName.contains(query);
        }).toList();
      }

      // Apply Date Sort
      filtered.sort((a, b) {
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
          return dateB.compareTo(dateA); // DESC default
        }
      });

      _filteredMeetings = filtered;
    });
  }

  Widget _buildMeetingTypesList() {
    if (_meetingTypes.isEmpty) {
      return Container(
        height: 65,
        alignment: Alignment.center,
        child: Text(
          'No meeting types available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.greyColor,
              ),
        ),
      );
    }

    return SizedBox(
      height: 65,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _meetingTypes.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedTypeIndex;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final backgroundColor = isDark
              ? AppColors.darkCardBackground
              : AppColors.lightCardBackground;
          final textColor =
              isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

          return Container(
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 8,
              right: index == _meetingTypes.length - 1 ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTypeIndex = index;
                });
                _applyFilters();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandPrimary : backgroundColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.brandPrimary.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.brandPrimary.withOpacity(0.3)
                          : Colors.transparent,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _meetingTypes[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getUserName(String userId) {
    final userDetails = _userCache[userId];
    if (userDetails != null) {
      final firstName = userDetails['firstName'] ?? '';
      final lastName = userDetails['lastName'] ?? '';
      return '${firstName} ${lastName}'.trim();
    }
    return 'User $userId';
  }

  String _getPropertyName(String? propertyId) {
    if (propertyId == null || propertyId.isEmpty) return 'No Property';

    final propertyDetails = _propertyCache[propertyId];
    if (propertyDetails != null) {
      return propertyDetails['name'] ?? 'Property $propertyId';
    }
    return 'Property $propertyId';
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
      default:
        return CupertinoIcons.calendar;
    }
  }

  void _showDeleteDialog(MeetingSchedule meeting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meeting'),
        content: Text('Are you sure you want to delete "${meeting.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _meetingService.deleteMeeting(meeting.id);
                _loadMyScheduledMeetings();
                AppSnackBar.showSnackBar(
                  context,
                  'Success',
                  'Meeting deleted successfully',
                  ContentType.success,
                );
              } catch (e) {
                AppSnackBar.showSnackBar(
                  context,
                  'Error',
                  'Error deleting meeting: $e',
                  ContentType.failure,
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
          'My Scheduled Meetings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkWhiteText : AppColors.lightDarkText,
          ),
        ),
        actions: [
          // Create Meeting Button - Only visible to admin, sales, and executive roles
          if (_canCreateMeetings())
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPrimary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
            
                    final result =
                        await Navigator.pushNamed(context, '/create_meeting');
                    if (result == true) {
                      _loadMyScheduledMeetings();
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Create',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8), // Add spacing between buttons
          IconButton(
            icon: Icon(
              CupertinoIcons.refresh,
              color: AppColors.brandPrimary,
            ),
            onPressed: _loadMyScheduledMeetings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyScheduledMeetings,
        color: AppColors.brandPrimary,
        child: _isLoading
            ? _buildLoadingState()
            : _error != null
                ? _buildErrorState()
                : Column(
                    children: [
                      // Meeting types filter
                      _buildMeetingTypesList(),
                      
                      // Search and Sort Control
                      Container(
                        margin: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
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
                                    _applyFilters();
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
                                          _applyFilters();
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
                        child: _filteredMeetings.isEmpty
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
            height: 180,
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
              onPressed: _loadMyScheduledMeetings,
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
                CupertinoIcons.calendar,
                size: 64,
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Scheduled Meetings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You haven\'t scheduled any meetings yet',
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
                  _loadMyScheduledMeetings();
                }
              },
              icon: const Icon(CupertinoIcons.add),
              label: const Text('Schedule Meeting'),
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
          padding: const EdgeInsets.all(20),
          itemCount: _filteredMeetings.length,
          itemBuilder: (context, index) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
              color: _getStatusColor(meeting.getStatusName()).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
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
                    color: _getStatusColor(meeting.getStatusName()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    meeting.getStatusName(),
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

          // Meeting details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and Time Section
                _buildSectionHeader('Schedule', CupertinoIcons.calendar),
                const SizedBox(height: 12),
                _buildInfoRow(
                    'Date', meeting.meetingDate, CupertinoIcons.calendar),
                _buildInfoRow(
                    'Start Time', meeting.startTime, CupertinoIcons.time),
                if (meeting.endTime != null && meeting.endTime!.isNotEmpty)
                  _buildInfoRow(
                      'End Time', meeting.endTime!, CupertinoIcons.time_solid),
                if (meeting.duration != null && meeting.duration!.isNotEmpty)
                  _buildInfoRow(
                      'Duration', meeting.duration!, CupertinoIcons.clock),

                const SizedBox(height: 20),

                // Description and Notes Section
                if (meeting.description.isNotEmpty) ...[
                  _buildSectionHeader('Details', CupertinoIcons.text_bubble),
                  const SizedBox(height: 12),
                  _buildInfoRow('Description', meeting.description,
                      CupertinoIcons.text_bubble),
                ],

                if (meeting.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      'Notes', meeting.notes, CupertinoIcons.doc_text),
                ],

                const SizedBox(height: 20),

                // People and Property Section
                _buildSectionHeader(
                    'Participants & Property', CupertinoIcons.person_2),
                const SizedBox(height: 12),
                _buildInfoRow('Customer', _getUserName(meeting.customerId),
                    CupertinoIcons.person),
                if (meeting.propertyId != null &&
                    meeting.propertyId!.isNotEmpty)
                  _buildInfoRow(
                      'Property',
                      _getPropertyName(meeting.propertyId),
                      CupertinoIcons.home),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          AppSnackBar.showSnackBar(
                            context,
                            'Info',
                            'Edit functionality coming soon',
                            ContentType.help,
                          );
                        },
                        icon: const Icon(CupertinoIcons.pencil),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: AppColors.brandPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDeleteDialog(meeting),
                        icon: const Icon(CupertinoIcons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightDanger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
                const SizedBox(height: 4),
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
}
