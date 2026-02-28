import 'package:flutter/material.dart';
import 'package:inhabit_realties/Enums/propertyStatusEnum.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/controllers/property/propertyController.dart';
import 'package:inhabit_realties/controllers/propertyType/propertyTypeController.dart';
import 'package:inhabit_realties/models/property/PropertyModel.dart';
import 'package:inhabit_realties/models/propertyType/PropertyTypeModel.dart';
import 'package:inhabit_realties/models/address/Address.dart';
import 'package:inhabit_realties/pages/properties/widgets/appAppBar.dart';
import 'package:inhabit_realties/pages/properties/widgets/propertyTypeContainer.dart';
import 'package:inhabit_realties/pages/properties/widgets/property_image_display.dart';
import 'package:inhabit_realties/pages/widgets/appCard.dart';
import 'package:inhabit_realties/pages/widgets/appSpinner.dart';
import 'package:inhabit_realties/pages/widgets/app_search_bar.dart';
import 'package:inhabit_realties/pages/widgets/horizontal_filter_bar.dart';
import 'package:inhabit_realties/providers/property_page_provider.dart';
import '../widgets/appSnackBar.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:inhabit_realties/pages/properties/property_details_page.dart';
import 'package:inhabit_realties/controllers/favoriteProperty/favoritePropertyController.dart';
import 'package:provider/provider.dart';
import 'package:inhabit_realties/services/pagination_service.dart';

class PropertiesPage extends StatefulWidget {
  const PropertiesPage({super.key});

  @override
  State<PropertiesPage> createState() => _PropertyPageState();
}

class _PropertyPageState extends State<PropertiesPage>
    with SingleTickerProviderStateMixin {
  final PropertyTypeController _propertyTypeController =
      PropertyTypeController();
  final PropertyController _propertyController = PropertyController();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  bool isPageLoading = false;
  bool isInitialLoading = true;
  List<PropertyTypeModel> propertyTypes = [];
  List<PropertyModel> properties = [];
  List<PropertyModel> filteredProperties = [];
  int choosedPropertyType = 0;
  int _propertyTypeIndex = 0;
  String _selectedPropertyStatus = 'ALL';
  final ScrollController _scrollController = ScrollController();
  bool _showFavoritesOnly = false;
  Map<String, bool> _favoriteStatus = {};

  // Pagination variables
  bool isLoadingMore = false;
  bool hasMoreData = true;
  static const int itemsPerPage = 20;
  int currentPage = 0;
  int totalItems = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    propertyTypes.add(
      PropertyTypeModel(
        id: 'all',
        typeName: 'ALL',
        description: 'All types',
        createdByUserId: '0',
        updatedByUserId: '0',
        published: true,
      ),
    );

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

    _loadData();
  }

  // Scroll listener for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMoreData) {
        _loadMoreData();
      }
    }
  }

  // Load more data for pagination
  Future<void> _loadMoreData() async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      // Simulate loading more data (in real app, this would be an API call)
      await Future.delayed(const Duration(milliseconds: 500));

      // Get next batch of properties
      final nextBatch = _getNextBatch();
      if (nextBatch.isNotEmpty) {
        setState(() {
          properties.addAll(nextBatch);
          filteredProperties = _applyFilters(properties);
          currentPage++;
        });
      } else {
        setState(() {
          hasMoreData = false;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  // Get next batch of properties (simulated pagination)
  List<PropertyModel> _getNextBatch() {
    // This is a simulation - in real app, you'd make an API call
    // For now, we'll just return empty to show the pagination structure
    return [];
  }

  // Apply filters to the properties list
  List<PropertyModel> _applyFilters(List<PropertyModel> allProperties) {
    List<PropertyModel> filtered = List.from(allProperties);

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((property) =>
              property.name.toLowerCase().contains(query) ||
              property.description.toLowerCase().contains(query))
          .toList();
    }

    if (_showFavoritesOnly) {
      filtered = filtered
          .where((property) => _favoriteStatus[property.id] == true)
          .toList();
    }

    return filtered;
  }

  Future<void> _loadData() async {
    setState(() {
      isPageLoading = true;
      isInitialLoading = true;
      // Clear data to prevent duplicates on refresh
      propertyTypes.clear();
      propertyTypes.add(
        PropertyTypeModel(
          id: 'all',
          typeName: 'ALL',
          description: 'All types',
          createdByUserId: '0',
          updatedByUserId: '0',
          published: true,
        ),
      );
      // Reset selections to defaults if desired, or keep them to refetch similar data
    });
    await getAllPropertyTypes();
    await loadProperties();

    // Clear any stale favorite status cache and reload from backend
    await _loadFavoriteStatus();

    setState(() {
      isPageLoading = false;
      isInitialLoading = false;
      totalItems = properties.length;
      hasMoreData = properties.length >= itemsPerPage;
    });
    _animationController.forward();
  }

  Future<void> getAllPropertyTypes() async {
    try {
      final response = await _propertyTypeController.getAllPropertyTypes();
      if (response['statusCode'] == 200 && mounted) {
        final data = response['data'];
        if (data.isNotEmpty) {
          setState(() {
            propertyTypes.addAll(
              data
                  .map<PropertyTypeModel>(
                    (item) => PropertyTypeModel.fromJson(item),
                  )
                  .toList(),
            );
          });
        }
      }
    } catch (e) {
      // Handle error appropriately
    }
  }

  Future<void> loadProperties() async {
    final response = await _propertyController.getAllProperties();
    if (response['statusCode'] == 200 && mounted) {
      final List<dynamic> data = response['data'] ?? [];
      if (data.isNotEmpty) {
        setState(() {
          properties = List<PropertyModel>.from(
            data.map(
              (property) =>
                  PropertyModel.fromJson(property as Map<String, dynamic>),
            ),
          );
          _filterProperties(); // Apply initial filtering
        });

        // Load favorite status for all properties
        await _loadFavoriteStatus();
      }
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final controller = context.read<FavoritePropertyController>();
      await controller.loadFavoriteProperties();

      if (mounted) {
        setState(() {
          for (var property in properties) {
            final isFavorited = controller.isPropertyFavorited(property.id);
            _favoriteStatus[property.id] = isFavorited;
          }
        });
      }
    } catch (e) {}
  }

  void _filterProperties() {
    setState(() {
      List<PropertyModel> filtered = List.from(properties);

      // Apply property type filter
      if (choosedPropertyType != 0) {
        final selectedType = propertyTypes[choosedPropertyType];
        filtered = filtered
            .where((property) => property.propertyTypeId == selectedType.id)
            .toList();
      }

      // Apply property status filter
      if (_selectedPropertyStatus != 'ALL') {
        filtered = filtered
            .where((property) =>
                property.propertyStatus == _selectedPropertyStatus)
            .toList();
      }

      // Apply favorites filter
      if (_showFavoritesOnly) {
        filtered = filtered
            .where((property) => _favoriteStatus[property.id] == true)
            .toList();
      }

      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        filtered = _applySearchFilter(filtered, _searchController.text);
      }

      filteredProperties = filtered;
    });
  }

  List<PropertyModel> _applySearchFilter(
      List<PropertyModel> properties, String query) {
    return properties.where((property) {
      final title = property.name.toString().toLowerCase();
      final address = _getFormattedAddressString(property.propertyAddress);
      final searchLower = query.toLowerCase();
      return title.contains(searchLower) ||
          address.toLowerCase().contains(searchLower);
    }).toList();
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

  void _handleSearch(String query) {
    _filterProperties();
  }

  // Widget _buildHeader() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.only(top: 16, bottom: 8, left: 20, right: 20),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         Text(
  //           PropertyPageProvider.mainTitle,
  //           style: Theme.of(context).textTheme.headlineSmall?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //                 letterSpacing: 0.5,
  //               ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: AppSearchBar(
        controller: _searchController,
        onChanged: _handleSearch,
        hintText: 'Search properties...',
        onClear: () => _handleSearch(''),
      ),
    );
  }

  Widget _buildPropertyTypesList() {
    if (propertyTypes.isEmpty) {
      return Container(
        height: 40,
        alignment: Alignment.center,
        child: Text(
          'No property types available',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.greyColor),
        ),
      );
    }

    final filters = propertyTypes.map((type) => type.typeName).toList();

    return HorizontalFilterBar(
      filters: filters,
      selectedIndex: _propertyTypeIndex,
      onFilterChanged: (index) {
        setState(() {
          choosedPropertyType = index;
          _propertyTypeIndex = index;
          _filterProperties();
        });
      },
    );
  }

  Widget _buildPropertyStatusFilter() {
    final statuses = ['ALL', 'FOR SALE', 'FOR RENT', 'SOLD', 'RENTED'];

    return HorizontalFilterBar(
      filters: statuses,
      selectedIndex: statuses.indexOf(_selectedPropertyStatus),
      onFilterChanged: (index) {
        setState(() {
          _selectedPropertyStatus = statuses[index];
          _filterProperties();
        });
      },
    );
  }

  Widget _buildPropertyCard(BuildContext context, int index) {
    final property = filteredProperties[index];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceColor = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsPage(property: property),
          ),
        );
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AppCard(
          widget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: screenHeight * 0.22,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PropertyImageDisplay(
                        propertyId: property.id,
                        width: double.infinity,
                        height: screenHeight * 0.22,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.flag_outlined,
                            size: 16,
                            color: AppColors.darkWhiteText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            PropertyStatus.getLabel(property.propertyStatus),
                            style: const TextStyle(
                              color: AppColors.darkWhiteText,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildHeartButton(property.id),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            property.name.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₹ ${property.price}',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: priceColor,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildFormattedAddress(context, property.propertyAddress),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeatureItem(
                          Icons.hotel_outlined,
                          '${property.features.bedRooms} beds',
                        ),
                        _buildFeatureItem(
                          Icons.bathtub_outlined,
                          '${property.features.bathRooms} bath',
                        ),
                        _buildFeatureItem(
                          Icons.space_dashboard_outlined,
                          '${property.features.areaInSquarFoot} sf',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedAddress(BuildContext context, Address address) {
    final List<String> addressParts = [];

    // Add street if not empty
    if (address.street.isNotEmpty) {
      addressParts.add(address.street);
    }

    // Add area if not empty
    if (address.area.isNotEmpty) {
      addressParts.add(address.area);
    }

    // Add city if not empty
    if (address.city.isNotEmpty) {
      addressParts.add(address.city);
    }

    // Add state if not empty
    if (address.state.isNotEmpty) {
      addressParts.add(address.state);
    }

    // Add zip/pin code if not empty
    if (address.zipOrPinCode.isNotEmpty) {
      addressParts.add(address.zipOrPinCode);
    }

    // Add country if not empty
    if (address.country.isNotEmpty) {
      addressParts.add(address.country);
    }

    // If no address parts, show a placeholder
    if (addressParts.isEmpty) {
      return Text(
        'Address not available',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.greyColor2,
              fontStyle: FontStyle.italic,
            ),
      );
    }

    // Join address parts with commas and spaces
    final formattedAddress = addressParts.join(', ');

    return Text(
      formattedAddress,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.greyColor2,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.greyColor2),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.greyColor2),
        ),
      ],
    );
  }

  Widget _buildHeartButton(String propertyId) {
    final isFavorited = _favoriteStatus[propertyId] ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _toggleFavorite(propertyId, context),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.7)
                : Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isFavorited ? Icons.favorite : Icons.favorite_border,
            color: isFavorited
                ? Colors.red
                : (isDark ? Colors.white : Colors.grey),
            size: 18,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(String propertyId, BuildContext context) async {
    try {
      final controller = context.read<FavoritePropertyController>();
      final success = await controller.toggleFavorite(propertyId, context);

      if (success && mounted) {
        // Update local state to match controller's state
        setState(() {
          _favoriteStatus[propertyId] =
              controller.isPropertyFavorited(propertyId);
        });

        // Reload properties if showing favorites only
        if (_showFavoritesOnly) {
          _filterProperties();
        }
      } else {}
    } catch (e) {
      if (mounted) {
        AppSnackBar.showSnackBar(
          context,
          'Error',
          'Failed to update favorite status: $e',
          ContentType.failure,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppAppBar(
        onToggleFavorites: () {
          setState(() {
            _showFavoritesOnly = !_showFavoritesOnly;
          });
          _filterProperties();
        },
        showFavoritesOnly: _showFavoritesOnly,
      ),
      body: isInitialLoading
          ? const Center(child: AppSpinner(size: 32.0, strokeWidth: 3.0))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  //_buildHeader(),
                  _buildPropertyTypesList(),
                  _buildPropertyStatusFilter(),
                  _buildSearchBar(),
                  const SizedBox(height: 4),
                  if (isPageLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.brandPrimary),
                      ),
                    )
                  else if (filteredProperties.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No properties found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.greyColor,
                              ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Text(
                              'Showing ${filteredProperties.length} propert${filteredProperties.length == 1 ? 'y' : 'ies'}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.greyColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              color: AppColors.brandPrimary,
                              onRefresh: _loadData,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  bottom: 100,
                                  top: 8,
                                ),
                                itemCount: filteredProperties.length + (isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == filteredProperties.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.brandPrimary,
                                        ),
                                      ),
                                    );
                                  }
                                  return _buildPropertyCard(context, index);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // Build loading indicator for pagination
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading more properties...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
