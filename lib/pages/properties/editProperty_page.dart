// ignore_for_file: no_leading_underscores_for_local_identifiers, prefer_final_fields, unused_field, unused_local_variable, use_build_context_synchronously

import 'package:country_state_city/models/city.dart';
import 'package:country_state_city/models/country.dart';
import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:inhabit_realties/controllers/property/propertyController.dart';
import 'package:inhabit_realties/controllers/propertyType/propertyTypeController.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/controllers/selectors/countryStateSelector.dart';
import 'package:inhabit_realties/controllers/user/userController.dart';
import 'package:inhabit_realties/models/auth/UsersModel.dart';
import 'package:inhabit_realties/models/propertyType/PropertyTypeModel.dart';
import 'package:inhabit_realties/models/property/PropertyModel.dart';
import 'package:inhabit_realties/models/property/PropertyImageModel.dart';
import 'package:inhabit_realties/pages/widgets/appSnackBar.dart';
import 'package:inhabit_realties/pages/widgets/appSpinner.dart';
import 'package:inhabit_realties/pages/widgets/formTextField.dart';
import 'package:inhabit_realties/providers/property_page_provider.dart';
import 'package:inhabit_realties/services/property/propertyImageService.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:country_state_city/country_state_city.dart'
    as country_state_selector;
import 'package:latlong2/latlong.dart';
import 'package:inhabit_realties/pages/properties/location_picker_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class EditPropertyPage extends StatefulWidget {
  const EditPropertyPage({super.key});

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  // Convert controllers to late final to improve performance
  late final PropertyController _propertyController;
  late final PropertyTypeController _propertyTypeController;
  late final UserController _userController;
  late final CountryStateSelector _countryStateSelector;
  late final PropertyImageService _propertyImageService;

  // Convert text controllers to late final
  late final TextEditingController _name;
  late final TextEditingController _propertyTypeId;
  late final TextEditingController _description;
  late final TextEditingController _street;
  late final TextEditingController _area;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _zipOrPinCode;
  late final TextEditingController _country;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _ownerId;
  late final TextEditingController _price;
  late final TextEditingController _propertyStatus;
  late final TextEditingController _bedRooms;
  late final TextEditingController _bathRooms;
  late final TextEditingController _areaInSquarFoot;
  late final TextEditingController _amenities;
  List<String> selectedAmenities = [];
  late final TextEditingController _listedDate;
  late final TextEditingController _countrySearchController;
  late final TextEditingController _stateSearchController;
  late final TextEditingController _citySearchController;
  late final TextEditingController _userSearchController;
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

  PropertyModel? property;
  String? selectedPropertyTypeId;
  String? selectedUserId;
  String? selectedPropertyStatus;
  DateTime? selectedListedDate;
  String? selectedCountry;
  String? selectedCountryCode;
  String? selectedState;
  String? selectedCity;
  bool selectedPublishedOrNot = true;

  bool isPageLoading = false;
  bool _initialized = false;
  bool _formReady = false; // New flag to track when form is ready
  List<PropertyTypeModel> propertyTypes = [];
  List<UsersModel> users = [];
  final List<String> propertyStatus = const ['FOR SALE', 'FOR RENT', 'SOLD'];
  List<Country> countries = [];
  List<country_state_selector.State> states = [];
  List<City> cities = [];

  // Comprehensive amenities list
  static const List<String> allAmenities = [
    // Basic Amenities
    'Air Conditioning',
    'Heating',
    'Central Air',
    'Ceiling Fans',
    'Furnished',
    'Unfurnished',
    'Pet Friendly',
    'No Pets Allowed',

    // Kitchen & Appliances
    'Dishwasher',
    'Microwave',
    'Refrigerator',
    'Oven',
    'Stove',
    'Garbage Disposal',
    'Kitchen Island',
    'Pantry',
    'Breakfast Bar',

    // Laundry
    'Washing Machine',
    'Dryer',
    'In-Unit Laundry',
    'Laundry Room',
    'Hookups',

    // Storage
    'Walk-in Closet',
    'Built-in Storage',
    'Storage Unit',
    'Attic',
    'Basement',
    'Garage',
    'Carport',
    'Bike Storage',

    // Flooring
    'Hardwood Floors',
    'Carpet',
    'Tile Floors',
    'Vinyl Floors',
    'Laminate Floors',

    // Special Features
    'Fireplace',
    'Balcony',
    'Patio',
    'Deck',
    'Garden',
    'Yard',
    'Pool',
    'Hot Tub',
    'Sauna',

    // Security & Access
    'Security System',
    'Doorman',
    'Concierge',
    'Elevator',
    'Stairs',
    'Gated Community',
    'Guest Parking',
    'Package Receiving',

    // Entertainment
    'Cable TV',
    'Internet/WiFi',
    'Home Theater',
    'Game Room',
    'Wine Cellar',

    // Outdoor & Recreation
    'BBQ Area',
    'Playground',
    'Tennis Court',
    'Basketball Court',
    'Gym',
    'Fitness Center',
    'Spa',
    'Golf Course Access',

    // Transportation
    'Public Transit Nearby',
    'Highway Access',
    'Airport Nearby',
    'Train Station Nearby',

    // Business & Work
    'Home Office',
    'Conference Room',
    'Business Center',
    'Coworking Space',

    // Accessibility
    'Wheelchair Accessible',
    'Elevator Access',
    'Ground Floor',
    'Ramp Access',

    // Energy & Utilities
    'Solar Panels',
    'Energy Efficient',
    'Smart Home Features',
    'Programmable Thermostat',

    // Views & Location
    'Mountain View',
    'Ocean View',
    'City View',
    'Garden View',
    'Waterfront',
    'Near Shopping',
    'Near Schools',
    'Near Parks',
  ];

  // Image management
  List<PropertyImageModel> propertyImages = [];
  List<File> newImages = [];
  bool isImageLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      property = ModalRoute.of(context)!.settings.arguments as PropertyModel;
      _initialized = true;
      _initializeControllers();
      _loadInitialData();
    }
  }

  void _initializeControllers() {
    // Initialize all controllers
    _propertyController = PropertyController();
    _propertyTypeController = PropertyTypeController();
    _userController = UserController();
    _countryStateSelector = CountryStateSelector();
    _propertyImageService = PropertyImageService();

    _name = TextEditingController();
    _propertyTypeId = TextEditingController();
    _description = TextEditingController();
    _street = TextEditingController();
    _area = TextEditingController();
    _city = TextEditingController();
    _state = TextEditingController();
    _zipOrPinCode = TextEditingController();
    _country = TextEditingController();
    _lat = TextEditingController();
    _lng = TextEditingController();
    _ownerId = TextEditingController();
    _price = TextEditingController();
    _propertyStatus = TextEditingController();
    _bedRooms = TextEditingController();
    _bathRooms = TextEditingController();
    _areaInSquarFoot = TextEditingController();
    _amenities = TextEditingController();
    _listedDate = TextEditingController();
    _countrySearchController = TextEditingController();
    _stateSearchController = TextEditingController();
    _citySearchController = TextEditingController();
    _userSearchController = TextEditingController();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => isPageLoading = true);

    try {
      // Load data in parallel
      await Future.wait([
        getAllPropertyTypes(),
        getAllUsers(),
        getAllCSC(),
        loadPropertyImages(),
      ]);
      // Set property details after loading data
      await setDetails();
      // Force refresh to ensure dropdowns show correct values
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Handle error appropriately
    } finally {
      if (mounted) {
        setState(() => isPageLoading = false);
      }
    }
  }

  Future<void> loadPropertyImages() async {
    if (property == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response =
          await _propertyImageService.getAllPropertyImagesByPropertyId(
        token,
        property!.id,
      );

      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          propertyImages = (response['data'] as List)
              .map((item) => PropertyImageModel.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> setDetails() async {
    if (property != null) {
      _name.text = property?.name ?? "";
      _propertyTypeId.text = property?.propertyTypeId ?? "";
      _description.text = property?.description ?? "";
      _street.text = property?.propertyAddress.street ?? "";
      _area.text = property?.propertyAddress.area ?? "";
      _city.text = property?.propertyAddress.city ?? "";
      _state.text = property?.propertyAddress.state ?? "";
      _zipOrPinCode.text = property?.propertyAddress.zipOrPinCode ?? "";
      _country.text = property?.propertyAddress.country ?? "";
      _lat.text = property?.propertyAddress.location.lat.toString() ?? "";
      _lng.text = property?.propertyAddress.location.lng.toString() ?? "";
      _ownerId.text = property?.owner ?? "";
      _price.text = property?.price.toString() ?? "";
      _propertyStatus.text = property?.propertyStatus ?? "";
      _bedRooms.text = property?.features.bedRooms.toString() ?? "";
      _bathRooms.text = property?.features.bathRooms.toString() ?? "";
      _areaInSquarFoot.text =
          property?.features.areaInSquarFoot.toString() ?? "";
      _amenities.text = property?.features.amenities.join(', ') ?? "";
      selectedAmenities = property?.features.amenities ?? [];
      _listedDate.text = property?.listedDate.toString().split(' ')[0] ?? "";

      selectedPropertyTypeId = property?.propertyTypeId;
      selectedUserId = property?.owner;
      selectedPropertyStatus = property?.propertyStatus;
      selectedListedDate = property?.listedDate;
      selectedCountry = property?.propertyAddress.country;
      selectedState = property?.propertyAddress.state;
      selectedCity = property?.propertyAddress.city;
      selectedPublishedOrNot = property?.published ?? true;

      // Validate that the selected user exists in the users list
      if (selectedUserId != null && selectedUserId!.isNotEmpty) {
        final userExists = users.any((user) => user.id == selectedUserId);
        if (!userExists) {
          // Keep the selectedUserId but it will show as "Unknown User" in dropdown
        }
      }

      // Validate that the selected property type exists in the property types list
      if (selectedPropertyTypeId != null &&
          selectedPropertyTypeId!.isNotEmpty) {
        final propertyTypeExists =
            propertyTypes.any((type) => type.id == selectedPropertyTypeId);
        if (!propertyTypeExists) {
          // Keep the selectedPropertyTypeId but it will show as "Unknown Type" in dropdown
        }
      }

      // Load states and cities if country and state are available
      if (selectedCountry != null && selectedCountry!.isNotEmpty) {
        try {
          final country = countries.firstWhere(
            (c) => c.name.toLowerCase() == selectedCountry!.toLowerCase(),
            orElse: () => countries.first,
          );

          // Load states for the selected country
          final statesList =
              await _countryStateSelector.getStatesByCountryCode(country);
          if (mounted) {
            setState(() {
              // Remove duplicates based on state name to prevent dropdown assertion errors
              states = statesList.fold<List<country_state_selector.State>>([],
                  (list, state) {
                if (!list.any((existingState) =>
                    existingState.name.toLowerCase() ==
                    state.name.toLowerCase())) {
                  list.add(state);
                }
                return list;
              });
            });
          }

          // Load cities if state is available
          if (selectedState != null && selectedState!.isNotEmpty) {
            try {
              final state = statesList.firstWhere(
                (s) => s.name.toLowerCase() == selectedState!.toLowerCase(),
                orElse: () => statesList.first,
              );

              final citiesList =
                  await _countryStateSelector.getCitiesByCountryCode(country);
              if (mounted) {
                setState(() {
                  // Remove duplicates based on city name to fix dropdown assertion error
                  cities = citiesList.fold<List<City>>([], (list, city) {
                    if (!list.any((existingCity) =>
                        existingCity.name.toLowerCase() ==
                        city.name.toLowerCase())) {
                      list.add(city);
                    }
                    return list;
                  });

                  // Additional safety check: if cities list is empty, reset selectedCity
                  if (cities.isEmpty && selectedCity != null) {
                    selectedCity = null;
                    _city.text = '';
                  }
                });
              }
            } catch (e) {
              // Handle error silently
            }
          }
        } catch (e) {
          // Handle error silently
        }
      }

      // Set form as ready after all data is loaded
      if (mounted) {
        setState(() {
          _formReady = true;
        });
      }
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _name.dispose();
    _propertyTypeId.dispose();
    _description.dispose();
    _street.dispose();
    _area.dispose();
    _city.dispose();
    _state.dispose();
    _zipOrPinCode.dispose();
    _country.dispose();
    _lat.dispose();
    _lng.dispose();
    _ownerId.dispose();
    _price.dispose();
    _propertyStatus.dispose();
    _bedRooms.dispose();
    _bathRooms.dispose();
    _areaInSquarFoot.dispose();
    _amenities.dispose();
    _listedDate.dispose();
    _countrySearchController.dispose();
    _stateSearchController.dispose();
    _citySearchController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> getAllPropertyTypes() async {
    try {
      final response = await _propertyTypeController.getAllPropertyTypes();
      // Property types response received

      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          propertyTypes = (response['data'] as List)
              .map((item) => PropertyTypeModel.fromJson(item))
              .toList();
        });
        // Property types loaded successfully
      } else {
        // Failed to load property types
      }
    } catch (e) {
      // Property types error
      if (mounted) {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          'Failed to load property types',
          ContentType.failure,
        );
      }
    }
  }

  Future<void> getAllUsers() async {
    try {
      final response = await _userController.getAllUsers();
      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          users = (response['data'] as List)
              .map((item) => UsersModel.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          'Failed to load users',
          ContentType.failure,
        );
      }
    }
  }

  Future<void> getAllCSC() async {
    try {
      final countriesList = await _countryStateSelector.getCountries();
      if (mounted) {
        setState(() {
          countries = countriesList;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          'Failed to load countries',
          ContentType.failure,
        );
      }
    }
  }

  Future<void> getStates(String countryCode) async {
    try {
      final country = await _countryStateSelector.getCountryByCode(countryCode);
      if (country != null) {
        final statesList =
            await _countryStateSelector.getStatesByCountryCode(country);
        if (mounted) {
          setState(() {
            // Remove duplicates based on state name to prevent dropdown assertion errors
            states = statesList.fold<List<country_state_selector.State>>([],
                (list, state) {
              if (!list.any((existingState) =>
                  existingState.name.toLowerCase() ==
                  state.name.toLowerCase())) {
                list.add(state);
              }
              return list;
            });
          });
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          'Failed to load states',
          ContentType.failure,
        );
      }
    }
  }

  Future<void> getCities(String countryCode, String stateCode) async {
    try {
      final country = await _countryStateSelector.getCountryByCode(countryCode);
      if (country != null) {
        final citiesList =
            await _countryStateSelector.getCitiesByCountryCode(country);
        if (mounted) {
          setState(() {
            // Remove duplicates based on city name to fix dropdown assertion error
            cities = citiesList.fold<List<City>>([], (list, city) {
              if (!list.any((existingCity) =>
                  existingCity.name.toLowerCase() == city.name.toLowerCase())) {
                list.add(city);
              }
              return list;
            });

            // Additional safety check: if cities list is empty, reset selectedCity
            if (cities.isEmpty && selectedCity != null) {
              selectedCity = null;
              _city.text = '';
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          'Failed to load cities',
          ContentType.failure,
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isPageLoading = true);
    try {
      // First, upload any new images
      if (newImages.isNotEmpty) {
        await _uploadNewImages();
      }

      // Then update the property
      final response = await _propertyController.editProperty(
        property!.id,
        _name.text.trim(),
        selectedPropertyTypeId ?? '',
        _description.text.trim(),
        _street.text.trim(),
        _area.text.trim(),
        _city.text.trim(),
        _state.text.trim(),
        _zipOrPinCode.text.trim(),
        _country.text.trim(),
        double.tryParse(_lat.text.trim()) ?? 0.0,
        double.tryParse(_lng.text.trim()) ?? 0.0,
        selectedUserId ?? '',
        double.tryParse(_price.text.trim()) ?? 0.0,
        selectedPropertyStatus ?? 'FOR SALE',
        int.tryParse(_bedRooms.text.trim()) ?? 0,
        int.tryParse(_bathRooms.text.trim()) ?? 0,
        double.tryParse(_areaInSquarFoot.text.trim()) ?? 0.0,
        selectedAmenities.isNotEmpty ? selectedAmenities : [],
        selectedListedDate ?? DateTime.now(),
        selectedPublishedOrNot,
      );

      if (!mounted) return;

      if (response['statusCode'] == 200) {
        AppSnackBar.showSnackBar(
          context,
          'Success',
          response['message'] ?? 'Property updated successfully',
          ContentType.success,
        );
        Navigator.pushReplacementNamed(context, '/properties');
      } else {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          response['message'] ?? 'Failed to update property',
          ContentType.failure,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showSnackBar(
        context,
        'Error',
        'Failed to update property: ${e.toString()}',
        ContentType.failure,
      );
    } finally {
      if (mounted) {
        setState(() => isPageLoading = false);
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _headerSpacing),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
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
            textEditingController: _name,
            labelText: PropertyPageProvider.name,
            prefixIcon: CupertinoIcons.home,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '${PropertyPageProvider.name} is required';
              }
              return null;
            },
          ),
          if (propertyTypes.isEmpty)
            Padding(
              padding: _fieldPadding,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading property types...'),
                  ],
                ),
              ),
            )
          else
            _buildDropdownField(
              labelText: PropertyPageProvider.propertyType,
              prefixIcon: CupertinoIcons.line_horizontal_3,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: PropertyPageProvider.propertyType,
                  prefixIcon: const Icon(CupertinoIcons.line_horizontal_3),
                ),
                value: selectedPropertyTypeId != null &&
                        selectedPropertyTypeId!.isNotEmpty &&
                        propertyTypes
                            .any((item) => item.id == selectedPropertyTypeId)
                    ? selectedPropertyTypeId
                    : null,
                items: [
                  // Add the current property type if it's not in the list
                  if (selectedPropertyTypeId != null &&
                      selectedPropertyTypeId!.isNotEmpty &&
                      !propertyTypes
                          .any((item) => item.id == selectedPropertyTypeId))
                    DropdownMenuItem<String>(
                      value: selectedPropertyTypeId,
                      child: Text('Unknown Type (ID: $selectedPropertyTypeId)',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ...propertyTypes.map((PropertyTypeModel item) {
                    return DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(item.typeName),
                    );
                  }).toList(),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    try {
                      final selectedItem =
                          propertyTypes.firstWhere((item) => item.id == value);
                      setState(() {
                        selectedPropertyTypeId = value;
                        _propertyTypeId.text = selectedItem.id;
                      });
                    } catch (e) {
                      // Handle case where the selected value is not in the list (e.g., "Unknown Type")
                      setState(() {
                        selectedPropertyTypeId = value;
                        _propertyTypeId.text = value;
                      });
                    }
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '${PropertyPageProvider.propertyType} is required';
                  }
                  return null;
                },
              ),
            ),
          FormTextField(
            textEditingController: _description,
            labelText: PropertyPageProvider.description,
            prefixIcon: CupertinoIcons.paperclip,
            keyboardType: TextInputType.multiline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '${PropertyPageProvider.description} is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(PropertyPageProvider.address),
          _buildDropdownField(
            labelText: PropertyPageProvider.country,
            prefixIcon: Icons.public,
            child: DropdownButtonFormField2<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: PropertyPageProvider.country,
                prefixIcon: const Icon(Icons.public),
              ),
              value: selectedCountry != null &&
                      selectedCountry!.isNotEmpty &&
                      countries.isNotEmpty &&
                      countries.any((item) =>
                          item.name.toLowerCase() ==
                          selectedCountry!.toLowerCase())
                  ? countries
                      .where((item) =>
                          item.name.toLowerCase() ==
                          selectedCountry!.toLowerCase())
                      .first
                      .name
                  : null,
              onChanged: (String? value) async {
                if (value != null) {
                  try {
                    final country = countries.firstWhere(
                        (c) => c.name.toLowerCase() == value.toLowerCase());

                    // Load states for the selected country
                    final statesList = await _countryStateSelector
                        .getStatesByCountryCode(country);

                    // Load cities for the selected country
                    final citiesList = await _countryStateSelector
                        .getCitiesByCountryCode(country);

                    if (mounted) {
                      setState(() {
                        selectedCountry = value;
                        _country.text = value;
                        // Remove duplicates based on state name to prevent dropdown assertion errors
                        states = statesList
                            .fold<List<country_state_selector.State>>([],
                                (list, state) {
                          if (!list.any((existingState) =>
                              existingState.name.toLowerCase() ==
                              state.name.toLowerCase())) {
                            list.add(state);
                          }
                          return list;
                        });
                        // Remove duplicates based on city name to fix dropdown assertion error
                        cities = citiesList.fold<List<City>>([], (list, city) {
                          if (!list.any((existingCity) =>
                              existingCity.name.toLowerCase() ==
                              city.name.toLowerCase())) {
                            list.add(city);
                          }
                          return list;
                        });

                        // Reset state and city if they don't exist in the new country
                        if (!statesList.any((s) =>
                            s.name.toLowerCase() ==
                            selectedState?.toLowerCase())) {
                          selectedState = null;
                          _state.text = '';
                        }
                        if (!citiesList.any((c) =>
                            c.name.toLowerCase() ==
                            selectedCity?.toLowerCase())) {
                          selectedCity = null;
                          _city.text = '';
                        }

                        // Additional safety check: if cities list is empty, reset selectedCity
                        if (cities.isEmpty && selectedCity != null) {
                          selectedCity = null;
                          _city.text = '';
                        }
                      });
                    }
                  } catch (e) {
                    // Handle error
                    if (mounted) {
                      setState(() {
                        selectedCountry = value;
                        _country.text = value;
                        states = [];
                        cities = [];
                        selectedState = null;
                        selectedCity = null;
                      });
                    }
                  }
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '${PropertyPageProvider.country} is required';
                }
                return null;
              },
              items: countries.isNotEmpty
                  ? countries.map((Country country) {
                      return DropdownMenuItem<String>(
                        value: country.name,
                        child: Text(country.name),
                      );
                    }).toList()
                  : [],
              dropdownSearchData: DropdownSearchData(
                searchController: _countrySearchController,
                searchInnerWidgetHeight: 50,
                searchInnerWidget: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextFormField(
                    controller: _countrySearchController,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: _dropdownContentPadding,
                      hintText: 'Search country...',
                      border: OutlineInputBorder(borderRadius: _borderRadius),
                    ),
                  ),
                ),
                searchMatchFn: (item, searchValue) {
                  return item.value!
                      .toLowerCase()
                      .contains(searchValue.toLowerCase());
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
            labelText: PropertyPageProvider.state,
            prefixIcon: Icons.place_outlined,
            child: DropdownButtonFormField2<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: PropertyPageProvider.state,
                prefixIcon: const Icon(Icons.place_outlined),
              ),
              value: selectedState != null &&
                      selectedState!.isNotEmpty &&
                      states.isNotEmpty &&
                      states.any((item) =>
                          item.name.toLowerCase() ==
                          selectedState!.toLowerCase())
                  ? states
                      .where((item) =>
                          item.name.toLowerCase() ==
                          selectedState!.toLowerCase())
                      .first
                      .name
                  : null,
              items: states.isNotEmpty
                  ? [
                      // Add the current state if it's not in the list
                      if (selectedState != null &&
                          selectedState!.isNotEmpty &&
                          !states.any((item) =>
                              item.name.toLowerCase() ==
                              selectedState!.toLowerCase()))
                        DropdownMenuItem<String>(
                          value: selectedState,
                          child: Text('Unknown State: $selectedState',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ...states.map((country_state_selector.State state) {
                        return DropdownMenuItem<String>(
                          value: state.name,
                          child: Text(state.name),
                        );
                      }).toList(),
                    ]
                  : [],
              onChanged: (String? value) async {
                if (value != null) {
                  try {
                    setState(() {
                      selectedState = value;
                      _state.text = value;
                      selectedCity = null;
                      _city.text = '';
                    });

                    // Load cities for the selected country and state
                    if (selectedCountry != null) {
                      final country = countries.firstWhere((c) =>
                          c.name.toLowerCase() ==
                          selectedCountry!.toLowerCase());
                      final citiesList = await _countryStateSelector
                          .getCitiesByCountryCode(country);

                      if (mounted) {
                        setState(() {
                          // Remove duplicates based on city name to fix dropdown assertion error
                          cities =
                              citiesList.fold<List<City>>([], (list, city) {
                            if (!list.any((existingCity) =>
                                existingCity.name.toLowerCase() ==
                                city.name.toLowerCase())) {
                              list.add(city);
                            }
                            return list;
                          });

                          // Additional safety check: if cities list is empty, reset selectedCity
                          if (cities.isEmpty && selectedCity != null) {
                            selectedCity = null;
                            _city.text = '';
                          }
                        });
                      }
                    }
                  } catch (e) {
                    // Handle error
                    if (mounted) {
                      setState(() {
                        selectedState = value;
                        _state.text = value;
                        cities = [];
                        selectedCity = null;
                        _city.text = '';
                      });
                    }
                  }
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '${PropertyPageProvider.state} is required';
                }
                return null;
              },
              dropdownSearchData: DropdownSearchData(
                searchController: _stateSearchController,
                searchInnerWidgetHeight: 50,
                searchInnerWidget: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextFormField(
                    controller: _stateSearchController,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: _dropdownContentPadding,
                      hintText: 'Search state...',
                      border: OutlineInputBorder(borderRadius: _borderRadius),
                    ),
                  ),
                ),
                searchMatchFn: (item, searchValue) {
                  return item.value!
                      .toLowerCase()
                      .contains(searchValue.toLowerCase());
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
            labelText: PropertyPageProvider.city,
            prefixIcon: Icons.location_city_outlined,
            child: DropdownButtonFormField2<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: PropertyPageProvider.city,
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
              value: selectedCity != null &&
                      selectedCity!.isNotEmpty &&
                      cities.isNotEmpty &&
                      cities.any((item) =>
                          item.name.toLowerCase() ==
                          selectedCity!.toLowerCase())
                  ? cities
                      .where((item) =>
                          item.name.toLowerCase() ==
                          selectedCity!.toLowerCase())
                      .first
                      .name
                  : null,
              items: cities.isNotEmpty
                  ? cities.map((City city) {
                      return DropdownMenuItem<String>(
                        value: city.name,
                        child: Text(city.name),
                      );
                    }).toList()
                  : [],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    selectedCity = value;
                    _city.text = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '${PropertyPageProvider.city} is required';
                }
                return null;
              },
              dropdownSearchData: DropdownSearchData(
                searchController: _citySearchController,
                searchInnerWidgetHeight: 50,
                searchInnerWidget: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextFormField(
                    controller: _citySearchController,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: _dropdownContentPadding,
                      hintText: 'Search city...',
                      border: OutlineInputBorder(borderRadius: _borderRadius),
                    ),
                  ),
                ),
                searchMatchFn: (item, searchValue) {
                  return item.value!
                      .toLowerCase()
                      .contains(searchValue.toLowerCase());
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
          FormTextField(
            textEditingController: _street,
            labelText: PropertyPageProvider.street,
            prefixIcon: Icons.streetview_outlined,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '${PropertyPageProvider.street} is required';
              }
              return null;
            },
          ),
          FormTextField(
            textEditingController: _area,
            labelText: PropertyPageProvider.area,
            prefixIcon: Icons.area_chart_outlined,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '${PropertyPageProvider.area} is required';
              }
              return null;
            },
          ),
          FormTextField(
            textEditingController: _zipOrPinCode,
            labelText: PropertyPageProvider.zipOrPinCode,
            prefixIcon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '${PropertyPageProvider.zipOrPinCode} is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(PropertyPageProvider.location),
              TextButton.icon(
                onPressed: () async {
                  LatLng? initialLocation;
                  if (_lat.text.isNotEmpty && _lng.text.isNotEmpty) {
                    initialLocation = LatLng(
                      double.tryParse(_lat.text) ?? 0.0,
                      double.tryParse(_lng.text) ?? 0.0,
                    );
                  }

                  final LatLng? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationPickerPage(
                        initialLocation: initialLocation,
                      ),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      _lat.text = result.latitude.toString();
                      _lng.text = result.longitude.toString();
                    });
                  }
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('SELECT FROM MAP'),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? AppColors.brandSecondary : AppColors.brandPrimary,
                ),
              ),
            ],
          ),
          FormTextField(
            textEditingController: _lat,
            labelText: PropertyPageProvider.lat,
            prefixIcon: Icons.location_on_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          FormTextField(
            textEditingController: _lng,
            labelText: PropertyPageProvider.lng,
            prefixIcon: Icons.location_on_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(PropertyPageProvider.owner),
          if (users.isEmpty)
            Padding(
              padding: _fieldPadding,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading users...'),
                  ],
                ),
              ),
            )
          else
            _buildDropdownField(
              labelText: PropertyPageProvider.chooseOwner,
              prefixIcon: CupertinoIcons.person,
              child: DropdownButtonFormField2<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: PropertyPageProvider.chooseOwner,
                  prefixIcon: const Icon(CupertinoIcons.person),
                ),
                value: selectedUserId != null &&
                        selectedUserId!.isNotEmpty &&
                        users.any((user) => user.id == selectedUserId)
                    ? selectedUserId
                    : null,
                items: [
                  // Add the current owner if it's not in the list
                  if (selectedUserId != null &&
                      selectedUserId!.isNotEmpty &&
                      !users.any((user) => user.id == selectedUserId))
                    DropdownMenuItem<String>(
                      value: selectedUserId,
                      child: Text('Unknown User (ID: $selectedUserId)',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ...users.map((UsersModel user) {
                    return DropdownMenuItem<String>(
                      value: user.id,
                      child: Text("${user.firstName} ${user.lastName}"),
                    );
                  }).toList(),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    try {
                      if (users.isEmpty) {
                        // If users list is empty, just set the value without trying to find the user
                        setState(() {
                          selectedUserId = value;
                          _ownerId.text = value;
                        });
                        return;
                      }

                      final selectedItem = users.firstWhere(
                        (item) => item.id == value,
                        orElse: () => users.first, // Provide a fallback
                      );
                      setState(() {
                        selectedUserId = value;
                        _ownerId.text = selectedItem.id;
                      });
                    } catch (e) {
                      // Handle the case when user is not found
                      setState(() {
                        selectedUserId = value;
                        _ownerId.text = value;
                      });
                    }
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '${PropertyPageProvider.owner} is required';
                  }
                  return null;
                },
                dropdownSearchData: DropdownSearchData(
                  searchController: _userSearchController,
                  searchInnerWidgetHeight: 50,
                  searchInnerWidget: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextFormField(
                      controller: _userSearchController,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: _dropdownContentPadding,
                        hintText: 'Search by name...',
                        border: OutlineInputBorder(borderRadius: _borderRadius),
                      ),
                    ),
                  ),
                  searchMatchFn: (item, searchValue) {
                    try {
                      if (users.isEmpty) {
                        return false;
                      }

                      final user = users.firstWhere((u) => u.id == item.value);
                      final fullName =
                          "${user.firstName} ${user.lastName}".toLowerCase();
                      return fullName.contains(searchValue.toLowerCase());
                    } catch (e) {
                      // If user is not found, return false
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
        ],
      ),
    );
  }

  Widget _buildPriceAndStatusSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Price & Status'),
          FormTextField(
            textEditingController: _price,
            labelText: PropertyPageProvider.price,
            prefixIcon: Icons.currency_rupee_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '${PropertyPageProvider.price} is required';
              }
              return null;
            },
          ),
          _buildDropdownField(
            labelText: PropertyPageProvider.propertyStatus,
            prefixIcon: CupertinoIcons.tag,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: PropertyPageProvider.propertyStatus,
                prefixIcon: const Icon(CupertinoIcons.tag),
              ),
              value: selectedPropertyStatus,
              items: propertyStatus.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    selectedPropertyStatus = value;
                    _propertyStatus.text = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '${PropertyPageProvider.propertyStatus} is required';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(PropertyPageProvider.features),
          FormTextField(
            textEditingController: _bedRooms,
            labelText: PropertyPageProvider.bedRooms,
            prefixIcon: Icons.bed_outlined,
            keyboardType: TextInputType.number,
          ),
          FormTextField(
            textEditingController: _bathRooms,
            labelText: PropertyPageProvider.bathRooms,
            prefixIcon: Icons.bathtub_outlined,
            keyboardType: TextInputType.number,
          ),
          FormTextField(
            textEditingController: _areaInSquarFoot,
            labelText: PropertyPageProvider.areaInSquarFoot,
            prefixIcon: Icons.space_dashboard_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '${PropertyPageProvider.areaInSquarFoot} is required';
              }
              return null;
            },
          ),
          _buildAmenitiesSelector(),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Padding(
      padding: _fieldPadding,
      child: TextFormField(
        controller: _listedDate,
        readOnly: true,
        decoration: const InputDecoration(
          contentPadding: _dropdownContentPadding,
          labelText: "Select Date",
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: _borderRadius),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Date is required';
          }
          return null;
        },
        onTap: () async {
          FocusScope.of(context).requestFocus(FocusNode());
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedListedDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );

          if (picked != null && mounted) {
            setState(() {
              selectedListedDate = picked;
              _listedDate.text =
                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
            });
          }
        },
      ),
    );
  }

  Widget _buildImagesSection() {
    return Padding(
      padding: _sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Property Images'),

          // Existing Images
          if (propertyImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Current Images',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: propertyImages.length,
                itemBuilder: (context, index) {
                  final image = propertyImages[index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            image.displayImageUrl,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _deleteImage(image.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          // New Images
          if (newImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'New Images to Upload',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: newImages.length,
                itemBuilder: (context, index) {
                  final image = newImages[index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            image,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                newImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          // Add Image Button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isImageLoading ? null : _pickImages,
              icon: isImageLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate),
              label: Text(isImageLoading ? 'Loading...' : 'Add Images'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          newImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      AppSnackBar.showSnackBar(
        context,
        'Error',
        'Failed to pick images',
        ContentType.failure,
      );
    }
  }

  Future<void> _deleteImage(String imageId) async {
    try {
      setState(() => isImageLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Try alternative method first (just image ID)
      var response = await _propertyImageService.deletePropertyImageByImageId(
        token,
        imageId,
      );

      // If alternative method fails, try original method
      if (response['statusCode'] != 200) {
        // Alternative method failed, trying original method
        response = await _propertyImageService.deletePropertyImageById(
          token,
          property!.id,
          imageId,
        );
      }

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        // Reload images from server to refresh the UI
        await loadPropertyImages();

        AppSnackBar.showSnackBar(
          context,
          'Success',
          'Image deleted successfully',
          ContentType.success,
        );
      } else {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          response['message'] ?? 'Failed to delete image',
          ContentType.failure,
        );
      }
    } catch (e) {
      AppSnackBar.showSnackBar(
        context,
        'Error',
        'Failed to delete image',
        ContentType.failure,
      );
    } finally {
      setState(() => isImageLoading = false);
    }
  }

  Future<void> _uploadNewImages() async {
    if (newImages.isEmpty) return;

    try {
      setState(() => isImageLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      for (final imageFile in newImages) {
        final response = await _propertyImageService.createPropertyImage(
          token,
          property!.id,
          imageFile,
        );

        if (response['statusCode'] != 200) {
          throw Exception(response['message'] ?? 'Failed to upload image');
        }
      }

      // Reload images after upload
      await loadPropertyImages();

      setState(() {
        newImages.clear();
      });

      AppSnackBar.showSnackBar(
        context,
        'Success',
        'Images uploaded successfully',
        ContentType.success,
      );
    } catch (e) {
      AppSnackBar.showSnackBar(
        context,
        'Error',
        'Failed to upload images: ${e.toString()}',
        ContentType.failure,
      );
    } finally {
      setState(() => isImageLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBackgroundColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Property'),
        backgroundColor: cardBackgroundColor,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!isPageLoading)
            TextButton(
              onPressed: _handleSubmit,
              child: Text(
                'Save',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : !_formReady
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading property data...'),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information Section
                        _buildBasicInfoSection(),

                        const SizedBox(height: _sectionSpacing),

                        // Address Section
                        _buildAddressSection(),

                        const SizedBox(height: _sectionSpacing),

                        // Location Section
                        _buildLocationSection(),

                        const SizedBox(height: _sectionSpacing),

                        // Owner Section
                        _buildOwnerSection(),

                        const SizedBox(height: _sectionSpacing),

                        // Price & Status Section
                        _buildPriceAndStatusSection(),

                        const SizedBox(height: _sectionSpacing),

                        // Features Section
                        _buildFeaturesSection(),

                        const SizedBox(height: _sectionSpacing),

                        // Date Section
                        _buildDateSection(),

                        const SizedBox(height: _sectionSpacing),

                        // Images Section
                        _buildImagesSection(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Builds the amenities multi-select widget
  Widget _buildAmenitiesSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          PropertyPageProvider.amenities,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(77), // 0.3 * 255
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Selected amenities display
              if (selectedAmenities.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedAmenities.map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withAlpha(26), // 0.1 * 255
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.brandPrimary,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              amenity,
                              style: TextStyle(
                                color: AppColors.brandPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedAmenities.remove(amenity);
                                });
                              },
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Add amenities button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedAmenities.isEmpty
                          ? 'No amenities selected'
                          : '${selectedAmenities.length} amenities selected',
                      style: TextStyle(
                        color: textColor.withAlpha(179), // 0.7 * 255
                        fontSize: 12,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAmenitiesDialog(),
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(
                        selectedAmenities.isEmpty ? 'Select' : 'Edit',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Shows the amenities selection dialog
  void _showAmenitiesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Amenities'),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  children: [
                    // Search field
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search amenities...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Filter amenities based on search
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    // Amenities list
                    Expanded(
                      child: ListView.builder(
                        itemCount: allAmenities.length,
                        itemBuilder: (context, index) {
                          final amenity = allAmenities[index];
                          final isSelected =
                              selectedAmenities.contains(amenity);

                          return CheckboxListTile(
                            title: Text(amenity),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  if (!selectedAmenities.contains(amenity)) {
                                    selectedAmenities.add(amenity);
                                  }
                                } else {
                                  selectedAmenities.remove(amenity);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
