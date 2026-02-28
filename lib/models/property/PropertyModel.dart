import 'package:inhabit_realties/models/address/Address.dart';
import 'package:inhabit_realties/models/property/FeaturesModel.dart';

class PropertyModel {
  final String id;
  final String name;
  final String propertyTypeId;
  final String description;
  final Address propertyAddress;
  final String owner;
  final double price;
  final String propertyStatus;
  final Features features;
  final DateTime listedDate;
  final String createdByUserId;
  final String updatedByUserId;
  final bool published;
  final DateTime createdAt;
  final DateTime updatedAt;

  PropertyModel({
    required this.id,
    required this.name,
    required this.propertyTypeId,
    required this.description,
    required this.propertyAddress,
    required this.owner,
    required this.price,
    required this.propertyStatus,
    required this.features,
    required this.listedDate,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.published,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Deserialize from JSON
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    try {
      // Handle propertyTypeId parsing
      String parsedPropertyTypeId = '';
      if (json['propertyTypeId'] != null) {
        if (json['propertyTypeId'] is String) {
          parsedPropertyTypeId = json['propertyTypeId'];
        } else if (json['propertyTypeId'] is Map) {
          parsedPropertyTypeId = json['propertyTypeId']['_id']?.toString() ?? '';
        }
      }
      
      return PropertyModel(
        id: json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        propertyTypeId: parsedPropertyTypeId,
        description: json['description']?.toString() ?? '',
        propertyAddress: Address.fromJson(json['propertyAddress'] ?? {}),
        owner: json['owner']?.toString() ?? '',
        price: (json['price'] ?? 0).toDouble(),
        propertyStatus: json['propertyStatus']?.toString().toUpperCase() ?? '',
        features: Features.fromJson(json['features'] ?? {}),
        listedDate: _parseDateTime(json['listedDate']),
        createdByUserId: json['createdByUserId']?.toString() ?? '',
        updatedByUserId: json['updatedByUserId']?.toString() ?? '',
        published: json['published'] ?? false,
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      // Return a default property model if parsing fails
      return PropertyModel(
        id: json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown Property',
        propertyTypeId: json['propertyTypeId']?.toString() ?? '',
        description:
            json['description']?.toString() ?? 'No description available',
        propertyAddress: Address.fromJson(json['propertyAddress'] ?? {}),
        owner: json['owner']?.toString() ?? '',
        price: (json['price'] ?? 0).toDouble(),
        propertyStatus: json['propertyStatus']?.toString() ?? 'FOR SALE',
        features: Features.fromJson(json['features'] ?? {}),
        listedDate: DateTime.now(),
        createdByUserId: json['createdByUserId']?.toString() ?? '',
        updatedByUserId: json['updatedByUserId']?.toString() ?? '',
        published: json['published'] ?? false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Helper method to safely parse DateTime
  static DateTime _parseDateTime(dynamic dateValue) {
    try {
      if (dateValue == null) return DateTime.now();
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) return DateTime.parse(dateValue);
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'propertyTypeId': propertyTypeId,
      'description': description,
      'propertyAddress': propertyAddress.toJson(),
      'owner': owner,
      'price': price,
      'propertyStatus': propertyStatus,
      'features': features.toJson(),
      'listedDate': listedDate.toIso8601String(),
      'createdByUserId': createdByUserId,
      'updatedByUserId': updatedByUserId,
      'published': published,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
