class PurchaseBookingModel {
  final String id;
  final String bookingId;
  final String bookingStatus;
  final String propertyId;
  final String customerId;
  final String assignedSalespersonId;
  final double totalPropertyValue;
  final double downPayment;
  final double loanAmount;
  final bool isFinanced;
  final String? bankName;
  final int loanTenure;
  final double interestRate;
  final double emiAmount;
  final String paymentTerms;
  final int installmentCount;
  final List<InstallmentSchedule> installmentSchedule;
  final bool isActive;
  final DateTime? completionDate;
  final String createdByUserId;
  final String updatedByUserId;
  final bool published;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Property Booking Form Data
  final String? developer;
  final String? channelPartnerName;
  final String? projectName;
  final String? location;
  final String? tcfNumber;

  // Buyer Data
  final String? buyerFullName;
  final String? buyerAddress;
  final String? buyerCityPin;
  final String? buyerMobileNo;
  final String? buyerEmailId;
  final String? buyerAadharNo;
  final String? buyerPanNo;

  // Detailed Property Stats
  final String? flatNo;
  final String? towerWing;
  final String? floorNo;
  final String? balconies;
  final String? propertyType;
  final String? propertyTypeOther;
  final String? carpetArea;
  final String? facing;
  final String? parkingNo;
  final String? specialFeatures;
  final String? otherDetails;

  // Financial Granularity
  final double? bookingAmount;
  final String? paymentMode;
  final String? financeMode;
  final double? totalEmi;
  final String? transactionChequeNo;
  final DateTime? bookingDate;

  // Populated fields
  final Map<String, dynamic>? property;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? assignedSalesperson;
  final List<dynamic>? documents;

  PurchaseBookingModel({
    required this.id,
    required this.bookingId,
    required this.bookingStatus,
    required this.propertyId,
    required this.customerId,
    required this.assignedSalespersonId,
    required this.totalPropertyValue,
    required this.downPayment,
    required this.loanAmount,
    required this.isFinanced,
    this.bankName,
    required this.loanTenure,
    required this.interestRate,
    required this.emiAmount,
    required this.paymentTerms,
    required this.installmentCount,
    required this.installmentSchedule,
    required this.isActive,
    this.completionDate,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.published,
    required this.createdAt,
    required this.updatedAt,
    this.developer,
    this.channelPartnerName,
    this.projectName,
    this.location,
    this.tcfNumber,
    this.buyerFullName,
    this.buyerAddress,
    this.buyerCityPin,
    this.buyerMobileNo,
    this.buyerEmailId,
    this.buyerAadharNo,
    this.buyerPanNo,
    this.flatNo,
    this.towerWing,
    this.floorNo,
    this.balconies,
    this.propertyType,
    this.propertyTypeOther,
    this.carpetArea,
    this.facing,
    this.parkingNo,
    this.specialFeatures,
    this.otherDetails,
    this.bookingAmount,
    this.paymentMode,
    this.financeMode,
    this.totalEmi,
    this.transactionChequeNo,
    this.bookingDate,
    this.property,
    this.customer,
    this.assignedSalesperson,
    this.documents,
  });

  factory PurchaseBookingModel.fromJson(Map<String, dynamic> json) {
    return PurchaseBookingModel(
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
      totalPropertyValue: (json['totalPropertyValue'] ?? 0).toDouble(),
      downPayment: (json['downPayment'] ?? 0).toDouble(),
      loanAmount: (json['loanAmount'] ?? 0).toDouble(),
      isFinanced: json['isFinanced'] ?? false,
      bankName: json['bankName'],
      loanTenure: json['loanTenure'] ?? 0,
      interestRate: (json['interestRate'] ?? 0).toDouble(),
      emiAmount: (json['emiAmount'] ?? 0).toDouble(),
      paymentTerms: json['paymentTerms'] ?? '',
      installmentCount: json['installmentCount'] ?? 0,
      installmentSchedule: (json['installmentSchedule'] as List?)
              ?.map((e) => InstallmentSchedule.fromJson(e))
              .toList() ??
          [],
      isActive: json['isActive'] ?? false,
      completionDate: json['completionDate'] != null
          ? DateTime.parse(json['completionDate'])
          : null,
      createdByUserId: json['createdByUserId'] ?? '',
      updatedByUserId: json['updatedByUserId'] ?? '',
      published: json['published'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      developer: json['developer'],
      channelPartnerName: json['channelPartnerName'],
      projectName: json['projectName'],
      location: json['location'],
      tcfNumber: json['tcfNumber'],
      buyerFullName: json['buyerFullName'],
      buyerAddress: json['buyerAddress'],
      buyerCityPin: json['buyerCityPin'],
      buyerMobileNo: json['buyerMobileNo'],
      buyerEmailId: json['buyerEmailId'],
      buyerAadharNo: json['buyerAadharNo'],
      buyerPanNo: json['buyerPanNo'],
      flatNo: json['flatNo'],
      towerWing: json['towerWing'],
      floorNo: json['floorNo']?.toString(), // Could be int or string
      balconies: json['balconies']?.toString(),
      propertyType: json['propertyType'],
      propertyTypeOther: json['propertyTypeOther'],
      carpetArea: json['carpetArea'],
      facing: json['facing'],
      parkingNo: json['parkingNo'],
      specialFeatures: json['specialFeatures'],
      otherDetails: json['otherDetails'],
      bookingAmount: json['bookingAmount']?.toDouble(),
      paymentMode: json['paymentMode'],
      financeMode: json['financeMode'],
      totalEmi: json['totalEmi']?.toDouble(),
      transactionChequeNo: json['transactionChequeNo'],
      bookingDate: json['bookingDate'] != null ? DateTime.parse(json['bookingDate']) : null,
      property: json['property'] ?? (json['propertyId'] is Map ? json['propertyId'] : null),
      customer: json['customer'] ?? (json['customerId'] is Map ? json['customerId'] : null),
      assignedSalesperson: json['assignedSalesperson'] ?? (json['assignedSalespersonId'] is Map ? json['assignedSalespersonId'] : null),
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
      'totalPropertyValue': totalPropertyValue,
      'downPayment': downPayment,
      'loanAmount': loanAmount,
      'isFinanced': isFinanced,
      'bankName': bankName,
      'loanTenure': loanTenure,
      'interestRate': interestRate,
      'emiAmount': emiAmount,
      'paymentTerms': paymentTerms,
      'installmentCount': installmentCount,
      'installmentSchedule':
          installmentSchedule.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'completionDate': completionDate?.toIso8601String(),
      'createdByUserId': createdByUserId,
      'updatedByUserId': updatedByUserId,
      'published': published,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'developer': developer,
      'channelPartnerName': channelPartnerName,
      'projectName': projectName,
      'location': location,
      'tcfNumber': tcfNumber,
      'buyerFullName': buyerFullName,
      'buyerAddress': buyerAddress,
      'buyerCityPin': buyerCityPin,
      'buyerMobileNo': buyerMobileNo,
      'buyerEmailId': buyerEmailId,
      'buyerAadharNo': buyerAadharNo,
      'buyerPanNo': buyerPanNo,
      'flatNo': flatNo,
      'towerWing': towerWing,
      'floorNo': floorNo,
      'balconies': balconies,
      'propertyType': propertyType,
      'propertyTypeOther': propertyTypeOther,
      'carpetArea': carpetArea,
      'facing': facing,
      'parkingNo': parkingNo,
      'specialFeatures': specialFeatures,
      'otherDetails': otherDetails,
      'bookingAmount': bookingAmount,
      'paymentMode': paymentMode,
      'financeMode': financeMode,
      'totalEmi': totalEmi,
      'transactionChequeNo': transactionChequeNo,
      'bookingDate': bookingDate?.toIso8601String(),
      'property': property,
      'customer': customer,
      'assignedSalesperson': assignedSalesperson,
      'documents': documents,
    };
  }
}

class InstallmentSchedule {
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final String status;
  final DateTime? paidDate;
  final double lateFees;
  final String? paymentId;
  final dynamic responsiblePersonId; // Changed to dynamic to support map with firstName
  final String? updatedByUserId;
  final DateTime? updatedAt;

  InstallmentSchedule({
    required this.installmentNumber,
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

  factory InstallmentSchedule.fromJson(Map<String, dynamic> json) {
    return InstallmentSchedule(
      installmentNumber: json['installmentNumber'] ?? 0,
      dueDate: DateTime.parse(json['dueDate']),
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      paidDate:
          json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      lateFees: (json['lateFees'] ?? 0).toDouble(),
      paymentId: json['paymentId'],
      responsiblePersonId: json['responsiblePersonId'],
      updatedByUserId: json['updatedByUserId'],
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'installmentNumber': installmentNumber,
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
