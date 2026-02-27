import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/services/meeting_schedule_service.dart';
import 'package:inhabit_realties/constants/role_utils.dart';
import 'package:inhabit_realties/pages/widgets/formTextField.dart';
import 'package:inhabit_realties/pages/widgets/appSpinner.dart';
import 'package:inhabit_realties/pages/widgets/app_search_bar.dart';
import 'package:inhabit_realties/controllers/user/userController.dart';
import 'package:inhabit_realties/controllers/property/propertyController.dart';
import 'package:inhabit_realties/controllers/meeting_schedule_status/meeting_schedule_status_controller.dart';
import 'package:inhabit_realties/controllers/role/roleController.dart';
import 'package:inhabit_realties/controllers/propertyType/propertyTypeController.dart';
import 'package:inhabit_realties/models/auth/UsersModel.dart';
import 'package:inhabit_realties/models/property/PropertyModel.dart';
import 'package:inhabit_realties/models/address/Address.dart';
import 'package:inhabit_realties/models/meetingSchedule/MeetingScheduleStatusModel.dart';
import 'package:inhabit_realties/models/role/RolesModel.dart';
import 'package:inhabit_realties/models/propertyType/PropertyTypeModel.dart';
import 'package:inhabit_realties/pages/users/widgets/role.dart';
import 'package:inhabit_realties/pages/properties/widgets/propertyTypeContainer.dart';
import 'package:inhabit_realties/pages/meetingSchedule/select_property_page.dart';
import 'package:inhabit_realties/Enums/propertyStatusEnum.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inhabit_realties/pages/widgets/appSnackBar.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class CreateMeetingPage extends StatefulWidget {
  const CreateMeetingPage({super.key});

  @override
  State<CreateMeetingPage> createState() => _CreateMeetingPageState();
}

class _CreateMeetingPageState extends State<CreateMeetingPage> {
  final _formKey = GlobalKey<FormState>();
  final MeetingScheduleService _meetingService = MeetingScheduleService();
  final UserController _userController = UserController();
  final PropertyController _propertyController = PropertyController();
  final MeetingScheduleStatusController _statusController =
      MeetingScheduleStatusController();
  final RoleController _roleController = RoleController();
  final PropertyTypeController _propertyTypeController =
      PropertyTypeController();

  // Step management
  int _currentStep =
      0; // 0: Customer Selection, 1: Property Selection, 2: Meeting Details

  // Customer selection data
  List<UsersModel> _customers = [];
  List<UsersModel> _filteredCustomers = [];
  List<String> _selectedCustomerIds = [];
  List<RolesModel> _roles = [];
  String _selectedRoleId = '0';

  // Property selection data
  String? _selectedPropertyId;
  List<PropertyModel> _properties = [];
  List<PropertyTypeModel> _propertyTypes = [];
  String? _selectedPropertyTypeId;
  String? _selectedPropertyStatus;

  // Meeting details data
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  String? _selectedStatus;
  List<MeetingScheduleStatusModel> _statuses = [];
  bool _isLoading = false;
  bool _isDataLoading = true;

  // Search controllers
  final TextEditingController _customerSearchController =
      TextEditingController();
  final TextEditingController _propertySearchController =
      TextEditingController();

  // UI Constants
  static const EdgeInsets _fieldPadding = EdgeInsets.only(
    top: 20,
    left: 15,
    right: 15,
  );
  static const double _sectionSpacing = 25.0;
  static const EdgeInsets _sectionPadding = EdgeInsets.only(
    bottom: _sectionSpacing,
  );

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    _customerSearchController.dispose();
    _propertySearchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isDataLoading = true;
      });

  

      await Future.wait([
        _loadCustomers(),
        _loadRoles(),
        _loadStatuses(),
        _loadProperties(),
        _loadPropertyTypes(),
      ]);

      

      if (mounted) {
        setState(() {
          _isDataLoading = false;
          _filteredCustomers = List.from(_customers);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDataLoading = false;
        });
        AppSnackBar.showSnackBar(
          context, 
          'Error', 
          'Error initializing: $e', 
          ContentType.failure
        );
      }
    }
  }

  Future<void> _loadStatuses() async {
    try {
      final response = await _statusController.getAllMeetingScheduleStatuses();

      if (response['statusCode'] == 200 && mounted) {
        final data = response['data'] as List;

        setState(() {
          _statuses = data
              .map((item) => MeetingScheduleStatusModel.fromJson(item))
              .toList();
        });

      } else {

      }
    } catch (e) {

      // Handle error silently
    }
  }

  Future<void> _loadCustomers() async {
    try {

      final response = await _userController.getAllUsers();

      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          _customers = (response['data'] as List)
              .map((item) => UsersModel.fromJson(item))
              .toList();
        });

      }
    } catch (e) {

      // Handle error silently
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
      // Handle error silently
    }
  }

  Future<void> _loadPropertiesWithFilters() async {
    try {
      // Build filter parameters
      Map<String, dynamic> filters = {};

      if (_selectedPropertyTypeId != null && _selectedPropertyTypeId != 'all') {
        filters['propertyTypeId'] = _selectedPropertyTypeId;
      }

      if (_selectedPropertyStatus != null) {
        filters['propertyStatus'] = _selectedPropertyStatus!;
      }

      // For now, we'll filter client-side since the API expects POST with body
      // In a real implementation, you'd call a filtered API endpoint
      final response = await _propertyController.getAllProperties();
      if (response['statusCode'] == 200 && mounted) {
        List<PropertyModel> allProperties = (response['data'] as List)
            .map((item) => PropertyModel.fromJson(item))
            .toList();

        // Apply filters client-side
        List<PropertyModel> filteredProperties =
            allProperties.where((property) {
          // Property type filter
          if (_selectedPropertyTypeId != null &&
              _selectedPropertyTypeId != 'all') {
            if (property.propertyTypeId != _selectedPropertyTypeId) {
              return false;
            }
          }

          // Property status filter
          if (_selectedPropertyStatus != null) {
            if (property.propertyStatus != _selectedPropertyStatus!) {
              return false;
            }
          }

          return true;
        }).toList();

        setState(() {
          _properties = filteredProperties;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadPropertyTypes() async {
    try {
      final response = await _propertyTypeController.getAllPropertyTypes();
      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          _propertyTypes = (response['data'] as List)
              .map((item) => PropertyTypeModel.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      // Handle error silently
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

      // Handle error silently
    }
  }

  void _handleSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = List.from(_customers);
      } else {
        _filteredCustomers = _customers.where((customer) {
          final name =
              '${customer.firstName} ${customer.lastName}'.toLowerCase();
          final email = customer.email.toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || email.contains(searchLower);
        }).toList();
      }
    });
  }

  void _handlePropertySearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _properties = List.from(_properties);
      } else {
        _properties = _properties.where((property) {
          final name = property.name.toString().toLowerCase();
          final address = _getFormattedAddressString(property.propertyAddress)
              .toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || address.contains(searchLower);
        }).toList();
      }
    });
  }

  String _getFormattedAddressString(Address address) {
    final List<String> addressParts = [];

    if (address.street.isNotEmpty) addressParts.add(address.street);
    if (address.area.isNotEmpty) addressParts.add(address.area);
    if (address.city.isNotEmpty) addressParts.add(address.city);
    if (address.state.isNotEmpty) addressParts.add(address.state);
    if (address.zipOrPinCode.isNotEmpty) addressParts.add(address.zipOrPinCode);
    if (address.country.isNotEmpty) addressParts.add(address.country);

    return addressParts.join(', ');
  }

  Future<void> _loadCustomersByRole(String roleId) async {
    try {
      final response = roleId == '0'
          ? await _userController.getAllUsers()
          : await _userController.getUsersByRoleId(roleId);

      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          _customers = (response['data'] as List)
              .map((item) => UsersModel.fromJson(item))
              .toList();
          _filteredCustomers = List.from(_customers);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _proceedToMeetingDetails() {
    if (_selectedCustomerIds.isEmpty) {
      AppSnackBar.showSnackBar(
        context, 
        'Validation Error', 
        'Please select at least one customer', 
        ContentType.warning
      );
      return;
    }

    setState(() {
      _currentStep = 1; // Move to property selection step
    });
  }

  void _goBackToCustomerSelection() {
    setState(() {
      _currentStep = 0; // Go back to customer selection step
    });
  }

  void _goToPropertySelection() {
    setState(() {
      _currentStep = 1; // Go to property selection step
    });
  }

  void _proceedToMeetingDetailsFromProperty() {
    setState(() {
      _currentStep = 2; // Move to meeting details step
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              hourMinuteTextStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              helpTextStyle: const TextStyle(fontSize: 12),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(0.8),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != _selectedStartTime && mounted) {
      setState(() {
        _selectedStartTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              hourMinuteTextStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              helpTextStyle: const TextStyle(fontSize: 12),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(0.8),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != _selectedEndTime && mounted) {
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  Future<void> _saveMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedStartTime == null) {
      AppSnackBar.showSnackBar(
        context, 
        'Validation Error', 
        'Please select date and start time', 
        ContentType.warning
      );
      return;
    }

    if (_selectedCustomerIds.isEmpty) {
      AppSnackBar.showSnackBar(
        context, 
        'Validation Error', 
        'Please select at least one customer', 
        ContentType.warning
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Calculate duration if both start and end time are provided
      String? calculatedDuration;
      if (_selectedStartTime != null && _selectedEndTime != null) {
        final startMinutes =
            _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
        final endMinutes =
            _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
        final durationMinutes = endMinutes - startMinutes;
        if (durationMinutes > 0) {
          final hours = durationMinutes ~/ 60;
          final minutes = durationMinutes % 60;
          calculatedDuration = '${hours}h ${minutes}m';
        }
      }

      final meetingData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'meetingDate': _selectedDate!.toIso8601String().split('T')[0],
        'startTime':
            '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}',
        'endTime': _selectedEndTime != null
            ? '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'duration': _durationController.text.isNotEmpty
            ? _durationController.text
            : calculatedDuration,
        'status': _selectedStatus,
        'customerIds': _selectedCustomerIds,
        'propertyId': _selectedPropertyId,
        'notes': _notesController.text,
      };

      final createdMeetings = await _meetingService.createMeeting(meetingData);

      if (mounted) {
        AppSnackBar.showSnackBar(
          context, 
          'Success', 
          createdMeetings.length == 1
              ? 'Meeting created successfully'
              : 'Meetings created successfully for ${createdMeetings.length} customers', 
          ContentType.success
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showSnackBar(
          context, 
          'Error', 
          'Error creating meeting: $e', 
          ContentType.failure
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCustomerSelectionStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: AppSearchBar(
              controller: _customerSearchController,
              onChanged: _handleSearch,
              hintText: 'Search customers...',
              onClear: () => _handleSearch(''),
            ),
          ),

          // Role Filter
          if (_roles.isNotEmpty)
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _roles.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 20 : 8,
                      right: index == _roles.length - 1 ? 20 : 8,
                    ),
                    child: InkWell(
                      onTap: () async {
                        setState(() {
                          _selectedRoleId = _roles[index].id;
                        });
                        await _loadCustomersByRole(_roles[index].id);
                      },
                      child: RoleContainer(
                        isActive: _selectedRoleId == _roles[index].id,
                        role: _roles[index].name,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Customer List
          Expanded(
            child: _filteredCustomers.isEmpty
                ? Center(
                    child: Text(
                      'No customers available',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      final isSelected =
                          _selectedCustomerIds.contains(customer.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            '${customer.firstName} ${customer.lastName}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            customer.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedCustomerIds.add(customer.id);
                                } else {
                                  _selectedCustomerIds.remove(customer.id);
                                }
                              });
                            },
                            activeColor: AppColors.brandPrimary,
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedCustomerIds.remove(customer.id);
                              } else {
                                _selectedCustomerIds.add(customer.id);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySelectionStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // Selected customers info
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.brandPrimary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.person_2,
                  color: AppColors.brandPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedCustomerIds.length} customer${_selectedCustomerIds.length == 1 ? '' : 's'} selected',
                    style: TextStyle(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: AppSearchBar(
              controller: _propertySearchController,
              onChanged: _handlePropertySearch,
              hintText: 'Search properties...',
              onClear: () => _handlePropertySearch(''),
            ),
          ),

          // Property Type Filter
          if (_propertyTypes.isNotEmpty)
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _propertyTypes.length + 1, // +1 for "All" option
                itemBuilder: (context, index) {
                  final isAllOption = index == 0;
                  final propertyType = isAllOption
                      ? PropertyTypeModel(
                          id: 'all',
                          typeName: 'ALL',
                          description: 'All types',
                          createdByUserId: '0',
                          updatedByUserId: '0',
                          published: true,
                        )
                      : _propertyTypes[index - 1];
                  final isSelected = _selectedPropertyTypeId == propertyType.id;

                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 20 : 8,
                      right: index == _propertyTypes.length ? 20 : 8,
                    ),
                    child: InkWell(
                      onTap: () async {
                        setState(() {
                          _selectedPropertyTypeId = propertyType.id;
                        });
                        await _loadPropertiesWithFilters();
                      },
                      child: PropertyTypeContainer(
                        isActive: isSelected,
                        propertyType: propertyType.typeName,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Property Status Filter
          Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount:
                  PropertyStatus.values.length + 1, // +1 for "All" option
              itemBuilder: (context, index) {
                final isAllOption = index == 0;
                final status =
                    isAllOption ? 'ALL' : PropertyStatus.values[index - 1];
                final isSelected = isAllOption
                    ? _selectedPropertyStatus == null
                    : _selectedPropertyStatus == status;

                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 20 : 8,
                    right: index == PropertyStatus.values.length ? 20 : 8,
                  ),
                  child: InkWell(
                    onTap: () async {
                      setState(() {
                        _selectedPropertyStatus = isAllOption ? null : status;
                      });
                      await _loadPropertiesWithFilters();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isSelected
                            ? (isDark
                                ? AppColors.brandSecondary
                                : AppColors.brandPrimary)
                            : (isDark
                                ? AppColors.darkCardBackground
                                : AppColors.lightCardBackground),
                      ),
                      child: Text(
                        status,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: isSelected
                                  ? AppColors.darkWhiteText
                                  : (isDark
                                      ? AppColors.darkWhiteText
                                      : AppColors.lightDarkText),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Property List
          Expanded(
            child: _properties.isEmpty
                ? Center(
                    child: Text(
                      'No properties available',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _properties.length,
                    itemBuilder: (context, index) {
                      final property = _properties[index];
                      final isSelected = _selectedPropertyId == property.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            '${property.name} - ${property.propertyAddress.city}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${property.propertyAddress.street}, ${property.propertyAddress.city}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightSuccess
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '₹${property.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.lightSuccess,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPrimary
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      property.propertyStatus,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.brandPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedPropertyId = property.id;
                                } else {
                                  _selectedPropertyId = null;
                                }
                              });
                            },
                            activeColor: AppColors.brandPrimary,
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedPropertyId = null;
                              } else {
                                _selectedPropertyId = property.id;
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectedCustomersSection(),
            _buildBasicInfoSection(),
            _buildDateTimeSection(),
            _buildStatusSection(),
            _buildPropertySection(),
            _buildNotesSection(),
            // Debug section
            if (_statuses.isEmpty || _customers.isEmpty || _properties.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Info:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Statuses: ${_statuses.length}'),
                        Text('Customers: ${_customers.length}'),
                        Text('Properties: ${_properties.length}'),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 50), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSelectedCustomersSection() {
    final selectedCustomers = _customers
        .where((customer) => _selectedCustomerIds.contains(customer.id))
        .toList();

    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Selected Customers'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${selectedCustomers.length} customer${selectedCustomers.length == 1 ? '' : 's'} selected',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _goBackToCustomerSelection,
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...selectedCustomers.map((customer) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.person_circle,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${customer.firstName} ${customer.lastName}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  customer.email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
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
          _buildSectionHeader('Basic Information'),
          FormTextField(
            textEditingController: _titleController,
            labelText: 'Meeting Title *',
            prefixIcon: CupertinoIcons.calendar,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a meeting title';
              }
              return null;
            },
          ),
          Padding(
            padding: _fieldPadding,
            child: TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: Icon(CupertinoIcons.doc_text),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Date & Time'),
          // Date Field
          Padding(
            padding: _fieldPadding,
            child: InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Meeting Date *',
                  prefixIcon: Icon(CupertinoIcons.calendar),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Select Date',
                ),
              ),
            ),
          ),
          // Start Time Field
          Padding(
            padding: _fieldPadding,
            child: InkWell(
              onTap: _selectStartTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Time *',
                  prefixIcon: Icon(CupertinoIcons.time),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedStartTime != null
                      ? _selectedStartTime!.format(context)
                      : 'Select Time',
                ),
              ),
            ),
          ),
          // End Time Field
          Padding(
            padding: _fieldPadding,
            child: InkWell(
              onTap: _selectEndTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'End Time (Optional)',
                  prefixIcon: Icon(CupertinoIcons.time_solid),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedEndTime != null
                      ? _selectedEndTime!.format(context)
                      : 'Select End Time',
                ),
              ),
            ),
          ),
          // Duration Field
          Padding(
            padding: _fieldPadding,
            child: TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (Optional)',
                prefixIcon: Icon(CupertinoIcons.clock),
                border: OutlineInputBorder(),
                hintText: 'e.g., 1h 30m, 2 hours',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Status'),
          Padding(
            padding: _fieldPadding,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Status *',
                prefixIcon: Icon(CupertinoIcons.flag),
                border: OutlineInputBorder(),
              ),
              value: _selectedStatus,
              items: _statuses.isEmpty
                  ? [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No statuses available'),
                      )
                    ]
                  : _statuses.map((status) {
                      return DropdownMenuItem<String>(
                        value: status.id,
                        child: Text(status.name),
                      );
                    }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a status';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Property'),
          Padding(
            padding: _fieldPadding,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Property (Optional)',
                prefixIcon: Icon(CupertinoIcons.house),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              value: _selectedPropertyId,
              isExpanded: true,
              items: _properties.isEmpty
                  ? [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No properties available'),
                      )
                    ]
                  : _properties.map((property) {
                      return DropdownMenuItem<String>(
                        value: property.id,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 250),
                          child: Text(
                            '${property.name} - ${property.propertyAddress.city}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      );
                    }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPropertyId = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Additional Information'),
          Padding(
            padding: _fieldPadding,
            child: TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(CupertinoIcons.doc_text),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 3,
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: _currentStep == 0
              ? () => Navigator.pop(context)
              : _currentStep == 1
                  ? () => _goBackToCustomerSelection()
                  : () => _goToPropertySelection(),
        ),
        title: Text(
          _currentStep == 0
              ? 'Select Customers'
              : _currentStep == 1
                  ? 'Select Property'
                  : 'Meeting Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        actions: [
          if (_currentStep == 0 && _selectedCustomerIds.isNotEmpty)
            TextButton(
              onPressed: _proceedToMeetingDetails,
              child: Text(
                'Proceed',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_currentStep == 1 && _selectedPropertyId != null)
            TextButton(
              onPressed: _proceedToMeetingDetailsFromProperty,
              child: Text(
                'Next',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_currentStep == 2 && !_isLoading)
            TextButton(
              onPressed: _saveMeeting,
              child: Text(
                'Schedule',
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
          : _currentStep == 0
              ? _buildCustomerSelectionStep()
              : _currentStep == 1
                  ? _buildPropertySelectionStep()
                  : _buildMeetingDetailsStep(),
    );
  }
}
