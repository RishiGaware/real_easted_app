import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/apiUrls.dart';

class DashboardService {
  static String get baseUrl => ApiUrls.baseUrl;

  // Get dashboard overview
  static Future<Map<String, dynamic>> getDashboardOverview(String token) async {
    try {
      final clientDate = DateTime.now().toIso8601String();
      final url = Uri.parse('$baseUrl/dashboard/overview').replace(
        queryParameters: {'clientDate': clientDate},
      );
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load dashboard overview');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get property analytics
  static Future<Map<String, dynamic>> getPropertyAnalytics(String token,
      [String timeFrame = '12M']) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/dashboard/properties/analytics?timeFrame=$timeFrame'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        throw Exception('Failed to load property analytics');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get lead analytics
  static Future<Map<String, dynamic>> getLeadAnalytics(String token,
      [String timeFrame = '12M']) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/leads/analytics?timeFrame=$timeFrame'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load lead analytics');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get sales analytics
  static Future<Map<String, dynamic>> getSalesAnalytics(String token,
      [String timeFrame = '12M']) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/sales/analytics?timeFrame=$timeFrame'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load sales analytics');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get user analytics
  static Future<Map<String, dynamic>> getUserAnalytics(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/users/analytics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load user analytics');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get recent activities
  static Future<Map<String, dynamic>> getRecentActivities(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/activities'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load recent activities');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get today's schedules
  static Future<Map<String, dynamic>> getTodaySchedules(String token) async {
    try {
      final clientDate = DateTime.now().toIso8601String();
      final url = Uri.parse(ApiUrls.getTodaySchedules).replace(
        queryParameters: {'clientDate': clientDate},
      );
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load today\'s schedules');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get weekly performance
  static Future<Map<String, dynamic>> getWeeklyPerformance(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/weekly-performance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load weekly performance');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get monthly trends
  static Future<Map<String, dynamic>> getMonthlyTrends(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/monthly-trends'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load monthly trends');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get top properties
  static Future<Map<String, dynamic>> getTopProperties(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/top-properties'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load top properties');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get lead conversion rates
  static Future<Map<String, dynamic>> getLeadConversionRates(
      String token) async {
    try {
      final clientDate = DateTime.now().toIso8601String();
      final url = Uri.parse('$baseUrl/dashboard/lead-conversion').replace(
        queryParameters: {'clientDate': clientDate},
      );
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load lead conversion rates');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get financial summary
  static Future<Map<String, dynamic>> getFinancialSummary(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/financial-summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load financial summary');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get admin performance analytics (overall company performance)
  static Future<Map<String, dynamic>> getAdminPerformanceAnalytics(String token,
      [String timeFrame = '12M']) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/admin/performance?timeFrame=$timeFrame'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load admin performance analytics');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get sales performance analytics (individual sales person performance)
  static Future<Map<String, dynamic>> getSalesPerformanceAnalytics(String token,
      [String timeFrame = '12M']) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/sales/performance?timeFrame=$timeFrame'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load sales performance analytics');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
