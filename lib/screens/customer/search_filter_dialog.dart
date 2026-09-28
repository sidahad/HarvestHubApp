import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/data_service.dart';

class SearchFilterDialog extends StatefulWidget {
  const SearchFilterDialog({super.key});

  @override
  State<SearchFilterDialog> createState() => _SearchFilterDialogState();
}

class _SearchFilterDialogState extends State<SearchFilterDialog> {
  final DataService _dataService = DataService();

  late String _selectedCategory;
  late double _distance;
  late String _selectedMarket;
  late TextEditingController _priceController;
  late TextEditingController _productNameController;
  late TextEditingController _farmerNameController;
  late TextEditingController _locationController;
  String _priceFilter = 'Any price';
  bool _gettingLocation = false;

  List<String> get _markets {
    final markets = <String>{
      ..._dataService.products.map((product) => product.marketName),
      ..._dataService.farmers.map(
        (farmer) =>
            farmer.marketName.isNotEmpty ? farmer.marketName : farmer.farmName,
      ),
    }..removeWhere((market) => market.trim().isEmpty);
    return ['All Markets', ...markets.toList()..sort()];
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = _dataService.selectedCategory;
    _distance = _dataService.maxDistanceKm;
    _selectedMarket = _dataService.selectedMarket;
    _priceController = TextEditingController(
      text: _dataService.priceLimit?.toStringAsFixed(0) ?? '',
    );
    _productNameController = TextEditingController(
      text: _dataService.productNameFilter ?? '',
    );
    _farmerNameController = TextEditingController(
      text: _dataService.farmerNameFilter ?? '',
    );
    _locationController = TextEditingController(
      text: _dataService.locationFilter,
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _productNameController.dispose();
    _farmerNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    _dataService.updateFilters(
      distance: _distance,
      market: _selectedMarket,
      category: _selectedCategory,
      price: double.tryParse(_priceController.text.trim()),
      priceMode: _priceFilter,
      productName: _productNameController.text.trim(),
      farmerName: _farmerNameController.text.trim(),
      location: _locationController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _distance = 50.0;
      _selectedMarket = 'All Markets';
      _priceController.clear();
      _productNameController.clear();
      _farmerNameController.clear();
      _locationController.clear();
      _priceFilter = 'Any price';
    });
    _dataService.resetFilters();
    Navigator.of(context).pop();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on Location Services to calculate distance.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Allow location access to calculate distance.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      _dataService.setCustomerLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS location ready for distance filters.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF15281E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Colors.white.withAlpha(25), width: 1.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle and header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Products',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF0F5F1),
                        ),
                      ),
                      TextButton(
                        onPressed: _resetFilters,
                        child: Text(
                          'Reset All',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFE76F51),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 24, color: Colors.white.withAlpha(20)),
                ],
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name Search Field
                    Text(
                      'Search by Product Name',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8FA497),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _productNameController,
                      style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                      decoration: InputDecoration(
                        hintText: 'e.g. Tomato, Mango, Wheat...',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF6F8578),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF182D22),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFFA1C68A),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(20),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(20),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF88AB75),
                          ),
                        ),
                        suffixIcon: _productNameController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Color(0xFF8FA497),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _productNameController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 20),

                    // Farmer Name Search Field
                    Text(
                      'Search by Farmer Name',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8FA497),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _farmerNameController,
                      style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                      decoration: InputDecoration(
                        hintText: 'e.g. John Smith, Green Farm...',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF6F8578),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF182D22),
                        prefixIcon: const Icon(
                          Icons.agriculture_rounded,
                          color: Color(0xFFA1C68A),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(20),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(20),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF88AB75),
                          ),
                        ),
                        suffixIcon: _farmerNameController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Color(0xFF8FA497),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _farmerNameController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Farm or Market Location',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8FA497),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                      decoration: InputDecoration(
                        hintText: 'Search by city, area, or market',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF6F8578),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF182D22),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFA1C68A),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(20),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(20),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF88AB75),
                          ),
                        ),
                        suffixIcon: _locationController.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Clear location',
                                icon: const Icon(
                                  Icons.clear,
                                  color: Color(0xFF8FA497),
                                ),
                                onPressed: () {
                                  setState(_locationController.clear);
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    // Category Select
                    Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8FA497),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                            'All',
                            ..._dataService.categories.map(
                              (category) => category.name,
                            ),
                          ].map((cat) {
                            final isSel = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSel,
                              selectedColor: const Color(0xFF88AB75),
                              backgroundColor: const Color(0xFF182D22),
                              side: BorderSide(
                                color: isSel
                                    ? const Color(0xFFA1C68A)
                                    : Colors.white.withAlpha(20),
                              ),
                              labelStyle: TextStyle(
                                color: isSel
                                    ? const Color(0xFF0D1A13)
                                    : const Color(0xFFF0F5F1),
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              onSelected: (val) {
                                if (val)
                                  setState(() => _selectedCategory = cat);
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Distance Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Farmer Distance',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8FA497),
                          ),
                        ),
                        Text(
                          'Up to ${_distance.toInt()} km',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFA1C68A),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _distance,
                      min: 5.0,
                      max: 50.0,
                      divisions: 9,
                      activeColor: const Color(0xFF88AB75),
                      inactiveColor: const Color(0xFF182D22),
                      onChanged: (val) => setState(() => _distance = val),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _dataService.customerLatitude != null
                                  ? const Color(0xFF1E3D2B)
                                  : Colors.transparent,
                              side: BorderSide(
                                color: _dataService.customerLatitude != null
                                    ? const Color(0xFFA1C68A)
                                    : const Color(0xFF88AB75).withAlpha(80),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onPressed: _gettingLocation
                                ? null
                                : _useCurrentLocation,
                            icon: _gettingLocation
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFA1C68A),
                                    ),
                                  )
                                : Icon(
                                    _dataService.customerLatitude != null
                                        ? Icons.location_on_rounded
                                        : Icons.my_location_rounded,
                                    size: 17,
                                    color: _dataService.customerLatitude != null
                                        ? const Color(0xFFA1C68A)
                                        : const Color(0xFFF0F5F1),
                                  ),
                            label: Text(
                              _gettingLocation
                                  ? 'Finding you...'
                                  : (_dataService.customerLatitude != null
                                      ? 'GPS Location Active'
                                      : 'Use my location for distance'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: _dataService.customerLatitude != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _dataService.customerLatitude != null
                                    ? const Color(0xFFA1C68A)
                                    : const Color(0xFFF0F5F1),
                              ),
                            ),
                          ),
                        ),
                        if (_dataService.customerLatitude != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Clear GPS Location',
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF2D1E1E),
                              foregroundColor: const Color(0xFFE76F51),
                              padding: const EdgeInsets.all(8),
                            ),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _dataService.resetFilters();
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Location filter cleared.'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Local Market Dropdown
                    Text(
                      'Local Market',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8FA497),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMarket,
                      dropdownColor: const Color(0xFF182D22),
                      style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF182D22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(20),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha(20),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: _markets.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(
                            m,
                            style: const TextStyle(color: Color(0xFFF0F5F1)),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMarket = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Price Filter',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8FA497),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFF0F5F1),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter amount',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF6F8578),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF182D22),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white.withAlpha(20),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white.withAlpha(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _priceFilter,
                            dropdownColor: const Color(0xFF182D22),
                            style: GoogleFonts.inter(
                              color: const Color(0xFFF0F5F1),
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF182D22),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white.withAlpha(20),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white.withAlpha(20),
                                ),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Any price',
                                child: Text(
                                  'Any price',
                                  style: TextStyle(color: Color(0xFFF0F5F1)),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Less than',
                                child: Text(
                                  'Less than',
                                  style: TextStyle(color: Color(0xFFF0F5F1)),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Greater than',
                                child: Text(
                                  'Greater than',
                                  style: TextStyle(color: Color(0xFFF0F5F1)),
                                ),
                              ),
                            ],
                            onChanged: (value) => setState(
                              () => _priceFilter = value ?? 'Any price',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF88AB75),
                          foregroundColor: const Color(0xFF0D1A13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D1A13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
