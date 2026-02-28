import 'package:inhabit_realties/models/lead/ReferenceSourceModel.dart';

class LeadsModel {
  final String id;
  final String
      userId; // lead user id if not then register it first then go further
  final Map<String, dynamic>? userData; // Store the full user object
  final String leadDesignation;
  final String leadInterestedPropertyId;
  final String leadStatus; // required
  final ReferenceSourceModel? referanceFrom; // optional
  final String followUpStatus; // required
  final String? referredByUserId;
  final String? referredByUserFirstName; // optional
  final String? referredByUserLastName; // optional
  final String? referredByUserEmail; // optional
  final String? referredByUserPhoneNumber; // optional
  final String? referredByUserDesignation; // optional
  final String assignedByUserId;
  final String assignedToUserId;
  final String? leadAltEmail; // optional
  final String? leadAltPhoneNumber; // optional
  final String? leadLandLineNumber; // optional
  final String? leadWebsite; // optional
  final String? note; // optional
  final String createdByUserId; // required
  final String updatedByUserId; // required
  final bool published;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeadsModel({
    required this.id,
    required this.userId,
    this.userData,
    required this.leadDesignation,
    required this.leadInterestedPropertyId,
    required this.leadStatus,
    this.referanceFrom,
    required this.followUpStatus,
    this.referredByUserId,
    this.referredByUserFirstName,
    this.referredByUserLastName,
    this.referredByUserEmail,
    this.referredByUserPhoneNumber,
    this.referredByUserDesignation,
    required this.assignedByUserId,
    required this.assignedToUserId,
    this.leadAltEmail,
    this.leadAltPhoneNumber,
    this.leadLandLineNumber,
    this.leadWebsite,
    this.note,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.published,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper methods to extract user information
  String get leadFirstName {
    if (userData != null && userData!.containsKey('firstName')) {
      return userData!['firstName'] ?? '';
    }
    return '';
  }

  String get leadLastName {
    if (userData != null && userData!.containsKey('lastName')) {
      return userData!['lastName'] ?? '';
    }
    return '';
  }

  String get leadEmail {
    if (userData != null && userData!.containsKey('email')) {
      return userData!['email'] ?? '';
    }
    return '';
  }

  String get leadPhoneNumber {
    if (userData != null && userData!.containsKey('phoneNumber')) {
      return userData!['phoneNumber'] ?? '';
    }
    return '';
  }

  String? get profilePictureUrl {
    if (userData != null && userData!.containsKey('profilePicture')) {
      final profilePicture = userData!['profilePicture'];
      if (profilePicture is Map && profilePicture.containsKey('url')) {
        return profilePicture['url'];
      }
    }
    return null;
  }

  String get fullName {
    final firstName = leadFirstName;
    final lastName = leadLastName;
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    }
    return 'Lead';
  }

  /// Helper method to extract ObjectId from MongoDB format
  static String _extractObjectId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map && value.containsKey('\$oid')) {
      return value['\$oid'] ?? '';
    }
    // Handle complex objects that have an _id field
    if (value is Map && value.containsKey('_id')) {
      return _extractObjectId(value['_id']);
    }
    return value.toString();
  }

  /// Helper method to extract string value from complex objects
  static String _extractStringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      // Try to extract name field first
      if (value.containsKey('name')) {
        return value['name'] ?? '';
      }
      // Try to extract enum field
      if (value.containsKey('enum')) {
        final enumValue = value['enum'];
        if (enumValue is List && enumValue.isNotEmpty) {
          return enumValue.first.toString();
        }
        return '';
      }
      // Try to extract _id field
      if (value.containsKey('_id')) {
        return _extractObjectId(value['_id']);
      }
    }
    return value.toString();
  }

  /// Helper method to extract date from MongoDB format
  static DateTime _extractDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    if (value is Map && value.containsKey('\$date')) {
      final dateValue = value['\$date'];
      if (dateValue is Map && dateValue.containsKey('\$numberLong')) {
        final timestamp = int.tryParse(dateValue['\$numberLong'] ?? '0') ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
    return DateTime.now();
  }

  /// Deserialize from JSON
  factory LeadsModel.fromJson(Map<String, dynamic> json) {
    try {
      // Handle userId field - it can be either a string ID or a full user object
      String userId = '';
      Map<String, dynamic>? userData;

      if (json['userId'] != null) {
        if (json['userId'] is String) {
          userId = json['userId'];
        } else if (json['userId'] is Map) {
          userData = Map<String, dynamic>.from(json['userId']);
          userId = _extractObjectId(json['userId']['_id']);
        }
      }

      return LeadsModel(
        id: _extractObjectId(json['_id']),
        userId: userId,
        userData: userData,
        leadDesignation: _extractStringValue(json['leadDesignation']),
        leadInterestedPropertyId:
            _extractObjectId(json['leadInterestedPropertyId']),
        leadStatus: _extractStringValue(json['leadStatus']),
        referanceFrom: json['referanceFrom'] != null
            ? ReferenceSourceModel.fromJson(json['referanceFrom'])
            : null,
        followUpStatus: _extractStringValue(json['followUpStatus']),
        referredByUserId: _extractObjectId(json['referredByUserId']),
        referredByUserFirstName: json['referredByUserFirstName'],
        referredByUserLastName: json['referredByUserLastName'],
        referredByUserEmail: json['referredByUserEmail'],
        referredByUserPhoneNumber: json['referredByUserPhoneNumber'],
        referredByUserDesignation: json['referredByUserDesignation'],
        assignedByUserId: _extractObjectId(json['assignedByUserId']),
        assignedToUserId: _extractObjectId(json['assignedToUserId']),
        leadAltEmail: json['leadAltEmail'],
        leadAltPhoneNumber: json['leadAltPhoneNumber'],
        leadLandLineNumber: json['leadLandLineNumber'],
        leadWebsite: json['leadWebsite'],
        note: json['note'],
        createdByUserId: _extractObjectId(json['createdByUserId']),
        updatedByUserId: _extractObjectId(json['updatedByUserId']),
        published: json['published'] ?? false,
        createdAt: _extractDate(json['createdAt']),
        updatedAt: _extractDate(json['updatedAt']),
      );
    } catch (error) {
      rethrow;
    }
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      '_id': id.isNotEmpty ? id : null,
      'userId': userId,
      'leadDesignation': leadDesignation,
      'leadInterestedPropertyId': leadInterestedPropertyId,
      'leadStatus': leadStatus,
      'referanceFrom': referanceFrom?.id,
      'followUpStatus': followUpStatus,
      'referredByUserId': referredByUserId ?? '',
      'referredByUserFirstName': referredByUserFirstName,
      'referredByUserLastName': referredByUserLastName,
      'referredByUserEmail': referredByUserEmail,
      'referredByUserPhoneNumber': referredByUserPhoneNumber,
      'referredByUserDesignation': referredByUserDesignation,
      'assignedByUserId': assignedByUserId,
      'assignedToUserId': assignedToUserId,
      'leadAltEmail': leadAltEmail,
      'leadAltPhoneNumber': leadAltPhoneNumber,
      'leadLandLineNumber': leadLandLineNumber,
      'leadWebsite': leadWebsite,
      'note': note,
      'createdByUserId': createdByUserId,
      'updatedByUserId': updatedByUserId,
      'published': published,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    map.removeWhere((key, value) => value == null || value == '');
    
    return map;
  }

  /// Serialize to JSON for edit operations (excludes fields that shouldn't be modified)
  Map<String, dynamic> toJsonForEdit() {
    final map = <String, dynamic>{
      'userId': userId,
      'leadDesignation': leadDesignation,
      'leadInterestedPropertyId': leadInterestedPropertyId,
      'leadStatus': leadStatus,
      'referanceFrom': referanceFrom?.id,
      'followUpStatus': followUpStatus,
      'referredByUserId': referredByUserId ?? '',
      'referredByUserFirstName': referredByUserFirstName,
      'referredByUserLastName': referredByUserLastName,
      'referredByUserEmail': referredByUserEmail,
      'referredByUserPhoneNumber': referredByUserPhoneNumber,
      'referredByUserDesignation': referredByUserDesignation,
      'assignedByUserId': assignedByUserId,
      'assignedToUserId': assignedToUserId,
      'leadAltEmail': leadAltEmail,
      'leadAltPhoneNumber': leadAltPhoneNumber,
      'leadLandLineNumber': leadLandLineNumber,
      'leadWebsite': leadWebsite,
      'note': note,
      'published': published,
    };

    // Remove empty values to match the frontend React payload behavior.
    // This prevents the backend API from rejecting nulls or overriding existing valid data with nulls.
    map.removeWhere((key, value) => value == null || value == '');

    return map;
  }
}
