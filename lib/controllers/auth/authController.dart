// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inhabit_realties/constants/apiUrls.dart';
import 'package:inhabit_realties/models/auth/UsersModel.dart';
import 'package:inhabit_realties/services/auth/authService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inhabit_realties/controllers/role/roleController.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> _checkAuth(String token) async {
    try {
      final url = ApiUrls.checkAuth;

      // First try with a shorter timeout
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 || response.statusCode == 201) {
          var data = jsonDecode(response.body);
          return {'success': true, 'isAuthenticated': data['data'] == true};
        }
      } catch (_) {
        // If first attempt fails, try again with a longer timeout
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200 || response.statusCode == 201) {
          var data = jsonDecode(response.body);
          return {'success': true, 'isAuthenticated': data['data'] == true};
        }
      }

      // If we get here, the server responded but with an error
      return {
        'success': true, // Changed to true since server is responding
        'isAuthenticated': false,
        'error': 'Authentication failed',
      };
    } catch (e) {
      // Only return server error if we truly can't reach the server
      return {
        'success': false,
        'isAuthenticated': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      if (token.isEmpty) {
        return {'success': true, 'isAuthenticated': false};
      }

      return await _checkAuth(token);
    } catch (e) {
      return {
        'success': false,
        'isAuthenticated': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    Map<String, dynamic> response;
    UsersModel usersModel = UsersModel(
      id: '0',
      email: email,
      firstName: '',
      lastName: '',
      phoneNumber: '',
      password: password,
      role: '',
      createdByUserId: '',
      updatedByUserId: '',
      published: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    response = await _authService.login(usersModel);
    if (response['statusCode'] == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response['token']);

      final roleId = response['data']['role'];
      bool isUserRole = false;
      try {
        final roleController = RoleController();
        final roleData = await roleController.getRoleById(roleId);
        if (roleData != null && roleData['data'] != null) {
          final roleName = roleData['data']['name'];
          if (roleName?.toLowerCase() == 'user') {
            isUserRole = true;
          }
        }
      } catch (e) {
        // Optional: log error or handle it
      }

      if (isUserRole) {
        await prefs.remove('token');
        return {
          'statusCode': 403,
          'message': 'User not allowed to login with mobile application. This is just for the internal team.',
          'data': null
        };
      }

      await prefs.setString('currentUser', jsonEncode(response['data']));
    }
    return response;
  }

  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      if (token.isEmpty) {
        return {
          'statusCode': 401,
          'message': 'User not authenticated',
          'data': null
        };
      }

      final response = await _authService.changePassword(
          token, currentPassword, newPassword);
      return response;
    } catch (e) {
      return {
        'statusCode': 500,
        'message': 'Internal error occurred',
        'data': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> register(
    String roleId,
    String email,
    String firstName,
    String lastName,
    String phoneNumber,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    Map<String, dynamic> response;
    UsersModel usersModel = UsersModel(
      id: '',
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      password: password,
      role: roleId,
      createdByUserId: '',
      updatedByUserId: '',
      published: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    response = await _authService.register(token, usersModel);
    return response;
  }
}
