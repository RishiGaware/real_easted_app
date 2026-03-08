class RentalBookingModel {
  final String id;
  final String bookingId;
  final String bookingStatus;
  final String propertyId;
  final String customerId;
  final String assignedSalespersonId;
  final DateTime startDate;
  final DateTime endDate;
  final int duration;
  final double monthlyRent;
  final double securityDeposit;
  final double maintenanceCharges;
  final double advanceRent;
  final int rentDueDate;
  final List<RentSchedule> rentSchedule;
  final bool isActive;
  final String createdByUserId;
  final String updatedByUserId;
  final bool published;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated fields
  final Map<String, dynamic>? property;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? assignedSalesperson;
  
  // Attachments
  final List<dynamic>? documents;

  RentalBookingModel({
    required this.id,
    required this.bookingId,
    required this.bookingStatus,
    required this.propertyId,
    required this.customerId,
    required this.assignedSalespersonId,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.maintenanceCharges,
    required this.advanceRent,
    required this.rentDueDate,
    required this.rentSchedule,
    required this.isActive,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.published,
    required this.createdAt,
    required this.updatedAt,
    this.property,
    this.customer,
    this.assignedSalesperson,
    this.documents,
  });

  factory RentalBookingModel.fromJson(Map<String, dynamic> json) {
    print('RentalBookingModel.fromJson parsing bookingId: ${json['bookingId']}');
    print('propertyId is Map: ${json['propertyId'] is Map}');
    print('propertyId type: ${json['propertyId'].runtimeType}');
    print('propertyId keys: ${json['propertyId'] is Map ? (json['propertyId'] as Map).keys : "N/A"}');
    
    return RentalBookingModel(
      id: json['_id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      bookingStatus: json['bookingStatus'] ?? '',
      propertyId: json['propertyId'] is String
          ? json['propertyId']
          : (json['propertyId']?['_id'] ?? ''),
      customerId: json['customerId'] is String
          ? json['customerId']
          : (json['customerId']?['_id'] ?? ''),
      assignedSalespersonId: json['assignedSalespersonId'] is String
          ? json['assignedSalespersonId']
          : (json['assignedSalespersonId']?['_id'] ?? ''),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      duration: json['duration'] ?? 0,
      monthlyRent: (json['monthlyRent'] ?? 0).toDouble(),
      securityDeposit: (json['securityDeposit'] ?? 0).toDouble(),
      maintenanceCharges: (json['maintenanceCharges'] ?? 0).toDouble(),
      advanceRent: (json['advanceRent'] ?? 0).toDouble(),
      rentDueDate: json['rentDueDate'] ?? 5,
      rentSchedule: (json['rentSchedule'] as List?)
              ?.map((e) => RentSchedule.fromJson(e))
              .toList() ??
          [],
      isActive: json['isActive'] ?? false,
      createdByUserId: json['createdByUserId'] ?? '',
      updatedByUserId: json['updatedByUserId'] ?? '',
      published: json['published'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      property: json['property'] ??
          (json['propertyId'] is Map ? json['propertyId'] : null),
      customer: json['customer'] ??
          (json['customerId'] is Map ? json['customerId'] : null),
      assignedSalesperson: json['assignedSalesperson'] ??
          (json['assignedSalespersonId'] is Map
              ? json['assignedSalespersonId']
              : null),
      documents: json['documents'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'bookingId': bookingId,
      'bookingStatus': bookingStatus,
      'propertyId': propertyId,
      'customerId': customerId,
      'assignedSalespersonId': assignedSalespersonId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'duration': duration,
      'monthlyRent': monthlyRent,
      'securityDeposit': securityDeposit,
      'maintenanceCharges': maintenanceCharges,
      'advanceRent': advanceRent,
      'rentDueDate': rentDueDate,
      'rentSchedule': rentSchedule.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'createdByUserId': createdByUserId,
      'updatedByUserId': updatedByUserId,
      'published': published,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'property': property,
      'customer': customer,
      'assignedSalesperson': assignedSalesperson,
      'documents': documents,
    };
  }
}

class RentSchedule {
  final String month;
  final int year;
  final int monthNumber;
  final DateTime dueDate;
  final double amount;
  final String status;
  final DateTime? paidDate;
  final double lateFees;
  final String? paymentId;
  final String responsiblePersonId;
  final String? updatedByUserId;
  final DateTime? updatedAt;

  RentSchedule({
    required this.month,
    required this.year,
    required this.monthNumber,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidDate,
    required this.lateFees,
    this.paymentId,
    required this.responsiblePersonId,
    this.updatedByUserId,
    this.updatedAt,
  });

  factory RentSchedule.fromJson(Map<String, dynamic> json) {
    return RentSchedule(
      month: json['month'] ?? '',
      year: json['year'] ?? 0,
      monthNumber: json['monthNumber'] ?? 0,
      dueDate: DateTime.parse(json['dueDate']),
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      paidDate:
          json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      lateFees: (json['lateFees'] ?? 0).toDouble(),
      paymentId: json['paymentId'],
      responsiblePersonId: json['responsiblePersonId'] ?? '',
      updatedByUserId: json['updatedByUserId'],
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'monthNumber': monthNumber,
      'dueDate': dueDate.toIso8601String(),
      'amount': amount,
      'status': status,
      'paidDate': paidDate?.toIso8601String(),
      'lateFees': lateFees,
      'paymentId': paymentId,
      'responsiblePersonId': responsiblePersonId,
      'updatedByUserId': updatedByUserId,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
