import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:inhabit_realties/controllers/role/roleController.dart';

class RoleUtils {
  static String? _currentUserRoleId;
  static String? _currentUserRoleName;
  static Map<String, dynamic>? _currentUserData;
  static bool _isInitialized = false;

  // Initialize current user data
  static Future<void> initializeCurrentUser({bool force = false}) async {
    // Re-initialize only if forced or not yet initialized
    if (_isInitialized && !force) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to get role from 'role' key directly first
      final directRole = prefs.getString('role');
      if (directRole != null && directRole.isNotEmpty) {
        _currentUserRoleName = directRole;
      }

      final currentUser = prefs.getString('currentUser') ?? '';

      if (currentUser.isNotEmpty) {
        _currentUserData = jsonDecode(currentUser);
        _currentUserRoleId = _currentUserData?['role'];

        // If we don't have a role name yet but have an ID, fetch it
        if ((_currentUserRoleName == null || _currentUserRoleName!.isEmpty) && 
            _currentUserRoleId != null && _currentUserRoleId!.isNotEmpty) {
          try {
            await _loadRoleName();
          } catch (roleError) {
            _currentUserRoleName = null;
          }
        }
      }

      _isInitialized = true;
    } catch (e) {
      // Don't re-throw the exception - let the app continue
      _currentUserRoleId = null;
      _currentUserRoleName = null;
      _currentUserData = null;
    }
  }

  // Load role name from role ID
  static Future<void> _loadRoleName() async {
    try {
      // First try to get all roles and find the matching one
      final roleController = RoleController();
      final allRolesResponse = await roleController.getAllRoles();

      if (allRolesResponse['statusCode'] == 200 &&
          allRolesResponse['data'] != null) {
        final roles = allRolesResponse['data'] as List;
        final matchingRole = roles.firstWhere(
          (role) => role['_id'] == _currentUserRoleId,
          orElse: () => null,
        );

        if (matchingRole != null) {
          _currentUserRoleName = matchingRole['name'];
        } else {
          // Role not found in all roles list
          _currentUserRoleName = null;
        }
      } else {
        // Failed to get all roles, trying individual role fetch
        try {
          final roleData =
              await roleController.getRoleById(_currentUserRoleId!);

          if (roleData['data'] != null) {
            _currentUserRoleName = roleData['data']['name'];
          } else {
            // No role data found in individual response
            _currentUserRoleName = null;
          }
        } catch (individualError) {
          // Error in individual role fetch
          _currentUserRoleName = null;
        }
      }
    } catch (e) {
      _currentUserRoleName = null;
    }
  }

  // Get current user role ID
  static String? getCurrentUserRoleId() {
    return _currentUserRoleId;
  }

  // Get current user role name
  static String? getCurrentUserRoleName() {
    return _currentUserRoleName;
  }

  // Get current user data
  static Map<String, dynamic>? getCurrentUserData() {
    return _currentUserData;
  }

  // Check if user has admin role
  static bool isAdmin() {
    return _currentUserRoleName?.trim().toLowerCase() == 'admin';
  }

  // Check if user has executive role
  static bool isExecutive() {
    return _currentUserRoleName?.toLowerCase() == 'executive';
  }

  // Check if user has sales role
  static bool isSales() {
    final roleLower = _currentUserRoleName?.toLowerCase();
    return roleLower == 'sales' || roleLower == 'sales person';
  }

  // Check if user has saller role
  static bool isSaller() {
    return _currentUserRoleName?.toLowerCase() == 'saller';
  }

  // Check if user has user role
  static bool isUser() {
    return _currentUserRoleName?.toLowerCase() == 'user';
  }

  // Check if user can create properties (admin, executive)
  static bool canCreateProperties() {
    return hasAnyRole(['admin', 'executive']);
  }

  // Check if user can edit properties (admin, executive)
  static bool canEditProperties() {
    return hasAnyRole(['admin', 'executive']);
  }

  // Check if user can delete properties (admin only)
  static bool canDeleteProperties() {
    return isAdmin();
  }

  // Check if user can manage properties (create/edit)
  static bool canManageProperties() {
    return hasAnyRole(['admin', 'executive']);
  }

  // Check if user can view unpublished properties (admin only)
  static bool canViewUnpublishedProperties() {
    return isAdmin();
  }

  // Check if user can use advanced property search (admin, executive)
  static bool canUseAdvancedPropertySearch() {
    return hasAnyRole(['admin', 'executive']);
  }

  // Check if user can create leads (admin, executive, sales)
  static bool canCreateLeads() {
    return hasAnyRole(['admin', 'executive', 'sales']);
  }

  // Check if user can edit leads (admin, executive, sales)
  static bool canEditLeads() {
    return hasAnyRole(['admin', 'executive', 'sales']);
  }

  // Check if user can manage leads (create/edit)
  static bool canManageLeads() {
    return hasAnyRole(['admin', 'executive', 'sales']);
  }

  // Check if user can view leads (admin, executive, sales)
  static bool canViewLeads() {
    return hasAnyRole(['admin', 'executive', 'sales']);
  }

  // Check if user can see all leads (admin only)
  static bool canSeeAllLeads() {
    return isAdmin();
  }

  // Check if user can see leads they created (executive)
  static bool canSeeOwnLeads() {
    return isExecutive();
  }

  // Check if user can see leads assigned to them (sales)
  static bool canSeeAssignedLeads() {
    return isSales();
  }

  // Check if user has specific role
  static bool hasRole(String role) {
    return _currentUserRoleName?.toLowerCase() == role.toLowerCase();
  }

  // Check if user has any of the specified roles
  static bool hasAnyRole(List<String> roles) {
    if (_currentUserRoleName == null) return false;
    return roles.any(
        (role) => _currentUserRoleName!.toLowerCase() == role.toLowerCase());
  }

  // Check if user has all of the specified roles
  static bool hasAllRoles(List<String> roles) {
    if (_currentUserRoleName == null) return false;
    return roles.every(
        (role) => _currentUserRoleName!.toLowerCase() == role.toLowerCase());
  }

  // Get filtered menu items based on user role
  static List<Map<String, dynamic>> getFilteredMenuItems(
      List<Map<String, dynamic>> menuItems) {
    return menuItems.where((item) {
      final path = item['path'] as String;

      // Admin-only routes
      if (path == '/users' || path == '/auth/register') {
        return isAdmin();
      }

      if (path == '/customers') {
        return isAdmin() || isExecutive();
      }

      // Property management routes - only for admin, executive
      if (path == '/addNewProperty') {
        return canCreateProperties();
      }

      // Lead management routes - only for admin, executive
      if (path == '/addLead' || path == '/editLead') {
        return canManageLeads();
      }

      // Routes accessible to all authenticated users
      if (path == '/settings' || path == '/auth/logout') {
        return true;
      }

      // Default: show all items
      return true;
    }).toList();
  }

  // Check if a specific route is accessible to current user
  static bool canAccessRoute(String route) {
    // Admin-only routes
    if (route == '/users' || route == '/auth/register') {
      return isAdmin();
    }

    if (route == '/customers') {
      return isAdmin() || isExecutive();
    }

    // Property management routes - only for admin, executive
    if (route == '/addNewProperty') {
      return canCreateProperties();
    }
    if (route == '/editProperty') {
      return canEditProperties();
    }

    // Lead management routes - only for admin, executive
    if (route == '/addLead' || route == '/editLead') {
      return canManageLeads();
    }

    // Routes accessible to all authenticated users
    if (route == '/settings' ||
        route == '/auth/logout') {
      return true;
    }

    // Default: allow access
    return true;
  }

  // Clear user data (for logout)
  static void clearUserData() {
    _currentUserRoleId = null;
    _currentUserRoleName = null;
    _currentUserData = null;
  }

  // Debug method to print current role information
  static void debugRoleInfo() {
    // No print statements in this method
  }
}
