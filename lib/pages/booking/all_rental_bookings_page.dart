import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/constants/role_utils.dart';
import 'package:inhabit_realties/models/booking/rental_booking_model.dart';
import 'package:inhabit_realties/services/booking/admin_booking_service.dart';
import 'package:inhabit_realties/pages/widgets/loader.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AllRentalBookingsPage extends StatefulWidget {
  const AllRentalBookingsPage({super.key});

  @override
  State<AllRentalBookingsPage> createState() => _AllRentalBookingsPageState();
}

class _AllRentalBookingsPageState extends State<AllRentalBookingsPage> {
  final AdminBookingService _bookingService = AdminBookingService();
  List<RentalBookingModel> _bookings = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _bookingService.getAllRentalBookings();

      // Check if data exists (API returns data directly without statusCode)
      if (response['data'] != null) {
        final List<dynamic> bookingsData = response['data'];
        final List<RentalBookingModel> bookings = bookingsData
            .map((json) => RentalBookingModel.fromJson(json))
            .toList();

        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load bookings';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  /// Confirm a rental booking by changing its status to ACTIVE
  Future<void> _confirmBooking(String bookingId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _bookingService.confirmRentalBooking(bookingId);

      if (response['data'] != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rental booking confirmed successfully!'),
            backgroundColor: AppColors.successColor(
                Theme.of(context).brightness == Brightness.dark),
          ),
        );

        // Reload bookings to show updated status
        await _loadBookings();
      } else {
        throw Exception(
            response['message'] ?? 'Failed to confirm rental booking');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming rental booking: $e'),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkDanger
              : AppColors.lightDanger,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<RentalBookingModel> get _filteredBookings {
    return _bookings.where((booking) {
      final matchesSearch = _searchQuery.isEmpty ||
          booking.bookingId
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (booking.property?['name'] ?? '')
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (booking.customer?['name'] ?? '')
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesStatus = _statusFilter == 'ALL' ||
          booking.bookingStatus.toUpperCase() == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  String _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return '#FFA500'; // Orange
      case 'ACTIVE':
        return '#4CAF50'; // Green
      case 'EXPIRED':
        return '#F44336'; // Red
      case 'CANCELLED':
        return '#9C27B0'; // Purple
      default:
        return '#757575'; // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('All Rental Bookings'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: cardColor,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by booking ID, property, or customer...',
                    prefixIcon: const Icon(CupertinoIcons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(CupertinoIcons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.darkBackground : Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Status Filter
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'ALL',
                            'PENDING',
                            'ACTIVE',
                            'EXPIRED',
                            'CANCELLED'
                          ]
                              .map((status) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(status),
                                      selected: _statusFilter == status,
                                      onSelected: (_) {
                                        setState(() {
                                          _statusFilter = status;
                                        });
                                      },
                                      backgroundColor: isDark
                                          ? AppColors.darkBackground
                                          : Colors.grey[200],
                                      selectedColor: isDark
                                          ? AppColors.darkPrimary
                                          : AppColors.brandPrimary,
                                      labelStyle: TextStyle(
                                        color: _statusFilter == status
                                            ? Colors.white
                                            : textColor,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bookings List
          Expanded(
            child: _isLoading
                ? const Center(child: Loader())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              size: 64,
                              color: Colors.orange[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadBookings,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredBookings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.house,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No rental bookings found',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty ||
                                    _statusFilter != 'ALL')
                                  Text(
                                    'Try adjusting your search or filters',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadBookings,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredBookings.length,
                              itemBuilder: (context, index) {
                                final booking = _filteredBookings[index];
                                return _buildBookingCard(
                                    booking, isDark, cardColor, textColor);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(RentalBookingModel booking, bool isDark,
      Color cardColor, Color textColor) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    final dateFormat = DateFormat('MMM dd, yyyy');
    final brandColor =
        isDark ? AppColors.brandSecondary : AppColors.brandPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking ID: ${booking.bookingId}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${DateFormat('MMM dd, yyyy').format(booking.createdAt)}',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: brandColor),
                    borderRadius: BorderRadius.circular(20),
                    color: brandColor.withOpacity(0.1),
                  ),
                  child: Text(
                    booking.bookingStatus.toUpperCase(),
                    style: TextStyle(
                      color: brandColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Property Info
            if (booking.property != null) ...[
              _buildInfoRow(
                  'Property', booking.property!['name']?.toString() ?? 'N/A', textColor),
              _buildInfoRow(
                  'Location',
                  '${booking.property!['propertyAddress']?['city'] ?? ''}, ${booking.property!['propertyAddress']?['state'] ?? ''}',
                  textColor),
            ] else if (booking.propertyId is Map) ...[
              _buildInfoRow(
                  'Property',
                  (booking.propertyId as Map<String, dynamic>)['name']?.toString() ?? 'N/A',
                  textColor),
              _buildInfoRow(
                  'Location',
                  '${(booking.propertyId as Map<String, dynamic>)['propertyAddress']?['city'] ?? ''}, ${(booking.propertyId as Map<String, dynamic>)['propertyAddress']?['state'] ?? ''}',
                  textColor),
            ] else ...[
              _buildInfoRow('Property', 'ID: ${booking.propertyId}', textColor),
            ],
            // Customer Info
            if (booking.customer != null) ...[
              _buildInfoRow(
                  'Customer', '${booking.customer!['firstName'] ?? ''} ${booking.customer!['lastName'] ?? ''}'.trim().isEmpty ? 'N/A' : '${booking.customer!['firstName'] ?? ''} ${booking.customer!['lastName'] ?? ''}'.trim(), textColor),
              _buildInfoRow(
                  'Phone', booking.customer!['phoneNumber']?.toString() ?? 'N/A', textColor),
            ] else if (booking.customerId is Map) ...[
              _buildInfoRow(
                  'Customer',
                  '${(booking.customerId as Map<String, dynamic>)['firstName'] ?? ''} ${(booking.customerId as Map<String, dynamic>)['lastName'] ?? ''}'.trim().isEmpty ? 'N/A' : '${(booking.customerId as Map<String, dynamic>)['firstName'] ?? ''} ${(booking.customerId as Map<String, dynamic>)['lastName'] ?? ''}'.trim(),
                  textColor),
              _buildInfoRow(
                  'Phone',
                  (booking.customerId as Map<String, dynamic>)['phoneNumber']?.toString() ??
                      'N/A',
                  textColor),
            ] else ...[
              _buildInfoRow('Customer', 'ID: ${booking.customerId}', textColor),
            ],
            // Salesperson Info
            if (booking.assignedSalesperson != null) ...[
              _buildInfoRow('Salesperson',
                  '${booking.assignedSalesperson!['firstName'] ?? ''} ${booking.assignedSalesperson!['lastName'] ?? ''}'.trim().isEmpty ? 'N/A' : '${booking.assignedSalesperson!['firstName'] ?? ''} ${booking.assignedSalesperson!['lastName'] ?? ''}'.trim(), textColor),
            ] else if (booking.assignedSalespersonId is Map) ...[
              _buildInfoRow(
                  'Salesperson',
                  '${(booking.assignedSalespersonId as Map<String, dynamic>)['firstName'] ?? ''} ${(booking.assignedSalespersonId as Map<String, dynamic>)['lastName'] ?? ''}'.trim().isEmpty ? 'N/A' : '${(booking.assignedSalespersonId as Map<String, dynamic>)['firstName'] ?? ''} ${(booking.assignedSalespersonId as Map<String, dynamic>)['lastName'] ?? ''}'.trim(),
                  textColor),
            ] else ...[
              _buildInfoRow('Salesperson',
                  'ID: ${booking.assignedSalespersonId}', textColor),
            ],
            const SizedBox(height: 12),
            // Rental Period
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.greyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rental Period',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Start Date',
                      dateFormat.format(booking.startDate), textColor),
                  _buildInfoRow('End Date', dateFormat.format(booking.endDate),
                      textColor),
                  _buildInfoRow(
                      'Duration', '${booking.duration} months', textColor),
                  _buildInfoRow('Rent Due Date',
                      '${booking.rentDueDate}th of month', textColor),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Financial Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.greyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Details',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Monthly Rent',
                      currencyFormat.format(booking.monthlyRent), textColor),
                  if (booking.securityDeposit > 0)
                    _buildInfoRow(
                        'Security Deposit',
                        currencyFormat.format(booking.securityDeposit),
                        textColor),
                  if (booking.maintenanceCharges > 0)
                    _buildInfoRow(
                        'Maintenance Charges',
                        currencyFormat.format(booking.maintenanceCharges),
                        textColor),
                  if (booking.advanceRent > 0)
                    _buildInfoRow('Advance Rent',
                        currencyFormat.format(booking.advanceRent), textColor),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showBookingDetails(context, booking),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(BuildContext context, RentalBookingModel booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('MMM dd, yyyy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rental Booking Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Overview Section
                    _buildSectionHeader('Overview', Icons.info_outline, Colors.blue),
                    _buildDetailRow('Booking ID', booking.bookingId, textColor),
                    _buildDetailRow('Status', booking.bookingStatus.toUpperCase(), textColor),
                    _buildDetailRow('Duration', '${booking.duration} months', textColor),
                    _buildDetailRow('Rent Due Date', '${booking.rentDueDate}th of month', textColor),

                    const SizedBox(height: 24),

                    // Property Details
                    _buildSectionHeader('Property Details', Icons.home_outlined, Colors.green),
                    _buildDetailRow('Name', booking.property?['name']?.toString() ?? 'N/A', textColor),
                    _buildDetailRow('Monthly Rent', currencyFormat.format(booking.monthlyRent), textColor),
                    _buildDetailRow('Location', '${booking.property?['propertyAddress']?['city'] ?? ''}, ${booking.property?['propertyAddress']?['state'] ?? ''}', textColor),

                    const SizedBox(height: 24),

                    // Customer Details
                    _buildSectionHeader('Customer Details', Icons.person_outline, Colors.purple),
                    _buildDetailRow('Name', '${booking.customer?['firstName'] ?? ''} ${booking.customer?['lastName'] ?? ''}'.trim().isEmpty ? 'N/A' : '${booking.customer?['firstName'] ?? ''} ${booking.customer?['lastName'] ?? ''}'.trim(), textColor),
                    _buildDetailRow('Email', booking.customer?['email']?.toString() ?? 'N/A', textColor),
                    _buildDetailRow('Phone', booking.customer?['phoneNumber']?.toString() ?? 'N/A', textColor),

                    const SizedBox(height: 24),

                    // Salesperson Details
                    _buildSectionHeader('Assigned Salesperson', Icons.badge_outlined, Colors.orange),
                    _buildDetailRow('Name', '${booking.assignedSalesperson?['firstName'] ?? ''} ${booking.assignedSalesperson?['lastName'] ?? ''}'.trim().isEmpty ? 'N/A' : '${booking.assignedSalesperson?['firstName'] ?? ''} ${booking.assignedSalesperson?['lastName'] ?? ''}'.trim(), textColor),
                    _buildDetailRow('Email', booking.assignedSalesperson?['email']?.toString() ?? 'N/A', textColor),
                    _buildDetailRow('Phone', booking.assignedSalesperson?['phoneNumber']?.toString() ?? 'N/A', textColor),

                    const SizedBox(height: 24),

                    // Financial Details
                    _buildSectionHeader('Financial Details', Icons.currency_rupee, Colors.teal),
                    _buildDetailRow('Monthly Rent', currencyFormat.format(booking.monthlyRent), textColor),
                    _buildDetailRow('Security Deposit', currencyFormat.format(booking.securityDeposit), textColor),
                    _buildDetailRow('Maintenance Charges', '${currencyFormat.format(booking.maintenanceCharges)}/month', textColor),
                    _buildDetailRow('Advance Rent', '${booking.advanceRent} months', textColor),

                    const SizedBox(height: 24),

                    // Lease Period
                    _buildSectionHeader('Lease Period', Icons.calendar_today, Colors.indigo),
                    _buildDetailRow('Start Date', dateFormat.format(booking.startDate), textColor),
                    _buildDetailRow('End Date', dateFormat.format(booking.endDate), textColor),

                    const SizedBox(height: 24),

                    // Rent Schedule
                    if (booking.rentSchedule.isNotEmpty) ...[
                      _buildSectionHeader('Rent Schedule', Icons.calendar_month, Colors.amber),
                      ...booking.rentSchedule.map((rent) => _buildRentScheduleRow(rent, isDark, textColor, currencyFormat, dateFormat)).toList(),
                      const SizedBox(height: 24),
                    ],

                    // Documents
                    _buildSectionHeader('Documents', Icons.attach_file, Colors.orangeAccent),
                    if (booking.documents != null && booking.documents!.isNotEmpty)
                      ...booking.documents!.map((doc) => _buildDocumentRow(doc, textColor)).toList()
                    else
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('No documents uploaded', style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor) {
    if (value.isEmpty || value == ', ') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentScheduleRow(RentSchedule rent, bool isDark, Color textColor, NumberFormat currencyFormat, DateFormat dateFormat) {
    final statusColor = rent.status.toUpperCase() == 'PAID'
        ? Colors.green
        : (rent.status.toUpperCase() == 'PENDING' ? Colors.orange : Colors.red);
        
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : (rent.status.toUpperCase() == 'PAID' ? Colors.green[50] : Colors.white),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Month ${rent.monthNumber}',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rent.status,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 6),
          Text(
            currencyFormat.format(rent.amount),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
          ),
          const SizedBox(height: 6),
          _buildDetailRow('Due Date', dateFormat.format(rent.dueDate), textColor),
          if (rent.status.toUpperCase() == 'PAID' && rent.paidDate != null)
            _buildDetailRow('Paid Date', dateFormat.format(rent.paidDate!), Colors.green),
          if (rent.lateFees > 0)
            _buildDetailRow('Late Fees', currencyFormat.format(rent.lateFees), Colors.red),
          if (rent.paymentId != null)
            _buildDetailRow('Payment ID', rent.paymentId!, textColor),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(dynamic document, Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docName = document['originalName']?.toString() ?? 'Document';
    final docType = document['documentType']?.toString() ?? 'OTHER';
    final mimeType = document['mimeType']?.toString() ?? '';
    final docUrl = document['documentUrl']?.toString() ?? document['url']?.toString() ?? document['fileUrl']?.toString();
    
    IconData iconData = Icons.insert_drive_file;
    if (mimeType.contains('pdf')) iconData = Icons.picture_as_pdf;
    else if (mimeType.contains('image')) iconData = Icons.image;
    else if (mimeType.contains('doc')) iconData = Icons.description;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: isDark ? Colors.grey[850] : Colors.white,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docName,
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  docType.replaceAll('_', ' '),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (docUrl != null && docUrl.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.blue),
              onPressed: () async {
                final uri = Uri.parse(docUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              tooltip: 'View Document',
            ),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.green),
              onPressed: () async {
                final uri = Uri.parse(docUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              tooltip: 'Download Document',
            ),
          ]
        ],
      ),
    );
  }
}
