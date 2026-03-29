// ignore_for_file: no_leading_underscores_for_local_identifiers, prefer_final_fields, unused_field, unused_local_variable, use_build_context_synchronously

import 'package:country_state_city/models/city.dart';
import 'package:country_state_city/models/country.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inhabit_realties/constants/initalAssigner.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:inhabit_realties/controllers/property/propertyController.dart';
import 'package:inhabit_realties/controllers/propertyType/propertyTypeController.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/controllers/selectors/countryStateSelector.dart';
import 'package:inhabit_realties/controllers/user/userController.dart';
import 'package:inhabit_realties/models/auth/UsersModel.dart';
import 'package:inhabit_realties/models/propertyType/PropertyTypeModel.dart';
import 'package:inhabit_realties/pages/widgets/appSnackBar.dart';
import 'package:inhabit_realties/pages/widgets/appSpinner.dart';
import 'package:inhabit_realties/pages/widgets/formTextField.dart';
import 'package:inhabit_realties/providers/property_page_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:country_state_city/country_state_city.dart'
    as country_state_selector;
import 'package:latlong2/latlong.dart';
import 'package:inhabit_realties/pages/properties/location_picker_page.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  // Convert controllers to late final to improve performance
  late final PropertyController _propertyController;
  late final PropertyTypeController _propertyTypeController;
  late final UserController _userController;
  late final CountryStateSelector _countryStateSelector;

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

  String? selectedPropertyTypeId;
  String? selectedUserId;
  String? selectedPropertyStatus;
  DateTime? selectedListedDate;
  String? selectedCountry;
  String? selectedCountryCode;
  String? selectedState;
  String? selectedCity;

  bool isPageLoading = false;
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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    // Initialize all controllers
    _propertyController = PropertyController();
    _propertyTypeController = PropertyTypeController();
    _userController = UserController();
    _countryStateSelector = CountryStateSelector();

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
      await Future.wait([getAllPropertyTypes(), getAllUsers(), getAllCSC()]);
    } catch (e) {
      // Handle error appropriately
    } finally {
      if (mounted) {
        setState(() => isPageLoading = false);
      }
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
      if (response['statusCode'] == 200 && mounted) {
        setState(() {
          propertyTypes = (response['data'] as List)
              .map((item) => PropertyTypeModel.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      // Handle error appropriately
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
      // Handle error appropriately
    }
  }

  Future<void> getAllCSC() async {
    try {
      final loadedCountries = await _countryStateSelector.getCountries();
      if (mounted) {
        setState(() {
          countries = loadedCountries;
        });
      }
    } catch (e) {
      // Handle error appropriately
    }
  }

  Future<Map<String, dynamic>> processCreateProperty(
    String name,
    String propertyTypeId,
    String description,
    String street,
    String area,
    String city,
    String state,
    String zipOrPinCode,
    String country,
    double lat,
    double lng,
    String ownerId,
    double price,
    String propertyStatus,
    int bedRooms,
    int bathRooms,
    double areaInSquarFoot,
    List<String> amenities,
    DateTime listedDate,
  ) async {
    return await _propertyController.createProperty(
      name,
      propertyTypeId,
      description,
      street,
      area,
      city,
      state,
      zipOrPinCode,
      country,
      lat,
      lng,
      ownerId,
      price,
      propertyStatus,
      bedRooms,
      bathRooms,
      areaInSquarFoot,
      amenities,
      listedDate,
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
          _buildDropdownField(
            labelText: PropertyPageProvider.propertyType,
            prefixIcon: CupertinoIcons.line_horizontal_3,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: PropertyPageProvider.propertyType,
                prefixIcon: const Icon(CupertinoIcons.line_horizontal_3),
              ),
              value: selectedPropertyTypeId,
              items: propertyTypes.map((PropertyTypeModel item) {
                return DropdownMenuItem<String>(
                  value: item.id,
                  child: Text(item.typeName),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  final selectedItem = propertyTypes.firstWhere(
                    (item) => item.id == value,
                  );
                  setState(() {
                    selectedPropertyTypeId = value;
                    _propertyTypeId.text = selectedItem.id;
                  });
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
              value: selectedCountry,
              onChanged: (String? value) async {
                if (value != null) {
                  final country = countries.firstWhere((c) => c.name == value);
                  states = await _countryStateSelector.getStatesByCountryCode(
                    country,
                  );
                  cities = await _countryStateSelector.getCitiesByCountryCode(
                    country,
                  );
                  if (mounted) {
                    setState(() {
                      selectedCountry = value;
                      _country.text = value;
                      selectedState = null;
                      selectedCity = null;
                    });
                  }
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '${PropertyPageProvider.country} is required';
                }
                return null;
              },
              items: countries.map((Country country) {
                return DropdownMenuItem<String>(
                  value: country.name,
                  child: Text(country.name),
                );
              }).toList(),
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
                  return item.value!.toLowerCase().contains(
                        searchValue.toLowerCase(),
                      );
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
              value: selectedState,
              items: states.map((country_state_selector.State state) {
                return DropdownMenuItem<String>(
                  value: state.name,
                  child: Text(state.name),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    selectedState = value;
                    _state.text = value;
                    selectedCity = null;
                  });
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
                  return item.value!.toLowerCase().contains(
                        searchValue.toLowerCase(),
                      );
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
              value: selectedCity,
              items: cities.map((City city) {
                return DropdownMenuItem<String>(
                  value: city.name,
                  child: Text(city.name),
                );
              }).toList(),
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
                  return item.value!.toLowerCase().contains(
                        searchValue.toLowerCase(),
                      );
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
          _buildLocationFields(),
        ],
      ),
    );
  }

  Widget _buildLocationFields() {
    return Column(
      children: [
        FormTextField(
          textEditingController: _street,
          labelText: PropertyPageProvider.street,
          prefixIcon: Icons.route_outlined,
          keyboardType: TextInputType.streetAddress,
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
          prefixIcon: Icons.numbers_outlined,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '${PropertyPageProvider.zipOrPinCode} is required';
            }
            return null;
          },
        ),
      ],
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
                  
                  final String? city = _city.text.isNotEmpty ? _city.text : null;
                  final String? state = _state.text.isNotEmpty ? _state.text : null;
                  final String? country = _country.text.isNotEmpty ? _country.text : null;
                  
                  final List<String> addressParts = [];
                  if (city != null) addressParts.add(city);
                  if (state != null) addressParts.add(state);
                  if (country != null) addressParts.add(country);
                  
                  final String? initialAddress = addressParts.isNotEmpty ? addressParts.join(', ') : null;

                  final LatLng? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationPickerPage(
                        initialLocation: initialLocation,
                        initialAddress: initialAddress,
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
          _buildDropdownField(
            labelText: PropertyPageProvider.chooseOwner,
            prefixIcon: CupertinoIcons.person,
            child: DropdownButtonFormField2<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: PropertyPageProvider.chooseOwner,
                prefixIcon: const Icon(CupertinoIcons.person),
              ),
              value: selectedUserId,
              items: users.map((UsersModel user) {
                return DropdownMenuItem<String>(
                  value: user.id,
                  child: Text("${user.firstName} ${user.lastName}"),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  final selectedItem = users.firstWhere(
                    (item) => item.id == value,
                  );
                  setState(() {
                    selectedUserId = value;
                    _ownerId.text = selectedItem.id;
                  });
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
                  final user = users.firstWhere((u) => u.id == item.value);
                  final fullName =
                      "${user.firstName} ${user.lastName}".toLowerCase();
                  return fullName.contains(searchValue.toLowerCase());
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

  @override
  Widget build(BuildContext context) {
    if (propertyTypes.isEmpty ||
        users.isEmpty ||
        propertyStatus.isEmpty ||
        countries.isEmpty) {
      return const AppSpinner();
    }

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
            title: Text(PropertyPageProvider.title),
            backgroundColor: backgroundColor,
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
                      _buildAddressSection(),
                      _buildLocationSection(),
                      _buildOwnerSection(),
                      _buildPriceAndStatusSection(),
                      _buildFeaturesSection(),
                      _buildDateSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isPageLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const AppSpinner(),
          ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!mounted || isPageLoading) return;

    setState(() => isPageLoading = true);

    try {
      if (_formKey.currentState!.validate()) {
        final name = await InitalAssigner.generateInitial(_name.text.trim());
        final propertyTypeId = _propertyTypeId.text.trim();
        final description = _description.text.trim();
        final street = await InitalAssigner.generateInitial(
          _street.text.trim(),
        );
        final area = await InitalAssigner.generateInitial(_area.text.trim());
        final city = await InitalAssigner.generateInitial(_city.text.trim());
        final state = await InitalAssigner.generateInitial(_state.text.trim());
        final zipOrPinCode = _zipOrPinCode.text.trim();
        final country = await InitalAssigner.generateInitial(
          _country.text.trim(),
        );
        final lat =
            _lat.text.trim().isEmpty ? 0.0 : double.parse(_lat.text.trim());
        final lng =
            _lng.text.trim().isEmpty ? 0.0 : double.parse(_lng.text.trim());
        final ownerId = _ownerId.text.trim();
        final price = double.parse(_price.text.trim());
        final propertyStatus = _propertyStatus.text.trim();
        final bedRooms = _bedRooms.text.trim().isEmpty
            ? 0
            : int.parse(_bedRooms.text.trim());
        final bathRooms = _bathRooms.text.trim().isEmpty
            ? 0
            : int.parse(_bathRooms.text.trim());
        final areaInSquarFoot = _areaInSquarFoot.text.trim().isEmpty
            ? 0.0
            : double.parse(_areaInSquarFoot.text.trim());

        final amenities =
            selectedAmenities.isNotEmpty ? selectedAmenities : <String>[];

        final listedDate = DateTime.parse(_listedDate.text);

        final response = await processCreateProperty(
          name,
          propertyTypeId,
          description,
          street,
          area,
          city,
          state,
          zipOrPinCode,
          country,
          lat,
          lng,
          ownerId,
          price,
          propertyStatus,
          bedRooms,
          bathRooms,
          areaInSquarFoot,
          amenities,
          listedDate,
        );

        if (!mounted) return;

        if (response['statusCode'] == 200) {
          AppSnackBar.showSnackBar(
            context,
            'Success',
            response["message"],
            ContentType.success,
          );
          Navigator.pushReplacementNamed(context, '/properties');
        } else {
          AppSnackBar.showSnackBar(
            context,
            'Failure',
            response["message"],
            ContentType.failure,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          'An error occurred while submitting the form',
          ContentType.failure,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isPageLoading = false);
      }
    }
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
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
                          color: AppColors.brandPrimary.withOpacity(0.1),
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
                        color: textColor.withOpacity(0.7),
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
                        prefixIcon: Icon(Icons.search),
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
