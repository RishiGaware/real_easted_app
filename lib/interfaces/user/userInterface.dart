// ignore_for_file: file_names
import 'package:inhabit_realties/models/auth/UsersModel.dart';

abstract class UserInterface {
  Future<Map<String, dynamic>> getCurrentUserFromLocalStorage();
  Future<Map<String, dynamic>> getAllUsers(String token);
  Future<Map<String, dynamic>> getUsersByRoleId(String token, String roleId);
  Future<Map<String, dynamic>> getUsersByUserId(String token, String userId);
  Future<Map<String, dynamic>> editUser(String token, UsersModel user);
  Future<Map<String, dynamic>> getAllUsersWithParams(
    String token, {
    String? roleId,
    bool? published,
  });
}

