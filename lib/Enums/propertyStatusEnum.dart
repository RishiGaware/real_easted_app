class PropertyStatus {
  // Constants for property statuses
  static const String forSale = 'FOR SALE';
  static const String forRent = 'FOR RENT';
  static const String sold = 'SOLD';
  static const String rented = 'RENTED';

  // List of all valid statuses
  static const List<String> values = [forSale, forRent, sold, rented];

  // Get display label for a status
  static String getLabel(String status) {
    switch (status.toUpperCase().trim()) {
      case forSale:
        return 'FOR SALE';
      case forRent:
        return 'FOR RENT';
      case sold:
        return 'SOLD';
      case rented:
        return 'RENTED';
      default:
        return 'FOR SALE';
    }
  }

  // Validate if a status is valid
  static bool isValid(String status) {
    return values.contains(status.toUpperCase().trim());
  }

  // Get default status
  static String getDefault() {
    return forSale;
  }

  // Parse status from string with fallback
  static String fromString(String value) {
    if (value.isEmpty) return getDefault();

    final normalizedValue = value.toUpperCase().trim();

    switch (normalizedValue) {
      case forSale:
        return forSale;
      case forRent:
        return forRent;
      case sold:
        return sold;
      case rented:
        return rented;
      default:
        return getDefault();
    }
  }
}
