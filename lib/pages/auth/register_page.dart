// ignore_for_file: no_leading_underscores_for_local_identifiers, prefer_final_fields, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/controllers/auth/authController.dart';
import 'package:inhabit_realties/controllers/role/roleController.dart';
import 'package:inhabit_realties/models/role/RolesModel.dart';
import 'package:inhabit_realties/pages/widgets/appSnackBar.dart';
import 'package:inhabit_realties/pages/widgets/formTextField.dart';
import 'package:inhabit_realties/providers/register_page_provider.dart';
import 'package:inhabit_realties/constants/role_utils.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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

  final AuthController _authController = AuthController();
  final RoleController _roleController = RoleController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _roleId = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _phoneNumber = TextEditingController();
  final TextEditingController _password = TextEditingController();

  String? selectedRoleId;
  List<RolesModel> roles = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await RoleUtils.initializeCurrentUser();
    await _loadRoles();
  }

  Future<void> _loadRoles() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await _roleController.getAllRoles();
      if (!mounted) return;

      if (response['statusCode'] == 200) {
        final data = response['data'];
        if (data != null && data.isNotEmpty) {
          setState(() {
            roles = List<RolesModel>.from(
              data.map((item) => RolesModel.fromJson(item)),
            );

            // Filter roles if the current user is an Executive
            if (RoleUtils.isExecutive()) {
              roles = roles.where((role) {
                final roleName = role.name.toLowerCase();
                return roleName == 'user';
              }).toList();
            }
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
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final response = await _authController.register(
        _roleId.text.trim(),
        _email.text.trim(),
        _firstName.text.trim(),
        _lastName.text.trim(),
        _phoneNumber.text.trim(),
        _password.text.trim(),
      );

      if (!mounted) return;

      if (response['statusCode'] == 200) {
        AppSnackBar.showSnackBar(
          context,
          'Success',
          RegisterPageProvider.registrationSuccess,
          ContentType.success,
        );
        final route = RoleUtils.isExecutive() ? '/customers' : '/users';
        Navigator.pushReplacementNamed(context, route);
      } else {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          response['message'] ?? RegisterPageProvider.registrationError,
          ContentType.failure,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showSnackBar(
        context,
        'Error',
        RegisterPageProvider.registrationError,
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return RegisterPageProvider.passwordValidationMessage;
              }
              if (value.length < 6) {
                return RegisterPageProvider.passwordValidationMessage;
              }
              return null;
            },
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
                RegisterPageProvider.registerButton,
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

    return Stack(
      children: [
        Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(RegisterPageProvider.title),
            backgroundColor: backgroundColor,
            elevation: 0,
            centerTitle: true,
          ),
          body: SafeArea(
            child: SelectionArea(
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
                      _buildSecuritySection(),
                      _buildSubmitButton(),
                    ],
                  ),
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
    _roleId.dispose();
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phoneNumber.dispose();
    _password.dispose();
    super.dispose();
  }
}
