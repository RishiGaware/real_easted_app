// ignore_for_file: prefer_final_fields

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/constants/initalAssigner.dart';
import 'package:inhabit_realties/controllers/auth/authController.dart';
import 'package:inhabit_realties/controllers/role/roleController.dart';
import 'package:inhabit_realties/controllers/user/userController.dart';
import 'package:inhabit_realties/models/auth/UsersModel.dart';
import 'package:inhabit_realties/models/role/RolesModel.dart';
import 'package:inhabit_realties/pages/widgets/appSnackBar.dart';
import 'package:inhabit_realties/pages/widgets/formTextField.dart';
import 'package:inhabit_realties/providers/register_page_provider.dart';
import 'package:inhabit_realties/pages/users/add_user_address_page.dart';
import 'package:inhabit_realties/controllers/address/userAddressController.dart';
import 'package:inhabit_realties/models/address/UserAddressModel.dart';

class EditUserPage extends StatefulWidget {
  const EditUserPage({super.key});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  // Add these constants at the class level for consistent styling
  static const double _formPadding = 10.0;
  static const double _formTopPadding = 10.0;
  static const double _formBottomPadding = 10.0;
  static const EdgeInsets _fieldPadding = EdgeInsets.only(
    top: 20,
    left: 15,
    right: 15,
  );
  static const EdgeInsets _dropdownContentPadding = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 15,
  );
  static const BorderRadius _borderRadius = BorderRadius.all(
    Radius.circular(10.0),
  );

  // Add these constants for consistent styling
  static const double _sectionSpacing = 25.0;
  static const double _headerSpacing = 15.0;
  static const EdgeInsets _sectionPadding = EdgeInsets.only(
    bottom: _sectionSpacing,
  );

  UsersModel? user;
  final AuthController _authController = AuthController();
  final UserController _userController = UserController();
  final RoleController _rolesController = RoleController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _id = TextEditingController();
  final TextEditingController _roleId = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _phoneNumber = TextEditingController();
  final TextEditingController _password = TextEditingController();

  String? selectedRoleId;
  bool selectedPublishedOrNot = true;
  List<RolesModel> roles = [];
  List<UserAddressModel> addresses = [];
  final UserAddressController _userAddressController = UserAddressController();
  bool isLoading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      user = ModalRoute.of(context)!.settings.arguments as UsersModel;
      _initialized = true;
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([getAllRoles(), setDetails()]);
    if (user != null) {
      await getUserAddresses(user!.id);
    }
    setState(() => isLoading = false);
  }

  Future<void> getUserAddresses(String userId) async {
    try {
      print('Fetching addresses for userId: $userId');
      final response = await _userAddressController.getUserAddressByUserId(userId);
      print('Address API response: $response');
      if (response['statusCode'] == 200 && response['data'] != null) {
        if (mounted) {
          setState(() {
            if (response['data'] is List) {
              addresses = (response['data'] as List)
                  .map((item) => UserAddressModel.fromJson(item))
                  .where((address) => address.published)
                  .toList();
            } else {
              final address = UserAddressModel.fromJson(response['data']);
              addresses = address.published ? [address] : [];
            }
            print('Parsed addresses count: ${addresses.length}');
          });
        }
      }
    } catch (e) {
      print('Error fetching addresses: $e');
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      final response = await _userAddressController.deleteUserAddress(addressId);
      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        if (mounted) {
          AppSnackBar.showSnackBar(
            context,
            'Success',
            'Address deleted successfully',
            ContentType.success,
          );
          await getUserAddresses(user!.id);
        }
      } else {
        if (mounted) {
          AppSnackBar.showSnackBar(
            context,
            'Error',
            response['message'] ?? 'Failed to delete address',
            ContentType.failure,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          'An error occurred',
          ContentType.failure,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> getAllRoles() async {
    try {
      final response = await _rolesController.getAllRoles();
      if (!mounted) return;

      if (response['statusCode'] == 200) {
        final data = response['data'];
        if (data != null && data.isNotEmpty) {
          setState(() {
            roles = List<RolesModel>.from(
              data.map((item) => RolesModel.fromJson(item)),
            );
          });
        }
      } else {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          response['message'] ?? RegisterPageProvider.loadRolesError,
          ContentType.failure,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showSnackBar(
        context,
        'Error',
        RegisterPageProvider.loadRolesError,
        ContentType.failure,
      );
    }
  }

  Future<void> setDetails() async {
    if (user != null) {
      _id.text = user?.id ?? "";
      _roleId.text = user?.role ?? "";
      _email.text = user!.email;
      _firstName.text = user?.firstName ?? "";
      _lastName.text = user?.lastName ?? "";
      _phoneNumber.text = user?.phoneNumber ?? "";
      _password.text = "";
      selectedPublishedOrNot = user?.published ?? false;
      selectedRoleId = user?.role ?? "";
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final response = await _userController.editUser(
        user!.id,
        _roleId.text.trim(),
        _email.text.trim(),
        await InitalAssigner.generateInitial(_firstName.text.trim()),
        await InitalAssigner.generateInitial(_lastName.text.trim()),
        _phoneNumber.text.trim(),
        _password.text.trim().isEmpty ? '' : _password.text.trim(),
        selectedPublishedOrNot,
      );

      if (!mounted) return;

      if (response['statusCode'] == 200) {
        AppSnackBar.showSnackBar(
          context,
          'Success',
          response['message'] ?? 'User updated successfully',
          ContentType.success,
        );
        Navigator.pushReplacementNamed(context, '/users');
      } else {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          response['message'] ?? 'Failed to update user',
          ContentType.failure,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showSnackBar(
        context,
        'Error',
        'Failed to update user',
        ContentType.failure,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _headerSpacing),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Basic Information'),
          _buildDropdownField(
            labelText: RegisterPageProvider.role,
            prefixIcon: Icons.security_outlined,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: RegisterPageProvider.role,
                prefixIcon: const Icon(
                  Icons.security_outlined,
                  color: AppColors.greyColor,
                ),
              ),
              value: selectedRoleId,
              items: roles.map((role) {
                return DropdownMenuItem<String>(
                  value: role.id,
                  child: Text(
                    role.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          selectedRoleId = value;
                          _roleId.text = value;
                        });
                      }
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return RegisterPageProvider.roleValidationMessage;
                }
                return null;
              },
            ),
          ),
          FormTextField(
            textEditingController: _email,
            labelText: RegisterPageProvider.email,
            prefixIcon: CupertinoIcons.mail,
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return RegisterPageProvider.emailValidationMessage;
              }
              final bool emailValid = RegExp(
                r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
              ).hasMatch(value);
              if (!emailValid) {
                return RegisterPageProvider.emailValidationMessage;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Personal Information'),
          FormTextField(
            textEditingController: _firstName,
            labelText: RegisterPageProvider.firstName,
            prefixIcon: CupertinoIcons.person,
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return RegisterPageProvider.firstNameValidationMessage;
              }
              return null;
            },
          ),
          FormTextField(
            textEditingController: _lastName,
            labelText: RegisterPageProvider.lastName,
            prefixIcon: CupertinoIcons.person,
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return RegisterPageProvider.lastNameValidationMessage;
              }
              return null;
            },
          ),
          FormTextField(
            textEditingController: _phoneNumber,
            labelText: RegisterPageProvider.phoneNumber,
            prefixIcon: CupertinoIcons.phone,
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return RegisterPageProvider.phoneNumberValidationMessage;
              }
              final bool phoneValid = RegExp(
                r'^\+?[0-9]{7,15}$',
              ).hasMatch(value);
              if (!phoneValid) {
                return RegisterPageProvider.phoneNumberValidationMessage;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInfoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Address Information'),
          if (addresses.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground,
                borderRadius: _borderRadius,
                border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.location, color: Colors.grey),
                  SizedBox(width: 10),
                  Text('No address added.'),
                ],
              ),
            )
          else
            ...addresses.map((address) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground,
                  borderRadius: _borderRadius,
                  border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(CupertinoIcons.location_solid, color: AppColors.brandPrimary),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address.fullAddress.isNotEmpty
                                ? address.fullAddress
                                : "${address.address.street}, ${address.address.city}, ${address.address.zipOrPinCode}",
                            style: TextStyle(fontSize: 14, color: textColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.delete, color: Colors.red, size: 20),
                      onPressed: () => _deleteAddress(address.id),
                      tooltip: 'Delete Address',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Security'),
          FormTextField(
            textEditingController: _password,
            labelText: RegisterPageProvider.password,
            prefixIcon: CupertinoIcons.lock,
            suffixIcon: CupertinoIcons.eye,
            obscureText: true,
            enabled: !isLoading,
          ),
          _buildDropdownField(
            labelText: 'Status',
            prefixIcon: Icons.label_important_outline,
            child: DropdownButtonFormField<bool>(
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(
                  Icons.label_important_outline,
                  color: AppColors.greyColor,
                ),
              ),
              value: selectedPublishedOrNot,
              items: [
                DropdownMenuItem(
                  value: true,
                  child: Text(
                    'Published',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text(
                    'Unpublished',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
              onChanged: isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          selectedPublishedOrNot = value;
                        });
                      }
                    },
              validator: (value) {
                if (value == null) {
                  return 'Status is required';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor =
        isDark ? AppColors.brandPrimary : AppColors.brandPrimary;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightCardBackground;

    return Container(
      height: 50,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.darkWhiteText,
                  ),
                ),
              )
            : Text(
                RegisterPageProvider.saveChanges,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required IconData prefixIcon,
    required Widget child,
  }) {
    return Padding(
      padding: _fieldPadding,
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            contentPadding: _dropdownContentPadding,
            border: OutlineInputBorder(borderRadius: _borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBackgroundColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(RegisterPageProvider.editTitle),
            backgroundColor: cardBackgroundColor,
            elevation: 0,
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddUserAddressPage(user: user!),
                    ),
                  );
                  if (result == true) {
                    // Address was added successfully
                    AppSnackBar.showSnackBar(
                      context,
                      'Success',
                      'Address added successfully',
                      ContentType.success,
                    );
                    await getUserAddresses(user!.id);
                  }
                },
                child: Text(
                  'Add Address',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isLoading)
                TextButton(
                  onPressed: _handleSubmit,
                  child: Text(
                    RegisterPageProvider.saveChanges,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(),
                      _buildPersonalInfoSection(),
                      _buildAddressInfoSection(),
                      _buildSecuritySection(),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _id.dispose();
    _roleId.dispose();
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phoneNumber.dispose();
    _password.dispose();
    super.dispose();
  }
}
