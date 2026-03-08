import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/services/booking/bookingService.dart';
import 'package:inhabit_realties/pages/widgets/appSpinner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inhabit_realties/models/booking/rental_booking_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class MyRentalBookingsPage extends StatefulWidget {
  const MyRentalBookingsPage({super.key});

  @override
  State<MyRentalBookingsPage> createState() => _MyRentalBookingsPageState();
}

class _MyRentalBookingsPageState extends State<MyRentalBookingsPage> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  List<dynamic> _rentalBookings = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('currentUser');
      if (userJson != null) {
        final userData = Map<String, dynamic>.from(
            Map<String, dynamic>.from(json.decode(userJson)));
        _currentUserId = userData['_id'] ?? userData['id'];
      }

      if (_currentUserId != null) {
        // Load rental bookings only
        final rentalResponse =
            await _bookingService.getMyRentalBookings(_currentUserId!);
        setState(() {
          _rentalBookings = rentalResponse['data'] ?? [];
        });
      }
    } catch (e) {
      // Handle error silently for now
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackgroundColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Rental Bookings')),
        body: const Center(child: AppSpinner()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rental Bookings'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _buildRentalBookingsSection(
              context, cardBackgroundColor, textColor),
        ),
      ),
    );
  }

  Widget _buildRentalBookingsSection(
      BuildContext context, Color cardBackgroundColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.house_fill,
                  color: AppColors.brandTurnary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Rental Bookings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brandTurnary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_rentalBookings.length}',
                    style: TextStyle(
                      color: AppColors.brandTurnary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_rentalBookings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.house,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No rental bookings found',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _rentalBookings.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _buildRentalBookingCard(context, _rentalBookings[index]),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRentalBookingCard(BuildContext context, dynamic rawBooking) {
    final booking = RentalBookingModel.fromJson(rawBooking);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor = isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final brandColor = isDark ? AppColors.brandSecondary : AppColors.brandPrimary;

    return InkWell(
      onTap: () {
        _showBookingDetails(context, booking);
      },
      child: Container(
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
                          'Booking ID: ${booking.bookingId ?? 'N/A'}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${dateFormat.format(booking.createdAt)}',
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: brandColor),
                      borderRadius: BorderRadius.circular(20),
                      color: brandColor.withOpacity(0.1),
                    ),
                    child: Text(
                      booking.bookingStatus?.toUpperCase() ?? 'PENDING',
                      style: TextStyle(
                        color: brandColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Property Info
              if (booking.property != null) ...[
                _buildInfoRow('Property', booking.property!['name']?.toString() ?? 'N/A', textColor),
                _buildInfoRow('Location', '${booking.property!['propertyAddress']?['city'] ?? ''}, ${booking.property!['propertyAddress']?['state'] ?? ''}', textColor),
              ] else if (booking.propertyId is Map) ...[
                _buildInfoRow('Property', (booking.propertyId as Map<String, dynamic>)['name']?.toString() ?? 'N/A', textColor),
                _buildInfoRow('Location', '${(booking.propertyId as Map<String, dynamic>)['propertyAddress']?['city'] ?? ''}, ${(booking.propertyId as Map<String, dynamic>)['propertyAddress']?['state'] ?? ''}', textColor),
              ] else ...[
                _buildInfoRow('Property', 'ID: ${booking.propertyId}', textColor),
              ],
              // Customer Info
              if (booking.customer != null) ...[
                _buildInfoRow('Customer', '${booking.customer!['firstName'] ?? ''} ${booking.customer!['lastName'] ?? ''}'.trim().isEmpty ? 'N/A' : '${booking.customer!['firstName'] ?? ''} ${booking.customer!['lastName'] ?? ''}'.trim(), textColor),
                _buildInfoRow('Phone', booking.customer!['phoneNumber']?.toString() ?? 'N/A', textColor),
              ] else if (booking.customerId is Map) ...[
                _buildInfoRow('Customer', '${(booking.customerId as Map<String, dynamic>)['firstName'] ?? ''} ${(booking.customerId as Map<String, dynamic>)['lastName'] ?? ''}'.trim().isEmpty ? 'N/A' : '${(booking.customerId as Map<String, dynamic>)['firstName'] ?? ''} ${(booking.customerId as Map<String, dynamic>)['lastName'] ?? ''}'.trim(), textColor),
                _buildInfoRow('Phone', (booking.customerId as Map<String, dynamic>)['phoneNumber']?.toString() ?? 'N/A', textColor),
              ] else ...[
                _buildInfoRow('Customer', 'ID: ${booking.customerId}', textColor),
              ],
              // Salesperson Info
              if (booking.assignedSalesperson != null) ...[
                _buildInfoRow('Salesperson', '${booking.assignedSalesperson!['firstName'] ?? ''} ${booking.assignedSalesperson!['lastName'] ?? ''}'.trim().isEmpty ? 'N/A' : '${booking.assignedSalesperson!['firstName'] ?? ''} ${booking.assignedSalesperson!['lastName'] ?? ''}'.trim(), textColor),
              ] else if (booking.assignedSalespersonId is Map) ...[
                _buildInfoRow('Salesperson', '${(booking.assignedSalespersonId as Map<String, dynamic>)['firstName'] ?? ''} ${(booking.assignedSalespersonId as Map<String, dynamic>)['lastName'] ?? ''}'.trim().isEmpty ? 'N/A' : '${(booking.assignedSalespersonId as Map<String, dynamic>)['firstName'] ?? ''} ${(booking.assignedSalespersonId as Map<String, dynamic>)['lastName'] ?? ''}'.trim(), textColor),
              ] else ...[
                _buildInfoRow('Salesperson', 'ID: ${booking.assignedSalespersonId}', textColor),
              ],
              const SizedBox(height: 12),
              // Rental Period
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.greyColor.withOpacity(0.1),
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
                    _buildInfoRow('Start Date', dateFormat.format(booking.startDate), textColor),
                    _buildInfoRow('End Date', dateFormat.format(booking.endDate), textColor),
                    _buildInfoRow('Duration', '${booking.duration} months', textColor),
                    _buildInfoRow('Rent Due Date', '${booking.rentDueDate}th of month', textColor),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Financial Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.greyColor.withOpacity(0.1),
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
                    _buildInfoRow('Monthly Rent', currencyFormat.format(booking.monthlyRent), textColor),
                    if (booking.securityDeposit > 0)
                      _buildInfoRow('Security Deposit', currencyFormat.format(booking.securityDeposit), textColor),
                    if (booking.maintenanceCharges > 0)
                      _buildInfoRow('Maintenance Charges', currencyFormat.format(booking.maintenanceCharges), textColor),
                    if (booking.advanceRent > 0)
                      _buildInfoRow('Advance Rent', currencyFormat.format(booking.advanceRent), textColor),
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    if (value.isEmpty) return const SizedBox.shrink();
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

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
      case 'CONFIRMED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'EXPIRED':
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
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
