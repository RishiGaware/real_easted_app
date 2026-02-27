import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/controllers/user/userController.dart';
import 'package:inhabit_realties/controllers/role/roleController.dart';
import 'package:inhabit_realties/models/auth/UsersModel.dart';
import 'package:inhabit_realties/models/role/RolesModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:inhabit_realties/controllers/address/userAddressController.dart';
import 'package:inhabit_realties/models/address/UserAddressModel.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;

  const UserDetailsPage({super.key, required this.userId});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage>
    with TickerProviderStateMixin {
  final UserController _userController = UserController();
  final RoleController _roleController = RoleController();
  final UserAddressController _userAddressController = UserAddressController();

  UsersModel? _user;
  RolesModel? _role;
  List<UserAddressModel> _addresses = [];
  bool _isLoading = true;
  String? _error;

  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _loadUserDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load user data
      final userResponse =
          await _userController.getUsersByUserId(widget.userId);
      if (userResponse['statusCode'] == 200 && userResponse['data'] != null) {
        _user = UsersModel.fromJson(userResponse['data']);

        // Load role data
        if (_user!.role.isNotEmpty) {
          try {
            final roleResponse = await _roleController.getRoleById(_user!.role);
            if (roleResponse['statusCode'] == 200 &&
                roleResponse['data'] != null) {
              _role = RolesModel.fromJson(roleResponse['data']);
            }
          } catch (e) {
            // Error loading role
          }
        }

        // Load address data
        try {
          final addressResponse = await _userAddressController.getUserAddressByUserId(widget.userId);
          if (addressResponse['statusCode'] == 200 && addressResponse['data'] != null) {
            if (addressResponse['data'] is List) {
              _addresses = (addressResponse['data'] as List)
                  .map((item) => UserAddressModel.fromJson(item))
                  .where((address) => address.published)
                  .toList();
            } else {
              final address = UserAddressModel.fromJson(addressResponse['data']);
              _addresses = address.published ? [address] : [];
            }
          }
        } catch (e) {
          // Error loading addresses
        }
      } else {
        throw Exception('Failed to load user data');
      }

      setState(() {
        _isLoading = false;
      });

      _animationController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _cardAnimationController.forward();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkCardBackground : Colors.white;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _cardAnimationController.value)),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    backgroundColor,
                    backgroundColor.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color.withOpacity(0.2),
                                    color.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (onTap != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  CupertinoIcons.chevron_right,
                                  color: color,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        content,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'User Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 24,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/users/edit',
                    arguments: {'userId': widget.userId},
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.pencil,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading user details...',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.lightDanger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          color: AppColors.lightDanger,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading user',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _loadUserDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _user == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.brandPrimary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              CupertinoIcons.person_crop_circle_badge_xmark,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'User not found',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The requested user could not be found',
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Header
                              AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: Container(
                                      margin: const EdgeInsets.all(20),
                                      padding: const EdgeInsets.all(30),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.brandGradient,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.brandPrimary
                                                .withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                            ),
                                            child: Icon(
                                              CupertinoIcons.person_fill,
                                              color: Colors.white,
                                              size: 50,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            '${_user!.firstName} ${_user!.lastName}',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _user!.email,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Personal Information Card
                              _buildInfoCard(
                                title: 'Personal Information',
                                icon: CupertinoIcons.person,
                                color: AppColors.brandPrimary,
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(
                                        'First Name', _user!.firstName),
                                    _buildInfoRow('Last Name', _user!.lastName),
                                    _buildInfoRow('Email', _user!.email),
                                    _buildInfoRow('Phone', _user!.phoneNumber),
                                    _buildInfoRow('User ID', _user!.id),
                                  ],
                                ),
                              ),

                              // Role Information Card
                              if (_role != null)
                                _buildInfoCard(
                                  title: 'Role Information',
                                  icon: CupertinoIcons.person_2,
                                  color: AppColors.lightSuccess,
                                  content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow('Role Name', _role!.name),
                                      _buildInfoRow('Role ID', _role!.id),
                                      if (_role!.description.isNotEmpty)
                                        _buildInfoRow(
                                            'Description', _role!.description),
                                    ],
                                  ),
                                ),

                                // Account Status Card
                              _buildInfoCard(
                                title: 'Account Status',
                                icon: CupertinoIcons.checkmark_shield,
                                color: _user!.published
                                    ? AppColors.lightSuccess
                                    : AppColors.lightDanger,
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(
                                        'Status',
                                        _user!.published
                                            ? 'Active'
                                            : 'Inactive'),
                                    _buildInfoRow(
                                        'Created',
                                        _user!.createdAt
                                            .toString()
                                            .split(' ')[0]),
                                    _buildInfoRow(
                                        'Last Updated',
                                        _user!.updatedAt
                                            .toString()
                                            .split(' ')[0]),
                                  ],
                                ),
                              ),

                              // Address Card
                              if (_addresses.isNotEmpty) ...[
                                for (var address in _addresses)
                                  _buildInfoCard(
                                    title: 'Address Information',
                                    icon: CupertinoIcons.location_solid,
                                    color: AppColors.brandPrimary,
                                    content: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildInfoRow('Full Address', address.fullAddress.isNotEmpty ? address.fullAddress : "${address.address.street}, ${address.address.city}, ${address.address.zipOrPinCode}"),
                                      ],
                                    ),
                                  ),
                              ] else ...[
                                _buildInfoCard(
                                  title: 'Address Information',
                                  icon: CupertinoIcons.location,
                                  color: Colors.grey,
                                  content: Text('No address added.', style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14)),
                                ),
                              ],

                              // Documents Card (placeholder for future functionality)
                              _buildInfoCard(
                                title: 'Documents',
                                icon: CupertinoIcons.doc_text,
                                color: AppColors.lightWarning,
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.info_circle,
                                          color: AppColors.lightWarning,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Document management functionality coming soon!',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: textColor.withOpacity(0.7),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Document management coming soon!'),
                                      backgroundColor: AppColors.lightWarning,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}
