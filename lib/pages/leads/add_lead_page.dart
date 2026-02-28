// ignore_for_file: no_leading_underscores_for_local_identifiers, prefer_final_fields, unused_field, unused_local_variable, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/controllers/lead/leadsController.dart';
import 'package:inhabit_realties/controllers/user/userController.dart';
import 'package:inhabit_realties/controllers/property/propertyController.dart';
import 'package:inhabit_realties/controllers/role/roleController.dart';
import 'package:inhabit_realties/models/auth/UsersModel.dart';
import 'package:inhabit_realties/models/lead/LeadsModel.dart';
import 'package:inhabit_realties/models/lead/LeadStatusModel.dart';
import 'package:inhabit_realties/models/lead/FollowUpStatusModel.dart';
import 'package:inhabit_realties/models/lead/ReferenceSourceModel.dart';
import 'package:inhabit_realties/models/property/PropertyModel.dart';
import 'package:inhabit_realties/models/role/RolesModel.dart';
import 'package:inhabit_realties/Enums/leadDesignationEnum.dart';
import 'package:inhabit_realties/pages/widgets/appSnackBar.dart';
import 'package:inhabit_realties/pages/widgets/appSpinner.dart';
import 'package:inhabit_realties/pages/widgets/formTextField.dart';
import 'package:inhabit_realties/providers/leads_page_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddLeadPage extends StatefulWidget {
  final LeadsModel? lead; // null for add, not null for edit

  const AddLeadPage({super.key, this.lead});

  @override
  State<AddLeadPage> createState() => _AddLeadPageState();
}

class _AddLeadPageState extends State<AddLeadPage> {
  // Convert controllers to late final to improve performance
  late final LeadsController _leadsController;
  late final UserController _userController;
  late final PropertyController _propertyController;
  late final RoleController _roleController;

  // Convert text controllers to late final
  late final TextEditingController _note;
  late final TextEditingController _altEmail;
  late final TextEditingController _altPhone;
  late final TextEditingController _landline;
  late final TextEditingController _website;
  late final TextEditingController _referredByFirstName;
  late final TextEditingController _referredByLastName;
  late final TextEditingController _referredByEmail;
  late final TextEditingController _referredByPhone;
  late final TextEditingController _referredByDesignation;
  late final TextEditingController _userSearchController;
  late final TextEditingController _referredByUserSearchController;
  late final TextEditingController _assignedToUserSearchController;
  late final TextEditingController _leadUserSearchController;
  late final TextEditingController _interestedPropertySearchController;
  late final TextEditingController _statusSearchController;
  late final TextEditingController _followUpStatusSearchController;
  late final TextEditingController _referenceSourceSearchController;
  final _formKey = GlobalKey<FormState>();

  // Add these constants at the class level
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

  // Form values
  String _selectedDesignation = LeadDesignation.buyer;
  String? _selectedStatus;
  String? _selectedFollowUpStatus;
  String? _selectedReferenceSource;
  String? _selectedInterestedProperty;
  String? _selectedReferredByUser;
  String? _selectedAssignedToUser;
  String? _selectedLeadUser;

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isDataLoading = true;

  // Data lists
  List<LeadStatusModel> _leadStatuses = [];
  List<FollowUpStatusModel> _followUpStatuses = [];
  List<ReferenceSourceModel> _referenceSources = [];
  List<UsersModel> _users = [];
  List<RolesModel> _roles = [];
  List<PropertyModel> _properties = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _isEditMode = widget.lead != null;
    _loadData();
    if (widget.lead != null) {
      _selectedDesignation =
          LeadDesignation.fromString(widget.lead!.leadDesignation);
    }
  }

  void _initializeControllers() {
    // Initialize all controllers
    _leadsController = LeadsController();
    _userController = UserController();
    _propertyController = PropertyController();
    _roleController = RoleController();

    _note = TextEditingController();
    _altEmail = TextEditingController();
    _altPhone = TextEditingController();
    _landline = TextEditingController();
    _website = TextEditingController();
    _referredByFirstName = TextEditingController();
    _referredByLastName = TextEditingController();
    _referredByEmail = TextEditingController();
    _referredByPhone = TextEditingController();
    _referredByDesignation = TextEditingController();
    _userSearchController = TextEditingController();
    _referredByUserSearchController = TextEditingController();
    _assignedToUserSearchController = TextEditingController();
    _leadUserSearchController = TextEditingController();
    _interestedPropertySearchController = TextEditingController();
    _statusSearchController = TextEditingController();
    _followUpStatusSearchController = TextEditingController();
    _referenceSourceSearchController = TextEditingController();
  }

  Future<void> _loadData() async {
    setState(() => _isDataLoading = true);

    await Future.wait([
      _loadLeadStatuses(),
      _loadFollowUpStatuses(),
      _loadReferenceSources(),
      _loadRoles(),
      _loadUsers(),
      _loadProperties(),
    ]);

    // Initialize form with default values
    if (_leadStatuses.isNotEmpty) {
      _selectedStatus = _leadStatuses.first.id;
    }
    if (_followUpStatuses.isNotEmpty) {
      _selectedFollowUpStatus = _followUpStatuses.first.id;
    }

    // Initialize form with existing data if editing
    if (_isEditMode && widget.lead != null) {
      _initializeFormWithExistingData();
    }

    if (mounted) {
      setState(() => _isDataLoading = false);
    }
  }

  void _initializeFormWithExistingData() {
    final lead = widget.lead!;
    _selectedDesignation = LeadDesignation.fromString(lead.leadDesignation);

    // Map status display names to IDs
    _selectedStatus = _findStatusIdByName(lead.leadStatus);
    _selectedFollowUpStatus = _findFollowUpStatusIdByName(lead.followUpStatus);

    _selectedReferenceSource = lead.referanceFrom?.id;
    _selectedInterestedProperty = lead.leadInterestedPropertyId;
    _selectedReferredByUser = lead.referredByUserId;
    _selectedAssignedToUser = lead.assignedToUserId;
    _selectedLeadUser = lead.userId;

    _note.text = lead.note ?? '';
    _altEmail.text = lead.leadAltEmail ?? '';
    _altPhone.text = lead.leadAltPhoneNumber ?? '';
    _landline.text = lead.leadLandLineNumber ?? '';
    _website.text = lead.leadWebsite ?? '';
    _referredByFirstName.text = lead.referredByUserFirstName ?? '';
    _referredByLastName.text = lead.referredByUserLastName ?? '';
    _referredByEmail.text = lead.referredByUserEmail ?? '';
    _referredByPhone.text = lead.referredByUserPhoneNumber ?? '';
    _referredByDesignation.text = lead.referredByUserDesignation ?? '';
  }

  // Helper method to find status ID by name
  String? _findStatusIdByName(String statusName) {
    try {
      final status = _leadStatuses.firstWhere(
        (status) => status.name.toLowerCase() == statusName.toLowerCase(),
        orElse: () => _leadStatuses.first,
      );
      return status.id;
    } catch (e) {
      return _leadStatuses.isNotEmpty ? _leadStatuses.first.id : null;
    }
  }

  // Helper method to find follow-up status ID by name
  String? _findFollowUpStatusIdByName(String statusName) {
    try {
      final status = _followUpStatuses.firstWhere(
        (status) => status.name.toLowerCase() == statusName.toLowerCase(),
        orElse: () => _followUpStatuses.first,
      );
      return status.id;
    } catch (e) {
      return _followUpStatuses.isNotEmpty ? _followUpStatuses.first.id : null;
    }
  }

  Future<void> _loadLeadStatuses() async {
    try {
      await _leadsController.loadLeadStatuses();
      if (mounted) {
        setState(() {
          _leadStatuses = _leadsController.leadStatuses;
        });
      }
    } catch (e) {
      // Handle error appropriately
    }
  }

  Future<void> _loadFollowUpStatuses() async {
    try {
      await _leadsController.loadFollowUpStatuses();
      if (mounted) {
        setState(() {
          _followUpStatuses = _leadsController.followUpStatuses;
        });
      }
    } catch (e) {
      // Handle error appropriately
    }
  }

  Future<void> _loadReferenceSources() async {
    try {
      await _leadsController.loadReferenceSources();
      if (mounted) {
        setState(() {
          _referenceSources = _leadsController.referenceSources;
        });
      }
    } catch (e) {
      // Handle error appropriately
    }
  }

  Future<void> _loadRoles() async {
    try {
      final response = await _roleController.getAllRoles();
      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          _roles = (response['data'] as List)
              .map((item) => RolesModel.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      // Handle error appropriately
    }
  }

  Future<void> _loadUsers() async {
    try {
      final response = await _userController.getAllUsers();
      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          _users = (response['data'] as List)
              .map((item) => UsersModel.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      // Handle error appropriately
    }
  }

  Future<void> _loadProperties() async {
    try {
      final response = await _propertyController.getAllProperties();
      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          _properties = (response['data'] as List)
              .map((item) => PropertyModel.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      // Handle error appropriately
    }
  }

  // Helper method to get current user ID from shared preferences
  Future<String> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = prefs.getString('currentUser') ?? "";
      if (currentUser.isNotEmpty) {
        final userData = jsonDecode(currentUser);
        return userData['_id'] ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _note.dispose();
    _altEmail.dispose();
    _altPhone.dispose();
    _landline.dispose();
    _website.dispose();
    _referredByFirstName.dispose();
    _referredByLastName.dispose();
    _referredByEmail.dispose();
    _referredByPhone.dispose();
    _referredByDesignation.dispose();
    _userSearchController.dispose();
    _referredByUserSearchController.dispose();
    _assignedToUserSearchController.dispose();
    _leadUserSearchController.dispose();
    _interestedPropertySearchController.dispose();
    _statusSearchController.dispose();
    _followUpStatusSearchController.dispose();
    _referenceSourceSearchController.dispose();
    super.dispose();
  }

  Future<void> _saveLead() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Get current user ID and token from shared preferences
      final currentUserId = await _getCurrentUserId();

      // Send the status IDs directly for both create and edit operations
      final leadStatusValue = _selectedStatus ?? '';
      final followUpStatusValue = _selectedFollowUpStatus ?? '';

      final lead = LeadsModel(
        id: _isEditMode ? widget.lead!.id : '',
        userId: _selectedLeadUser ?? currentUserId,
        leadDesignation: _selectedDesignation,
        leadInterestedPropertyId: _selectedInterestedProperty ?? '',
        leadStatus: leadStatusValue,
        referanceFrom: _selectedReferenceSource != null
            ? _referenceSources
                .firstWhere((r) => r.id == _selectedReferenceSource)
            : null,
        followUpStatus: followUpStatusValue,
        referredByUserId: _selectedReferredByUser != null &&
                _selectedReferredByUser!.isNotEmpty
            ? _selectedReferredByUser!
            : '',
        referredByUserFirstName: _referredByFirstName.text.isNotEmpty
            ? _referredByFirstName.text
            : null,
        referredByUserLastName: _referredByLastName.text.isNotEmpty
            ? _referredByLastName.text
            : null,
        referredByUserEmail:
            _referredByEmail.text.isNotEmpty ? _referredByEmail.text : null,
        referredByUserPhoneNumber:
            _referredByPhone.text.isNotEmpty ? _referredByPhone.text : null,
        referredByUserDesignation: _referredByDesignation.text.isNotEmpty
            ? _referredByDesignation.text
            : null,
        assignedByUserId: currentUserId,
        assignedToUserId: _selectedAssignedToUser ?? '',
        leadAltEmail: _altEmail.text.isNotEmpty ? _altEmail.text : null,
        leadAltPhoneNumber: _altPhone.text.isNotEmpty ? _altPhone.text : null,
        leadLandLineNumber: _landline.text.isNotEmpty ? _landline.text : null,
        leadWebsite: _website.text.isNotEmpty ? _website.text : null,
        note: _note.text.isNotEmpty ? _note.text : null,
        createdByUserId: currentUserId,
        updatedByUserId: currentUserId,
        published: true,
        createdAt: _isEditMode ? widget.lead!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (_isEditMode) {
        debugPrint('--- EDIT LEAD PAYLOAD ---');
        debugPrint(jsonEncode(lead.toJsonForEdit()));
        success = await _leadsController.editLead(lead);
      } else {
        success = await _leadsController.createLead(lead);
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        _showSnackBar(
          _isEditMode
              ? LeadsPageProvider.leadUpdatedSuccess
              : LeadsPageProvider.leadCreatedSuccess,
          ContentType.success,
        );
      } else {
        _showSnackBar(
          _isEditMode
              ? LeadsPageProvider.leadUpdateError
              : LeadsPageProvider.leadCreationError,
          ContentType.failure,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Error: ${e.toString()}',
        ContentType.failure,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper method to get status name by ID
  String _getStatusNameById(String? statusId) {
    if (statusId == null) return '';
    try {
      final status = _leadStatuses.firstWhere(
        (status) => status.id == statusId,
        orElse: () => _leadStatuses.first,
      );
      return status.name;
    } catch (e) {
      return _leadStatuses.isNotEmpty ? _leadStatuses.first.name : '';
    }
  }

  // Helper method to get follow-up status name by ID
  String _getFollowUpStatusNameById(String? statusId) {
    if (statusId == null) return '';
    try {
      final status = _followUpStatuses.firstWhere(
        (status) => status.id == statusId,
        orElse: () => _followUpStatuses.first,
      );
      return status.name;
    } catch (e) {
      return _followUpStatuses.isNotEmpty ? _followUpStatuses.first.name : '';
    }
  }

  void _showSnackBar(String message, ContentType contentType) {
    if (mounted) {
      AppSnackBar.showSnackBar(
        context,
        contentType == ContentType.success ? 'Success' : 'Error',
        message,
        contentType,
      );
    }
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

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: _headerSpacing),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? AppColors.brandSecondary : AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
          _buildSectionHeader(LeadsPageProvider.basicInfo),
          _buildDropdownField(
            labelText: 'Lead User',
            prefixIcon: CupertinoIcons.person,
            child: DropdownButtonFormField2<String?>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Lead User',
                prefixIcon: Icon(CupertinoIcons.person),
              ),
              value: _users.any((user) => user.id == _selectedLeadUser)
                  ? _selectedLeadUser
                  : null,
              items: [
                if (_selectedLeadUser != null &&
                    !_users.any((user) => user.id == _selectedLeadUser))
                  DropdownMenuItem<String?>(
                    value: _selectedLeadUser,
                    child: Text('Missing user (ID: $_selectedLeadUser)',
                        style: TextStyle(color: Colors.red)),
                  ),
                ...(_users.isNotEmpty
                    ? _users.map((user) {
                        return DropdownMenuItem<String>(
                          value: user.id,
                          child: Text(
                              '${user.firstName} ${user.lastName} (${_getRoleNameById(user.role)})'),
                        );
                      })
                    : []),
              ],
              onChanged: (String? value) {
                setState(() => _selectedLeadUser = value);
              },
              dropdownSearchData: DropdownSearchData(
                searchController: _leadUserSearchController,
                searchInnerWidgetHeight: 50,
                searchInnerWidget: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextFormField(
                    controller: _leadUserSearchController,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: _dropdownContentPadding,
                      hintText: 'Search for a user...',
                      border: OutlineInputBorder(borderRadius: _borderRadius),
                    ),
                  ),
                ),
                searchMatchFn: (item, searchValue) {
                  if (item.value == null) return true;
                  try {
                    final user = _users.firstWhere((u) => u.id == item.value);
                    final fullName =
                        '${user.firstName} ${user.lastName}'.toLowerCase();
                    final email = user.email.toLowerCase();
                    final roleName = _getRoleNameById(user.role).toLowerCase();
                    return fullName.contains(searchValue.toLowerCase()) ||
                        email.contains(searchValue.toLowerCase()) ||
                        roleName.contains(searchValue.toLowerCase());
                  } catch (e) {
                    return false;
                  }
                },
              ),
              dropdownStyleData: const DropdownStyleData(
                maxHeight: 300,
                decoration: BoxDecoration(borderRadius: _borderRadius),
              ),
              menuItemStyleData: const MenuItemStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          _buildDesignationDropdown(),
          _buildDropdownField(
            labelText: 'Interested Property',
            prefixIcon: CupertinoIcons.home,
            child: DropdownButtonFormField2<String?>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Interested Property',
                prefixIcon: Icon(CupertinoIcons.home),
              ),
              value: _properties.any(
                      (property) => property.id == _selectedInterestedProperty)
                  ? _selectedInterestedProperty
                  : null,
              items: [
                if (_selectedInterestedProperty != null &&
                    !_properties.any((property) =>
                        property.id == _selectedInterestedProperty))
                  DropdownMenuItem<String?>(
                    value: _selectedInterestedProperty,
                    child: Text(
                        'Missing property (ID: $_selectedInterestedProperty)',
                        style: TextStyle(color: Colors.red)),
                  ),
                ...(_properties.isNotEmpty
                    ? _properties.map((property) {
                        return DropdownMenuItem<String>(
                          value: property.id,
                          child: Text(property.name),
                        );
                      })
                    : []),
              ],
              onChanged: (String? value) {
                setState(() => _selectedInterestedProperty = value);
              },
              dropdownSearchData: DropdownSearchData(
                searchController: _interestedPropertySearchController,
                searchInnerWidgetHeight: 50,
                searchInnerWidget: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextFormField(
                    controller: _interestedPropertySearchController,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: _dropdownContentPadding,
                      hintText: 'Search for a property...',
                      border: OutlineInputBorder(borderRadius: _borderRadius),
                    ),
                  ),
                ),
                searchMatchFn: (item, searchValue) {
                  if (item.value == null) return true;
                  try {
                    final property =
                        _properties.firstWhere((p) => p.id == item.value);
                    return property.name
                        .toLowerCase()
                        .contains(searchValue.toLowerCase());
                  } catch (e) {
                    return false;
                  }
                },
              ),
              dropdownStyleData: const DropdownStyleData(
                maxHeight: 300,
                decoration: BoxDecoration(borderRadius: _borderRadius),
              ),
              menuItemStyleData: const MenuItemStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          _buildDropdownField(
            labelText: LeadsPageProvider.status,
            prefixIcon: CupertinoIcons.flag,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: LeadsPageProvider.status,
                prefixIcon: const Icon(CupertinoIcons.flag),
              ),
              value: _leadStatuses.any((status) => status.id == _selectedStatus)
                  ? _selectedStatus
                  : null,
              items: _leadStatuses.isNotEmpty
                  ? _leadStatuses.map((status) {
                      return DropdownMenuItem<String>(
                        value: status.id,
                        child: Text(status.name),
                      );
                    }).toList()
                  : [],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _selectedStatus = value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LeadsPageProvider.statusValidationMessage;
                }
                return null;
              },
            ),
          ),
          _buildDropdownField(
            labelText: LeadsPageProvider.followUpStatus,
            prefixIcon: CupertinoIcons.arrow_clockwise,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: LeadsPageProvider.followUpStatus,
                prefixIcon: const Icon(CupertinoIcons.arrow_clockwise),
              ),
              value: _followUpStatuses
                      .any((status) => status.id == _selectedFollowUpStatus)
                  ? _selectedFollowUpStatus
                  : null,
              items: _followUpStatuses.isNotEmpty
                  ? _followUpStatuses.map((status) {
                      return DropdownMenuItem<String>(
                        value: status.id,
                        child: Text(status.name),
                      );
                    }).toList()
                  : [],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _selectedFollowUpStatus = value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LeadsPageProvider.followUpStatusValidationMessage;
                }
                return null;
              },
            ),
          ),
          _buildDropdownField(
            labelText:
                '${LeadsPageProvider.referenceSource} ${LeadsPageProvider.optional}',
            prefixIcon: CupertinoIcons.link,
            child: DropdownButtonFormField<String?>(
              decoration: InputDecoration(
                labelText:
                    '${LeadsPageProvider.referenceSource} ${LeadsPageProvider.optional}',
                prefixIcon: const Icon(CupertinoIcons.link),
              ),
              value: _referenceSources
                      .any((source) => source.id == _selectedReferenceSource)
                  ? _selectedReferenceSource
                  : null,
              items: [
                DropdownMenuItem<String?>(
                    value: null, child: Text(LeadsPageProvider.none)),
                ...(_referenceSources.isNotEmpty
                    ? _referenceSources.map((source) {
                        return DropdownMenuItem<String>(
                          value: source.id,
                          child: Text(source.name),
                        );
                      })
                    : []),
              ],
              onChanged: (String? value) {
                setState(() => _selectedReferenceSource = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(LeadsPageProvider.contactInfo),
          FormTextField(
            textEditingController: _altEmail,
            labelText:
                '${LeadsPageProvider.alternativeEmail} ${LeadsPageProvider.optional}',
            prefixIcon: CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return LeadsPageProvider.emailValidationMessage;
                }
              }
              return null;
            },
          ),
          FormTextField(
            textEditingController: _altPhone,
            labelText:
                '${LeadsPageProvider.alternativePhone} ${LeadsPageProvider.optional}',
            prefixIcon: CupertinoIcons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^\+?[\d\s-]+$').hasMatch(value)) {
                  return LeadsPageProvider.phoneValidationMessage;
                }
              }
              return null;
            },
          ),
          FormTextField(
            textEditingController: _landline,
            labelText:
                '${LeadsPageProvider.landline} ${LeadsPageProvider.optional}',
            prefixIcon: CupertinoIcons.phone,
            keyboardType: TextInputType.phone,
          ),
          FormTextField(
            textEditingController: _website,
            labelText:
                '${LeadsPageProvider.website} ${LeadsPageProvider.optional}',
            prefixIcon: CupertinoIcons.globe,
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^https?:\/\/.*').hasMatch(value)) {
                  return LeadsPageProvider.websiteValidationMessage;
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentInfoSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(LeadsPageProvider.assignmentInfo),
          _buildAssignedToDropdown(),
        ],
      ),
    );
  }

  Widget _buildReferralInfoSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(LeadsPageProvider.referralInfo),
          _buildDropdownField(
            labelText:
                '${LeadsPageProvider.referredBy} ${LeadsPageProvider.optional}',
            prefixIcon: CupertinoIcons.person_add,
            child: DropdownButtonFormField2<String?>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText:
                    '${LeadsPageProvider.referredBy} ${LeadsPageProvider.optional}',
                prefixIcon: const Icon(CupertinoIcons.person_add),
              ),
              value: _users.any((user) => user.id == _selectedReferredByUser)
                  ? _selectedReferredByUser
                  : null,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(LeadsPageProvider.none),
                ),
                if (_selectedReferredByUser != null &&
                    !_users.any((user) => user.id == _selectedReferredByUser))
                  DropdownMenuItem<String?>(
                    value: _selectedReferredByUser,
                    child: Text('Missing user (ID: $_selectedReferredByUser)',
                        style: TextStyle(color: Colors.red)),
                  ),
                ...(_users.isNotEmpty
                    ? _users.map((user) {
                        return DropdownMenuItem<String>(
                          value: user.id,
                          child: Text(
                              '${user.firstName} ${user.lastName} (${_getRoleNameById(user.role)})'),
                        );
                      })
                    : []),
              ],
              onChanged: (String? value) {
                setState(() {
                  _selectedReferredByUser = value;
                  // Clear referral fields if a user is selected
                  if (value != null && value.isNotEmpty) {
                    _referredByFirstName.clear();
                    _referredByLastName.clear();
                    _referredByEmail.clear();
                    _referredByPhone.clear();
                    _referredByDesignation.clear();
                  }
                });
              },
            ),
          ),
          // Show referral fields if no referred by user is selected OR if there's manual referral data
          if (_selectedReferredByUser == null ||
              _selectedReferredByUser!.isEmpty ||
              _referredByFirstName.text.isNotEmpty ||
              _referredByLastName.text.isNotEmpty ||
              _referredByEmail.text.isNotEmpty ||
              _referredByPhone.text.isNotEmpty ||
              _referredByDesignation.text.isNotEmpty) ...[
            FormTextField(
              textEditingController: _referredByFirstName,
              labelText:
                  '${LeadsPageProvider.referredBy} First Name ${LeadsPageProvider.optional}',
              prefixIcon: CupertinoIcons.person,
              keyboardType: TextInputType.name,
            ),
            FormTextField(
              textEditingController: _referredByLastName,
              labelText:
                  '${LeadsPageProvider.referredBy} Last Name ${LeadsPageProvider.optional}',
              prefixIcon: CupertinoIcons.person,
              keyboardType: TextInputType.name,
            ),
            FormTextField(
              textEditingController: _referredByEmail,
              labelText:
                  '${LeadsPageProvider.referrerEmail} ${LeadsPageProvider.optional}',
              prefixIcon: CupertinoIcons.mail,
              keyboardType: TextInputType.emailAddress,
            ),
            FormTextField(
              textEditingController: _referredByPhone,
              labelText:
                  '${LeadsPageProvider.referrerPhone} ${LeadsPageProvider.optional}',
              prefixIcon: CupertinoIcons.phone,
              keyboardType: TextInputType.phone,
            ),
            FormTextField(
              textEditingController: _referredByDesignation,
              labelText:
                  '${LeadsPageProvider.referrerDesignation} ${LeadsPageProvider.optional}',
              prefixIcon: CupertinoIcons.briefcase,
              keyboardType: TextInputType.text,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignedToDropdown() {
    final salesRoleId = _getSalesRoleId();
    final salesUsers = salesRoleId != null
        ? _users.where((user) => user.role == salesRoleId).toList()
        : <UsersModel>[];

    return _buildDropdownField(
      labelText:
          '${LeadsPageProvider.assignedTo} ${LeadsPageProvider.optional}',
      prefixIcon: CupertinoIcons.person_crop_circle_badge_checkmark,
      child: DropdownButtonFormField2<String?>(
        value: _users.any((user) => user.id == _selectedAssignedToUser)
            ? _selectedAssignedToUser
            : null,
        decoration: InputDecoration(
          labelText:
              '${LeadsPageProvider.assignedTo} ${LeadsPageProvider.optional}',
          hintText: 'Select a sales person...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          prefixIcon:
              const Icon(CupertinoIcons.person_crop_circle_badge_checkmark),
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(LeadsPageProvider.none),
          ),
          ...salesUsers.map((user) {
            return DropdownMenuItem<String>(
              value: user.id,
              child: Text('${user.firstName} ${user.lastName}'),
            );
          }),
        ],
        onChanged: (value) {
          setState(() {
            _selectedAssignedToUser = value;
          });
        },
        buttonStyleData: const ButtonStyleData(
          padding: EdgeInsets.only(right: 8),
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(Icons.arrow_drop_down),
          iconSize: 24,
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        dropdownSearchData: DropdownSearchData(
          searchController: _assignedToUserSearchController,
          searchInnerWidgetHeight: 50,
          searchInnerWidget: Container(
            height: 50,
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 4,
              right: 8,
              left: 8,
            ),
            child: TextFormField(
              expands: true,
              maxLines: null,
              controller: _assignedToUserSearchController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                hintText: 'Search users...',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) {
            if (item.value == null) return true;
            try {
              final user = salesUsers.firstWhere((u) => u.id == item.value);
              final fullName =
                  '${user.firstName} ${user.lastName}'.toLowerCase();
              return fullName.contains(searchValue.toLowerCase());
            } catch (e) {
              return false;
            }
          },
        ),
        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            _assignedToUserSearchController.clear();
          }
        },
      ),
    );
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(LeadsPageProvider.additionalInfo),
          FormTextField(
            textEditingController: _note,
            labelText:
                '${LeadsPageProvider.note} ${LeadsPageProvider.optional}',
            prefixIcon: CupertinoIcons.doc_text,
            keyboardType: TextInputType.multiline,
          ),
        ],
      ),
    );
  }

  // Helper method to get sales role ID
  String? _getSalesRoleId() {
    // Look for roles that might be sales-related (case-insensitive)
    final salesRole = _roles.firstWhere(
      (role) =>
          role.name.toLowerCase().contains('sales') ||
          role.name.toLowerCase().contains('agent') ||
          role.name.toLowerCase().contains('representative'),
      orElse: () => RolesModel(
        id: '',
        name: '',
        description: '',
        createdByUserId: '',
        updatedByUserId: '',
        published: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return salesRole.id.isNotEmpty ? salesRole.id : null;
  }

  // Helper method to get role name by ID
  String _getRoleNameById(String roleId) {
    try {
      if (_roles.isEmpty) return 'Unknown';

      final role = _roles.firstWhere(
        (role) => role.id == roleId,
        orElse: () => RolesModel(
          id: '',
          name: 'Unknown',
          description: '',
          createdByUserId: '',
          updatedByUserId: '',
          published: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return role.name;
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildDesignationDropdown() {
    // Normalize the selected designation to ensure it matches the enum values
    final normalizedSelectedDesignation =
        LeadDesignation.fromString(_selectedDesignation);

    return _buildDropdownField(
      labelText: 'Designation',
      prefixIcon: CupertinoIcons.person_2,
      child: DropdownButtonFormField<String>(
        value: normalizedSelectedDesignation,
        decoration: const InputDecoration(
          labelText: 'Designation',
          prefixIcon: Icon(CupertinoIcons.person_2),
        ),
        items: LeadDesignation.values.map((designation) {
          return DropdownMenuItem<String>(
            value: designation,
            child: Text(LeadDesignation.getLabel(designation)),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedDesignation = value!;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a designation';
          }
          return null;
        },
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? LeadsPageProvider.editTitle : LeadsPageProvider.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveLead,
              child: Text(
                LeadsPageProvider.saveButton,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading || _isDataLoading
          ? const Center(child: AppSpinner())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    _buildContactInfoSection(),
                    _buildReferralInfoSection(),
                    _buildAssignmentInfoSection(),
                    _buildNotesSection(),
                    const SizedBox(height: 50), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }
}
