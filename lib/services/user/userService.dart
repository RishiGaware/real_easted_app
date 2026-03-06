import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:inhabit_realties/constants/apiUrls.dart';
import 'package:inhabit_realties/interfaces/user/userInterface.dart';
import 'package:inhabit_realties/models/auth/UsersModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService implements UserInterface {
  @override
  Future<Map<String, dynamic>> getCurrentUserFromLocalStorage() async {
    Map<String, dynamic> result = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = prefs.getString('currentUser') ?? "";
      final decodedCurrentUser = jsonDecode(currentUser);
      //UsersModel usersModel = UsersModel.fromJson(decodedCurrentUser);
      result = decodedCurrentUser;
    } catch (error) {
      result = {
        "statusCode": 500,
        "message": 'internal server error',
        "data": error,
      };
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> getAllUsers(String token) async {
    Map<String, dynamic> result = {};
    try {
      final url = ApiUrls.getAllUsersWithParams;
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      );

      var data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        result = {
          "statusCode": 200,
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        result = {
          "statusCode": 400,
          "message": data['message'],
          "data": data['data'],
        };
      }
    } catch (error) {
      result = {
        "statusCode": 500,
        "message": 'internal server error',
        "data": error,
      };
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> getUsersByUserId(
    String token,
    String userId,
  ) async {
    Map<String, dynamic> result = {};

    try {
      final url = "${ApiUrls.getUserById}$userId";
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      var data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        result = {
          "statusCode": 200,
          "message": data['message'],
          "data": data['data'],
        };
      } else {
        result = {
          "statusCode": 400,
          "message": data['message'],
          "data": data['data'],
        };
      }
    } catch (error) {
      result = {
        "statusCode": 500,
        "message": 'internal server error',
        "data": error,
      };
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> getUsersByRoleId(
    String token,
    String roleId,
  ) async {
    Map<String, dynamic> result = {};

    try {
      final prefs = await SharedPreferences.getInstance();
      //final token = prefs.getString('token') ?? "";
      final currentUser = prefs.getString('currentUser') ?? "";
      final decodedCurrentUser = jsonDecode(currentUser);
      final url = ApiUrls.getAllUsersWithParams;
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"roleId": roleId}),
      );

      var data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        result = {
          "statusCode": 200,
          "message": data['message'],
          "count": data['count'],
          "data": data['data'],
        };
      } else {
        result = {
          "statusCode": 400,
          "message": data['message'],
          "data": data['data'],
        };
      }
    } catch (error) {
      result = {
        "statusCode": 500,
        "message": 'internal server error',
        "data": error,
      };
    }

    return result;
  }

  @override
  Future<Map<String, dynamic>> getAllUsersWithParams(
    String token, {
    String? roleId,
    bool? published,
  }) async {
    Map<String, dynamic> result = {};

    try {
      final url = ApiUrls.getAllUsersWithParams;
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (roleId != null) "roleId": roleId,
          if (published != null) "published": published,
        }),
      );

      var data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        result = {
          "statusCode": 200,
          "message": data['message'],
          "count": data['count'],
          "data": data['data'],
        };
      } else {
        result = {
          "statusCode": 400,
          "message": data['message'],
          "data": data['data'],
        };
      }
    } catch (error) {
      result = {
        "statusCode": 500,
        "message": 'internal server error',
        "data": error,
      };
    }

    return result;
  }


  @override
  Future<Map<String, dynamic>> editUser(
    String token,
    UsersModel userModel,
  ) async {
    Map<String, dynamic> result = {};
    try {
      final url = '${ApiUrls.editUser}${userModel.id}';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userModel),
      );

      var data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        result = {
          "statusCode": 200,
          "message": data['message'],
          "token": data['token'],
          "data": data['data'],
        };
      } else {
        result = {
          "statusCode": 400,
          "message": data['message'],
          "data": data['data'],
        };
      }
    } catch (error) {
      result = {
        "statusCode": 500,
        "message": 'internal server error',
        "data": error,
      };
    }
    return result;
  }
}
