import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/services/booking/bookingService.dart';
import 'package:inhabit_realties/pages/widgets/appSpinner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:inhabit_realties/models/booking/purchase_booking_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class MyPurchaseBookingsPage extends StatefulWidget {
  const MyPurchaseBookingsPage({super.key});

  @override
  State<MyPurchaseBookingsPage> createState() => _MyPurchaseBookingsPageState();
}

class _MyPurchaseBookingsPageState extends State<MyPurchaseBookingsPage> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  List<dynamic> _purchaseBookings = [];
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
        // Load purchase bookings only
        final purchaseResponse =
            await _bookingService.getMyPurchaseBookings(_currentUserId!);
        setState(() {
          _purchaseBookings = purchaseResponse['data'] ?? [];
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
        appBar: AppBar(title: const Text('My Purchase Bookings')),
        body: const Center(child: AppSpinner()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Purchase Bookings'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _buildPurchaseBookingsSection(
              context, cardBackgroundColor, textColor),
        ),
      ),
    );
  }

  Widget _buildPurchaseBookingsSection(
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
                  CupertinoIcons.bag_fill,
                  color: AppColors.brandSecondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Purchase Bookings',
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
                    color: AppColors.brandSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_purchaseBookings.length}',
                    style: TextStyle(
                      color: AppColors.brandSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_purchaseBookings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.bag,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No purchase bookings found',
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
              itemCount: _purchaseBookings.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _buildPurchaseBookingCard(context, _purchaseBookings[index]),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPurchaseBookingCard(BuildContext context, dynamic rawBooking) {
    final booking = PurchaseBookingModel.fromJson(rawBooking);
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
              _buildInfoRow('Property', booking.property?['name']?.toString() ?? 'ID: ${booking.propertyId}', textColor),
              if (booking.property?['propertyAddress'] != null)
                _buildInfoRow('Location', '${booking.property!['propertyAddress']?['city'] ?? ''}, ${booking.property!['propertyAddress']?['state'] ?? ''}', textColor),

              // Customer Info
              _buildInfoRow('Customer', '${booking.customer?['firstName'] ?? ''} ${booking.customer?['lastName'] ?? ''}'.trim().isEmpty ? 'ID: ${booking.customerId}' : '${booking.customer?['firstName'] ?? ''} ${booking.customer?['lastName'] ?? ''}'.trim(), textColor),
              _buildInfoRow('Phone', booking.customer?['phoneNumber']?.toString() ?? 'N/A', textColor),

              // Salesperson Info
              _buildInfoRow('Salesperson', '${booking.assignedSalesperson?['firstName'] ?? ''} ${booking.assignedSalesperson?['lastName'] ?? ''}'.trim().isEmpty ? 'ID: ${booking.assignedSalespersonId}' : '${booking.assignedSalesperson?['firstName'] ?? ''} ${booking.assignedSalesperson?['lastName'] ?? ''}'.trim(), textColor),
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
                    _buildInfoRow('Total Value', currencyFormat.format(booking.totalPropertyValue), textColor),
                    _buildInfoRow('Down Payment', currencyFormat.format(booking.downPayment), textColor),
                    if (booking.loanAmount > 0)
                      _buildInfoRow('Loan Amount', currencyFormat.format(booking.loanAmount), textColor),
                    _buildInfoRow('Payment Terms', booking.paymentTerms ?? 'N/A', textColor),
                    if (booking.installmentCount > 0)
                      _buildInfoRow('Installments', '${booking.installmentCount} months', textColor),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Action Button
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

  void _showBookingDetails(BuildContext context, PurchaseBookingModel booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

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
                      'Purchase Booking Details',
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
                    _buildDetailRow('Booking ID', booking.bookingId ?? 'N/A', textColor),
                    _buildDetailRow('Status', booking.bookingStatus ?? 'N/A', textColor),
                    _buildDetailRow('Created', DateFormat('MMM dd, yyyy').format(booking.createdAt), textColor),

                    const SizedBox(height: 24),

                    // Property Booking Form Details
                    if (booking.developer != null ||
                        booking.channelPartnerName != null ||
                        booking.projectName != null ||
                        booking.location != null ||
                        booking.tcfNumber != null) ...[
                      _buildSectionHeader('Property Booking Form', Icons.content_paste, Colors.blue),
                      _buildDetailRow('Developer', booking.developer ?? '', textColor),
                      _buildDetailRow('Channel Partner', booking.channelPartnerName ?? '', textColor),
                      _buildDetailRow('Project Name', booking.projectName ?? '', textColor),
                      _buildDetailRow('Location', booking.location ?? '', textColor),
                      _buildDetailRow('TCF Number', booking.tcfNumber ?? '', textColor),
                      const SizedBox(height: 24),
                    ],

                    // Property Details
                    _buildSectionHeader('Property Details', Icons.home_outlined, Colors.green),
                    _buildDetailRow('Property Name', booking.property?['name']?.toString() ?? 'N/A', textColor),
                    if (booking.property?['price'] != null)
                      _buildDetailRow('Price', currencyFormat.format(booking.property!['price']), textColor),
                    _buildDetailRow('Flat / Plot No.', booking.flatNo ?? '', textColor),
                    _buildDetailRow('Tower / Wing', booking.towerWing ?? '', textColor),
                    _buildDetailRow('Floor', booking.floorNo ?? '', textColor),
                    _buildDetailRow('Number of Balconies', booking.balconies ?? '', textColor),
                    _buildDetailRow('Type', booking.propertyType == 'Other' ? (booking.propertyTypeOther ?? '') : (booking.propertyType ?? ''), textColor),
                    _buildDetailRow('Carpet Area', booking.carpetArea ?? '', textColor),
                    _buildDetailRow('Facing', booking.facing ?? '', textColor),
                    _buildDetailRow('Parking No.', booking.parkingNo ?? '', textColor),
                    _buildDetailRow('Special Features', booking.specialFeatures ?? '', textColor),
                    _buildDetailRow('Other Details', booking.otherDetails ?? '', textColor),

                    const SizedBox(height: 24),

                    // Customer Details
                    _buildSectionHeader('Customer Details', Icons.person_outline, Colors.purple),
                    _buildDetailRow('Name', '${booking.customer?['firstName'] ?? ''} ${booking.customer?['lastName'] ?? ''}'.trim().isEmpty ? 'N/A' : '${booking.customer?['firstName'] ?? ''} ${booking.customer?['lastName'] ?? ''}'.trim(), textColor),
                    _buildDetailRow('Email', booking.customer?['email']?.toString() ?? 'N/A', textColor),
                    _buildDetailRow('Phone', booking.customer?['phoneNumber']?.toString() ?? 'N/A', textColor),

                    const SizedBox(height: 24),

                    // Salesperson Details
                    _buildSectionHeader('Assigned Salesperson', Icons.badge_outlined, Colors.brown),
                    _buildDetailRow('Name', '${booking.assignedSalesperson?['firstName'] ?? ''} ${booking.assignedSalesperson?['lastName'] ?? ''}'.trim().isEmpty ? 'N/A' : '${booking.assignedSalesperson?['firstName'] ?? ''} ${booking.assignedSalesperson?['lastName'] ?? ''}'.trim(), textColor),
                    _buildDetailRow('Email', booking.assignedSalesperson?['email']?.toString() ?? 'N/A', textColor),
                    _buildDetailRow('Phone', booking.assignedSalesperson?['phoneNumber']?.toString() ?? 'N/A', textColor),

                    const SizedBox(height: 24),

                    // Buyer Details
                    if (booking.buyerFullName != null ||
                        booking.buyerAddress != null ||
                        booking.buyerCityPin != null ||
                        booking.buyerMobileNo != null ||
                        booking.buyerEmailId != null ||
                        booking.buyerAadharNo != null ||
                        booking.buyerPanNo != null) ...[
                      _buildSectionHeader('Buyer Details', Icons.receipt_long_outlined, Colors.green),
                      _buildDetailRow('Full Name', booking.buyerFullName ?? '', textColor),
                      _buildDetailRow('Address', booking.buyerAddress ?? '', textColor),
                      _buildDetailRow('City / PIN', booking.buyerCityPin ?? '', textColor),
                      _buildDetailRow('Mobile No.', booking.buyerMobileNo ?? '', textColor),
                      _buildDetailRow('Email ID', booking.buyerEmailId ?? '', textColor),
                      _buildDetailRow('Aadhar No.', booking.buyerAadharNo ?? '', textColor),
                      _buildDetailRow('PAN No.', booking.buyerPanNo ?? '', textColor),
                      const SizedBox(height: 24),
                    ],

                    // Financial Details
                    _buildSectionHeader('Financial Details', Icons.currency_rupee, Colors.teal),
                    _buildDetailRow('Total Cost', currencyFormat.format(booking.totalPropertyValue), textColor),
                    if (booking.bookingAmount != null)
                      _buildDetailRow('Booking Amount', currencyFormat.format(booking.bookingAmount), textColor),
                    _buildDetailRow('Down Payment', currencyFormat.format(booking.downPayment), textColor),
                    _buildDetailRow('Payment Mode', booking.paymentMode ?? '', textColor),
                    _buildDetailRow('Finance Mode', booking.financeMode ?? '', textColor),
                    if (booking.totalEmi != null)
                      _buildDetailRow('Total EMI', currencyFormat.format(booking.totalEmi), textColor),
                    if (booking.transactionChequeNo != null)
                      _buildDetailRow('Transaction / Cheque No.', booking.transactionChequeNo ?? '', textColor),
                    if (booking.bookingDate != null)
                      _buildDetailRow('Booking Date', DateFormat('MMM dd, yyyy').format(booking.bookingDate!), textColor),
                    
                    if (booking.loanAmount > 0)
                      _buildDetailRow('Loan Amount', currencyFormat.format(booking.loanAmount), textColor),
                    if (booking.isFinanced) ...[
                      _buildDetailRow('Bank Name', booking.bankName ?? 'N/A', textColor),
                      _buildDetailRow('Loan Tenure', '${booking.loanTenure} months', textColor),
                      _buildDetailRow('Interest Rate', '${booking.interestRate}%', textColor),
                      _buildDetailRow('EMI Amount', currencyFormat.format(booking.emiAmount), textColor),
                    ],

                    const SizedBox(height: 24),

                    // Payment Terms
                    _buildSectionHeader('Payment Terms', Icons.request_quote_outlined, Colors.indigo),
                    _buildDetailRow('Payment Terms', booking.paymentTerms ?? 'N/A', textColor),
                    _buildDetailRow('Installments', '${booking.installmentCount} installments', textColor),

                    const SizedBox(height: 24),

                    // Installment Schedule
                    if (booking.installmentSchedule.isNotEmpty) ...[
                      _buildSectionHeader('Installment Schedule', Icons.calendar_month, Colors.amber),
                      ...booking.installmentSchedule.map((inst) => _buildInstallmentRow(inst, isDark, textColor, currencyFormat)).toList(),
                      const SizedBox(height: 24),
                    ],

                    // Documents
                    _buildSectionHeader('Documents', Icons.attach_file, Colors.orange),
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
    if (value.isEmpty) return const SizedBox.shrink();
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

  Widget _buildInstallmentRow(InstallmentSchedule inst, bool isDark, Color textColor, NumberFormat currencyFormat) {
    final statusColor = inst.status.toUpperCase() == 'PAID'
        ? Colors.green
        : (inst.status.toUpperCase() == 'PENDING' ? Colors.orange : Colors.red);
        
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : (inst.status.toUpperCase() == 'PAID' ? Colors.green[50] : Colors.white),
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
                'Installment ${inst.installmentNumber}',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  inst.status,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 6),
          Text(
            currencyFormat.format(inst.amount),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text('Due: ${DateFormat('MMM dd, yyyy').format(inst.dueDate)}', style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.8))),
          if (inst.paidDate != null)
            Text('Paid: ${DateFormat('MMM dd, yyyy').format(inst.paidDate!)}', style: const TextStyle(fontSize: 12, color: Colors.green)),
          if (inst.lateFees > 0)
            Text('Late Fees: ${currencyFormat.format(inst.lateFees)}', style: const TextStyle(fontSize: 12, color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(dynamic document, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_outlined, color: Colors.blue[300]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document['title'] ?? document['documentType'] ?? 'Document',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                ),
                if (document['originalName'] != null)
                  Text(
                    document['originalName'],
                    style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (document['documentUrl'] != null || document['url'] != null || document['fileUrl'] != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'View Document',
                  icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.blue),
                  onPressed: () async {
                    final url = document['documentUrl'] ?? document['url'] ?? document['fileUrl'];
                    if (url != null) {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Download Document',
                  icon: const Icon(Icons.download, color: Colors.blue),
                  onPressed: () async {
                    final url = document['documentUrl'] ?? document['url'] ?? document['fileUrl'];
                    if (url != null) {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
