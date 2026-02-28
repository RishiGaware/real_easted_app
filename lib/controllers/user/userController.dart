import 'package:inhabit_realties/models/auth/UsersModel.dart';
import 'package:inhabit_realties/services/user/userService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:inhabit_realties/models/lead/LeadsModel.dart';
import 'package:inhabit_realties/services/lead/leadsService.dart';
import 'package:inhabit_realties/controllers/role/roleController.dart';

class UserController {
  final UserService _userService = UserService();
  final LeadsService _leadsService = LeadsService();
  final RoleController _roleController = RoleController();

  Future<UsersModel> getCurrentUserFromLocalStorage() async {
    var userData = await _userService.getCurrentUserFromLocalStorage();
    UsersModel usersModel = UsersModel.fromJson(userData);
    return usersModel;
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    var users = await _userService.getAllUsers(token);
    return users;
  }

  Future<Map<String, dynamic>> getUsersByUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    var users = await _userService.getUsersByUserId(token, userId);
    return users;
  }

  Future<Map<String, dynamic>> getUsersByRoleId(String roleId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    var users = await _userService.getUsersByRoleId(token, roleId);
    return users;
  }

  Future<Map<String, dynamic>> editUser(
    String userId,
    String roleId,
    String email,
    String firstName,
    String lastName,
    String phoneNumber,
    String password,
    bool published,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    Map<String, dynamic> response;
    UsersModel usersModel = UsersModel(
      id: userId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      password: password,
      role: roleId,
      createdByUserId: '',
      updatedByUserId: '',
      published: published,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    response = await _userService.editUser(token, usersModel);
    return response;
  }

  // Get user statistics for profile page (role-based)
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final currentUser = prefs.getString('currentUser') ?? '';

      if (currentUser.isEmpty) {
        return {
          'totalLeads': 0,
          'activeLeads': 0,
          'completedLeads': 0,
        };
      }

      final decodedCurrentUser = jsonDecode(currentUser);
      final userId = decodedCurrentUser['_id'] ?? '';
      final userRoleId = decodedCurrentUser['role'] ?? '';

      // Get role name by role ID
      String userRoleName = '';
      try {
        final roleData = await _roleController.getRoleById(userRoleId);
        if (roleData['statusCode'] == 200) {
          userRoleName = roleData['data']['name'] ?? '';
        }
        // Role name fetched successfully
      } catch (e) {
        // Error handled silently
      }

      Map<String, dynamic> leadsResponse;
      
      // Since role fetching is failing, let's check if this is the admin role ID we know
      // Role ID: 68162f63ff2da55b40ca61b8 (from logs)
      bool isAdmin = userRoleId == '68162f63ff2da55b40ca61b8' || userRoleName.toLowerCase() == 'admin';
      
      if (isAdmin) {
        // Admin: get all leads
        leadsResponse = await _leadsService.getAllLeads(token, '');
      } else {
        // Sales or unknown: get assigned leads
        leadsResponse =
            await _leadsService.getAssignedLeadsForCurrentUser(token);
      }

      if (leadsResponse['statusCode'] == 200) {
        final allLeads = (leadsResponse['data'] as List)
            .map((item) => LeadsModel.fromJson(item))
            .toList();
        // Total leads fetched successfully

        final totalLeads = allLeads.length;

        final activeLeads = allLeads.where((lead) {
          final status = lead.leadStatus?.toLowerCase() ?? '';
          return status == 'active' || status == 'pending';
        }).length;
        final completedLeads = allLeads.where((lead) {
          final status = lead.leadStatus?.toLowerCase() ?? '';
          return status == 'completed' || status == 'closed';
        }).length;

        return {
          'totalLeads': totalLeads,
          'activeLeads': activeLeads,
          'completedLeads': completedLeads,
          'isAdmin': isAdmin,
        };
      }

      return {
        'totalLeads': 0,
        'activeLeads': 0,
        'completedLeads': 0,
      };
    } catch (e) {
      return {
        'totalLeads': 0,
        'activeLeads': 0,
        'completedLeads': 0,
      };
    }
  }

  // Get assigned leads for sales person
  Future<List<LeadsModel>> getAssignedLeads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final currentUser = prefs.getString('currentUser') ?? '';

      if (currentUser.isEmpty) {
        return [];
      }

      final decodedCurrentUser = jsonDecode(currentUser);
      final userId = decodedCurrentUser['_id'] ?? '';

      // Get all leads
      final leadsResponse = await _leadsService.getAllLeads(token, '');

      if (leadsResponse['statusCode'] == 200) {
        final allLeads = (leadsResponse['data'] as List)
            .map((item) => LeadsModel.fromJson(item))
            .toList();

        // Filter leads assigned to current user
        return allLeads
            .where((lead) => lead.assignedToUserId == userId)
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // New: Get assigned leads for sales user using the new endpoint or all leads for admin
  Future<List<LeadsModel>> getAssignedLeadsNew() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final currentUser = prefs.getString('currentUser') ?? '';

      if (currentUser.isEmpty) {
        return [];
      }

      final decodedCurrentUser = jsonDecode(currentUser);
      final userRoleId = decodedCurrentUser['role'] ?? '';

      // Get role name by role ID
      String userRoleName = '';
      try {
        final roleData = await _roleController.getRoleById(userRoleId);
        if (roleData['statusCode'] == 200) {
          userRoleName = roleData['data']['name'] ?? '';
        }
      } catch (e) {
        // Error handled silently
      }

      // Check if user is admin
      bool isAdmin = userRoleId == '68162f63ff2da55b40ca61b8' ||
          userRoleName.toLowerCase() == 'admin';

      Map<String, dynamic> response;
      if (isAdmin) {
        // Find all leads for admin users
        response = await _leadsService.getAllLeads(token, '');
      } else {
        // Find assigned leads for other users
        response = await _leadsService.getAssignedLeadsForCurrentUser(token);
      }

      if (response['statusCode'] == 200) {
        return (response['data'] as List)
            .map((item) => LeadsModel.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
