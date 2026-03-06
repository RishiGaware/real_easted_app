import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inhabit_realties/constants/contants.dart';
import 'package:inhabit_realties/controllers/favoriteProperty/favoritePropertyController.dart';
import 'package:inhabit_realties/models/favoriteProperty/FavoritePropertyModel.dart';
import 'package:inhabit_realties/models/property/PropertyModel.dart';
import 'package:inhabit_realties/models/address/Address.dart';
import 'package:inhabit_realties/services/property/propertyService.dart';
import 'package:inhabit_realties/pages/widgets/page_container.dart';
import 'package:inhabit_realties/pages/widgets/appDrawer.dart';
import 'package:inhabit_realties/pages/widgets/appCard.dart';
import 'package:inhabit_realties/pages/properties/widgets/property_image_display.dart';
import 'package:inhabit_realties/pages/properties/property_details_page.dart';
import 'package:inhabit_realties/Enums/propertyStatusEnum.dart';
import 'package:inhabit_realties/controllers/propertyType/propertyTypeController.dart';
import 'package:inhabit_realties/models/propertyType/PropertyTypeModel.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritePropertiesPage extends StatefulWidget {
  const FavoritePropertiesPage({super.key});

  @override
  State<FavoritePropertiesPage> createState() => _FavoritePropertiesPageState();
}

class _FavoritePropertiesPageState extends State<FavoritePropertiesPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final PropertyService _propertyService = PropertyService();
  final PropertyTypeController _propertyTypeController = PropertyTypeController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isInitialLoading = true;
  List<PropertyModel> _favoriteProperties = [];
  List<PropertyModel> _filteredProperties = [];
  List<PropertyTypeModel> _propertyTypes = [];
  String _selectedStatus = 'ALL';
  String _selectedType = 'ALL';
  String? _errorMessage;

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

    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    await _loadFavoriteProperties(isRefresh: isRefresh);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteProperties({bool isRefresh = false}) async {
    setState(() {
      _isLoading = true;
      if (!isRefresh) {
        _isInitialLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final controller = context.read<FavoritePropertyController>();
      await controller.loadFavoriteProperties();

      if (mounted) {
        final favoriteProperties = controller.favoriteProperties;

        if (favoriteProperties.isNotEmpty) {
          // Get the actual property details for each favorite
          await _loadPropertyDetails(favoriteProperties);
        } else {
          // If no favorites, clear the list
          setState(() {
            _favoriteProperties = [];
            _filteredProperties = [];
          });
        }

        setState(() {
          _isLoading = false;
          _isInitialLoading = false;
        });
        _animationController.forward();
      }

      // Load property types
      await _loadPropertyTypes();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load favorite properties: $e';
          _isLoading = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadPropertyDetails(
      List<FavoritePropertyModel> favorites) async {
    try {
      final List<PropertyModel> properties = [];

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      for (final favorite in favorites) {
        try {
          final response = await _propertyService.getPropertyById(
              token, favorite.propertyId);
          if (response['statusCode'] == 200 && response['data'] != null) {
            final property = PropertyModel.fromJson(response['data']);
            properties.add(property);
          }
        } catch (e) {
          // Skip properties that can't be loaded
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _favoriteProperties = properties;
          _filteredProperties = properties;
        });
        _applyFilters();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadPropertyTypes() async {
    try {
      final response = await _propertyTypeController.getAllPropertyTypes();
      if (response['statusCode'] == 200 && response['data'] != null) {
        final List<PropertyTypeModel> types = (response['data'] as List)
            .map((json) => PropertyTypeModel.fromJson(json))
            .toList();
        if (mounted) {
          setState(() {
            _propertyTypes = types;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredProperties = _favoriteProperties.where((property) {
        // Search filter
        final nameMatch = property.name.toString().toLowerCase().contains(query);
        
        // Also check if property type name matches search query
        final typeForSearch = _propertyTypes.firstWhere(
          (t) => t.id == property.propertyTypeId,
          orElse: () => PropertyTypeModel(id: '', typeName: '', description: '', createdByUserId: '', updatedByUserId: '', published: false),
        );
        final typeSearchMatch = typeForSearch.typeName.toLowerCase().contains(query);
        
        final finalSearchMatch = nameMatch || typeSearchMatch;
        
        // Status filter
        final statusMatch = _selectedStatus == 'ALL' || 
            PropertyStatus.getLabel(property.propertyStatus).toUpperCase() == _selectedStatus;
            
        // Type filter (from chips)
        bool typeMatch = _selectedType == 'ALL';
        if (!typeMatch) {
          typeMatch = typeForSearch.typeName == _selectedType;
        }

        return finalSearchMatch && statusMatch && typeMatch;
      }).toList();
    });
  }

  Future<void> _removeFromFavorites(String propertyId) async {
    try {
      final controller = context.read<FavoritePropertyController>();
      final success = await controller.removeFromFavorites(propertyId, context);

      if (success && mounted) {
        // Remove from local list
        setState(() {
          _favoriteProperties
              .removeWhere((property) => property.id == propertyId);
        });
      }
    } catch (e) {
      // Error handled by controller
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('My Favorite Properties'),
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDark ? AppColors.darkWhiteText : AppColors.lightDarkText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.refresh,
              color: isDark ? AppColors.darkWhiteText : AppColors.lightDarkText,
            ),
            onPressed: () {
              setState(() {
                _isInitialLoading = true;
              });
              _loadData();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadData(isRefresh: true);
          },
          color: AppColors.brandPrimary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              if (_isInitialLoading)
                _buildLoadingShimmer()
              else if (_errorMessage != null)
                _buildErrorWidget()
              else if (_favoriteProperties.isEmpty)
                _buildEmptyState()
              else ...[
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildStatusFilters(),
                const SizedBox(height: 12),
                _buildTypeFilters(),
                const SizedBox(height: 16),
                _buildTotalCountRow(),
                const SizedBox(height: 16),
                if (_filteredProperties.isEmpty)
                  _buildNoResultsFound()
                else
                  _buildPropertiesList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoSearchTextField(
        controller: _searchController,
        onChanged: (value) => _applyFilters(),
        placeholder: 'Search favorite properties...',
        style: TextStyle(
          color: isDark ? AppColors.darkWhiteText : AppColors.lightDarkText,
          fontSize: 14,
        ),
        placeholderStyle: TextStyle(
          color: AppColors.greyColor,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    final List<String> statuses = ['ALL', 'FOR SALE', 'FOR RENT', 'SOLD'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: statuses.map((status) {
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(status == 'ALL' ? 'All Properties' : status),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedStatus = status;
                  });
                  _applyFilters();
                }
              },
              selectedColor: AppColors.brandPrimary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.brandPrimary
                    : (isDark ? AppColors.darkWhiteText : AppColors.lightDarkText),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.brandPrimary : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> types = ['ALL'];
    types.addAll(_propertyTypes.map((t) => t.typeName).toList());

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: types.map((type) {
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(type == 'ALL' ? 'All Types' : type),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedType = type;
                  });
                  _applyFilters();
                }
              },
              selectedColor: AppColors.brandSecondary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.brandSecondary
                    : (isDark ? AppColors.darkWhiteText : AppColors.lightDarkText),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.brandSecondary : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.search,
              size: 64,
              color: AppColors.greyColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No properties match your filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters to find what you\'re looking for.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.greyColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: AppColors.lightDanger,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Favorites',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.lightDanger,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'An unknown error occurred',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.greyColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadFavoriteProperties,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.heart,
            size: 64,
            color: AppColors.greyColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Favorite Properties',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t added any properties to your favorites yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.greyColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/properties'),
            icon: const Icon(Icons.search),
            label: const Text('Browse Properties'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCountRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground.withOpacity(0.5) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.list_bullet,
                size: 18,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Total: ${_filteredProperties.length} properties',
                style: TextStyle(
                  color: isDark ? AppColors.darkWhiteText : AppColors.lightDarkText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (_filteredProperties.length != _favoriteProperties.length)
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatus = 'ALL';
                  _selectedType = 'ALL';
                  _searchController.clear();
                });
                _applyFilters();
              },
              child: Text(
                'Clear Filters',
                style: TextStyle(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertiesList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredProperties.length,
        itemBuilder: (context, index) {
          final property = _filteredProperties[index];
          return _buildPropertyCard(property);
        },
      ),
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceColor = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;

    return GestureDetector(
      onTap: () {
        // Navigate to property details page
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

  Widget _buildPropertyFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.greyColor,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.greyColor,
              ),
        ),
      ],
    );
  }

  Widget _buildHeartButton(String propertyId) {
    final isFavorited = true; // Always true since this is favorites page
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _removeFromFavorites(propertyId),
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
            Icons.favorite,
            color: Colors.red,
            size: 18,
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
}
