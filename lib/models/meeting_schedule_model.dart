class MeetingSchedule {
  final String id;
  final String title;
  final String description;
  final String meetingDate;
  final String startTime;
  final String? endTime;
  final String? duration;
  final dynamic status; // Can be String (ID) or Map (populated object)
  final String scheduledByUserId;
  final String customerId;
  final String? propertyId;
  final Map<String, dynamic>? scheduledByUser;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? propertyDetails;
  final String notes;
  final String createdByUserId;
  final String updatedByUserId;
  final bool published;
  final String? createdAt;
  final String? updatedAt;

  MeetingSchedule({
    required this.id,
    required this.title,
    required this.description,
    required this.meetingDate,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.status,
    required this.scheduledByUserId,
    required this.customerId,
    this.propertyId,
    this.scheduledByUser,
    this.customer,
    this.propertyDetails,
    required this.notes,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.published,
    this.createdAt,
    this.updatedAt,
  });

  factory MeetingSchedule.fromJson(Map<String, dynamic> json) {
    return MeetingSchedule(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      meetingDate: json['meetingDate'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'],
      duration: json['duration'],
      status: json['status'] ?? '',
      scheduledByUserId: json['scheduledByUserId'] is Map
          ? (json['scheduledByUserId']['_id'] ??
              json['scheduledByUserId']['id'] ??
              '')
          : (json['scheduledByUserId'] ?? ''),
      customerId: json['customerId'] is Map
          ? (json['customerId']['_id'] ?? json['customerId']['id'] ?? '')
          : (json['customerId'] ?? ''),
      propertyId: json['propertyId'] is Map
          ? (json['propertyId']['_id'] ?? json['propertyId']['id'] ?? '')
          : json['propertyId'],
      scheduledByUser: json['scheduledByUserId'] is Map ? json['scheduledByUserId'] : null,
      customer: json['customerId'] is Map ? json['customerId'] : null,
      propertyDetails: json['propertyId'] is Map ? json['propertyId'] : null,
      notes: json['notes'] ?? '',
      createdByUserId: json['createdByUserId'] ?? '',
      updatedByUserId: json['updatedByUserId'] ?? '',
      published: json['published'] ?? true,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'meetingDate': meetingDate,
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      'status': status,
      'scheduledByUserId': scheduledByUserId,
      'customerId': customerId,
      'propertyId': propertyId,
      'notes': notes,
      'createdByUserId': createdByUserId,
      'updatedByUserId': updatedByUserId,
      'published': published,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Helper method to get status name
  String getStatusName() {
    if (status is Map) {
      return status['name'] ?? '';
    }
    return status.toString();
  }
}
