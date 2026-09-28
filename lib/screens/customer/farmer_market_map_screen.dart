import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../../models/conversation_model.dart';
import '../../models/farmer_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/pakistan_locations.dart';
import '../common/chat_detail_screen.dart';
import 'farmer_profile_screen.dart';

class FarmerMarketMapScreen extends StatefulWidget {
  final String? initialCity;
  final String? initialArea;

  const FarmerMarketMapScreen({
    super.key,
    this.initialCity,
    this.initialArea,
  });

  @override
  State<FarmerMarketMapScreen> createState() => _FarmerMarketMapScreenState();
}

class _FarmerMarketMapScreenState extends State<FarmerMarketMapScreen>
    with SingleTickerProviderStateMixin {
  final DataService _dataService = DataService();
  final MapController _mapController = MapController();

  FarmerModel? _selectedFarmer;
  bool _locating = false;
  bool _mapReady = false;
  String? _locationMessage;

  String _selectedCity = 'Karachi'; // Default focus on Karachi as requested
  String _selectedArea = 'All Areas';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    if (widget.initialCity != null) _selectedCity = widget.initialCity!;
    if (widget.initialArea != null) _selectedArea = widget.initialArea!;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _dataService.addListener(_onDataChanged);
    _dataService.loadCatalog().catchError((error) {
      debugPrint('Could not refresh farmer map data: $error');
    });

    _locateCustomer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  LocationCity? get _currentCityData {
    if (_selectedCity == 'All Pakistan') return null;
    return PakistanLocations.cities.firstWhere(
      (c) => c.name.toLowerCase() == _selectedCity.toLowerCase(),
      orElse: () => PakistanLocations.cities.first,
    );
  }

  List<String> get _availableAreas {
    final cityData = _currentCityData;
    if (cityData == null) return ['All Areas'];
    return ['All Areas', ...cityData.areas.map((a) => a.name)];
  }

  bool _farmerMatchesCityAndArea(FarmerModel farmer) {
    final text = '${farmer.location} ${farmer.marketName} ${farmer.farmName}'
        .toLowerCase();

    if (_selectedCity != 'All Pakistan') {
      final cityLower = _selectedCity.toLowerCase();
      // Match city name in farmer location or farm name
      final inCity = text.contains(cityLower);
      if (!inCity && farmer.latitude != null && farmer.longitude != null) {
        final cityData = _currentCityData;
        if (cityData != null) {
          // If within 60km of city center
          final dist = Geolocator.distanceBetween(
                cityData.center.latitude,
                cityData.center.longitude,
                farmer.latitude!,
                farmer.longitude!,
              ) /
              1000;
          if (dist > 65) return false;
        } else {
          return false;
        }
      }
    }

    if (_selectedArea != 'All Areas') {
      final areaLower = _selectedArea.toLowerCase();
      final words = areaLower.split(RegExp(r'[\s&/,\-]+')).where((w) => w.length > 2);
      bool matchesArea = false;
      for (final word in words) {
        if (text.contains(word)) {
          matchesArea = true;
          break;
        }
      }
      if (!matchesArea && farmer.latitude != null && farmer.longitude != null) {
        final cityData = _currentCityData;
        final areaData = cityData?.areas.firstWhere(
          (a) => a.name == _selectedArea,
          orElse: () => cityData.areas.first,
        );
        if (areaData != null) {
          final dist = Geolocator.distanceBetween(
                areaData.center.latitude,
                areaData.center.longitude,
                farmer.latitude!,
                farmer.longitude!,
              ) /
              1000;
          if (dist > 15) return false;
        } else {
          return false;
        }
      }
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      if (!farmer.name.toLowerCase().contains(q) &&
          !farmer.farmName.toLowerCase().contains(q) &&
          !farmer.marketName.toLowerCase().contains(q) &&
          !farmer.location.toLowerCase().contains(q)) {
        return false;
      }
    }

    return true;
  }

  List<FarmerModel> get _visibleFarmers {
    final visible = _dataService.farmers.where((farmer) {
      if (farmer.latitude == null || farmer.longitude == null) return false;
      return _farmerMatchesCityAndArea(farmer);
    }).toList();

    visible.sort((first, second) {
      final firstDistance =
          _dataService.distanceFromCustomerToFarmer(first) ?? double.infinity;
      final secondDistance =
          _dataService.distanceFromCustomerToFarmer(second) ?? double.infinity;
      return firstDistance.compareTo(secondDistance);
    });
    return visible;
  }

  LatLng get _initialCenter {
    if (_selectedCity == 'All Pakistan') {
      return PakistanLocations.pakistanCenter;
    }
    final cityData = _currentCityData;
    if (cityData != null) {
      if (_selectedArea != 'All Areas') {
        final areaData = cityData.areas.firstWhere(
          (a) => a.name == _selectedArea,
          orElse: () => cityData.areas.first,
        );
        return areaData.center;
      }
      return cityData.center;
    }
    return const LatLng(24.8607, 67.0011); // Karachi default
  }

  Future<void> _locateCustomer() async {
    setState(() {
      _locating = true;
      _locationMessage = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      _dataService.setCustomerLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        _locating = false;
        _locationMessage = null;
      });
      if (_mapReady) {
        _mapController.move(LatLng(position.latitude, position.longitude), 13);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onCityChanged(String newCity) {
    setState(() {
      _selectedCity = newCity;
      _selectedArea = 'All Areas';
      _selectedFarmer = null;
    });
    if (_mapReady) {
      if (newCity == 'All Pakistan') {
        _mapController.move(PakistanLocations.pakistanCenter, PakistanLocations.pakistanZoom);
      } else {
        final cityData = _currentCityData;
        if (cityData != null) {
          _mapController.move(cityData.center, cityData.defaultZoom);
        }
      }
    }
  }

  void _onAreaChanged(String newArea) {
    setState(() {
      _selectedArea = newArea;
      _selectedFarmer = null;
    });
    if (_mapReady) {
      if (newArea == 'All Areas') {
        final cityData = _currentCityData;
        if (cityData != null) {
          _mapController.move(cityData.center, cityData.defaultZoom);
        }
      } else {
        final cityData = _currentCityData;
        final areaData = cityData?.areas.firstWhere(
          (a) => a.name == newArea,
          orElse: () => cityData.areas.first,
        );
        if (areaData != null) {
          _mapController.move(areaData.center, areaData.defaultZoom);
        }
      }
    }
  }

  void _selectFarmer(FarmerModel farmer) {
    setState(() => _selectedFarmer = farmer);
    if (farmer.latitude != null && farmer.longitude != null) {
      _mapController.move(LatLng(farmer.latitude!, farmer.longitude!), 15);
    }
    _showFarmerDetailBottomSheet(farmer);
  }

  void _showFarmerDetailBottomSheet(FarmerModel farmer) {
    final distance = _dataService.distanceFromCustomerToFarmer(farmer);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF15281E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0xFF88AB75), width: 1.5),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF1E3A2B),
                    backgroundImage: farmer.imageUrl.isNotEmpty
                        ? NetworkImage(farmer.imageUrl)
                        : null,
                    child: farmer.imageUrl.isEmpty
                        ? const Icon(Icons.person, color: Color(0xFFA1C68A), size: 28)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                farmer.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF0F5F1),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (farmer.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A2B),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFA1C68A).withAlpha(80),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 13,
                                      color: Color(0xFFA1C68A),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Verified',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFA1C68A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        Text(
                          farmer.farmName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF8FA497),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFE5B94C), size: 16),
                            const SizedBox(width: 3),
                            Text(
                              '${farmer.rating.toStringAsFixed(1)} (${farmer.reviewsCount} reviews)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFFF0F5F1),
                              ),
                            ),
                            if (distance != null) ...[
                              const Text(' • ', style: TextStyle(color: Colors.white38)),
                              Text(
                                '${distance.toStringAsFixed(1)} km away',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFA1C68A),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.white12),
              // Market Details
              Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: Color(0xFFA1C68A), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      farmer.marketName.isNotEmpty ? farmer.marketName : farmer.farmName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFF8FA497), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      farmer.location.isNotEmpty ? farmer.location : 'Location available on map',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8FA497),
                      ),
                    ),
                  ),
                ],
              ),
              if (farmer.marketHours.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: Color(0xFF8FA497), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        farmer.marketHours,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF8FA497),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF88AB75)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.directions_rounded, color: Color(0xFF88AB75)),
                      label: Text(
                        'Directions',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF88AB75),
                        ),
                      ),
                      onPressed: () async {
                        if (farmer.latitude != null && farmer.longitude != null) {
                          final url = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=${farmer.latitude},${farmer.longitude}',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF88AB75),
                        foregroundColor: const Color(0xFF0D1A13),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.storefront_rounded),
                      label: Text(
                        'View Produce',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FarmerProfileScreen(farmer: farmer),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A2B),
                      foregroundColor: const Color(0xFFA1C68A),
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    tooltip: 'Chat with Farmer',
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final currentUserId = AuthService().currentUser?.uid;
                      if (currentUserId == null) return;
                      final convId = await ChatService().createConversation(
                        otherUserId: farmer.id,
                        otherUserName: farmer.name,
                        otherUserAvatar: farmer.imageUrl,
                        otherUserRole: UserRole.farmer,
                      );
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              conversationId: convId,
                              otherUserName: farmer.name,
                              otherUserAvatar: farmer.imageUrl,
                              otherUserId: farmer.id,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(List<FarmerModel> farmers) {
    final markers = <Marker>[];

    // Customer position marker (blue pulsing beacon)
    final custLat = _dataService.customerLatitude;
    final custLng = _dataService.customerLongitude;
    if (custLat != null && custLng != null) {
      markers.add(
        Marker(
          point: LatLng(custLat, custLng),
          width: 50,
          height: 50,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 38 + (12 * _pulseController.value),
                    height: 38 + (12 * _pulseController.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2A9D8F).withOpacity(
                        (1.0 - _pulseController.value).clamp(0.0, 1.0) * 0.4,
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A9D8F),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    // Farmer markers
    for (final farmer in farmers) {
      if (farmer.latitude == null || farmer.longitude == null) continue;
      final isSelected = farmer.id == _selectedFarmer?.id;

      markers.add(
        Marker(
          point: LatLng(farmer.latitude!, farmer.longitude!),
          width: isSelected ? 80 : 54,
          height: isSelected ? 80 : 54,
          child: GestureDetector(
            onTap: () => _selectFarmer(farmer),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF88AB75)
                        : const Color(0xFF15281E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : (farmer.isVerified
                              ? const Color(0xFFA1C68A)
                              : const Color(0xFFE5B94C)),
                      width: isSelected ? 2.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: isSelected ? 22 : 16,
                    backgroundColor: const Color(0xFF1E3A2B),
                    backgroundImage: farmer.imageUrl.isNotEmpty
                        ? NetworkImage(farmer.imageUrl)
                        : null,
                    child: farmer.imageUrl.isEmpty
                        ? Icon(
                            Icons.agriculture_rounded,
                            color: isSelected
                                ? const Color(0xFF0D1A13)
                                : const Color(0xFFA1C68A),
                            size: isSelected ? 20 : 16,
                          )
                        : null,
                  ),
                ),
                // Pin triangle pointer
                CustomPaint(
                  size: const Size(10, 6),
                  painter: _TrianglePainter(
                    color: isSelected
                        ? const Color(0xFF88AB75)
                        : const Color(0xFF15281E),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final farmers = _visibleFarmers;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Live Farmer Markets Map',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'My Location',
            onPressed: _locating ? null : _locateCustomer,
            icon: _locating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // City & Area Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF15281E),
                border: Border(bottom: BorderSide(color: Colors.white.withAlpha(20))),
              ),
              child: Column(
                children: [
                  // City selector and Search row
                  Row(
                    children: [
                      // City dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3427),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF88AB75).withAlpha(80)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCity,
                            dropdownColor: const Color(0xFF1A3427),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFFA1C68A), size: 20),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF0F5F1),
                            ),
                            items: [
                              'All Pakistan',
                              ...PakistanLocations.cities.map((c) => c.name),
                            ].map((city) {
                              return DropdownMenuItem(
                                value: city,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      city == 'All Pakistan'
                                          ? Icons.public_rounded
                                          : Icons.location_city_rounded,
                                      size: 15,
                                      color: const Color(0xFFA1C68A),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(city),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) _onCityChanged(val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Search farmer on map
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: GoogleFonts.inter(
                              color: const Color(0xFFF0F5F1), fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search farm or farmer...',
                            hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF6B8A74), fontSize: 12),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: Color(0xFF8FA497), size: 18),
                            filled: true,
                            fillColor: const Color(0xFF1A3427),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Area chips (shown for selected city like Karachi / Lahore / Islamabad)
                  if (_availableAreas.length > 1) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableAreas.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final area = _availableAreas[index];
                          final isSelected = _selectedArea == area;
                          return ChoiceChip(
                            label: Text(area),
                            selected: isSelected,
                            selectedColor: const Color(0xFF88AB75),
                            backgroundColor: const Color(0xFF1A3427),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF0D1A13)
                                  : const Color(0xFFF0F5F1),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFFA1C68A)
                                  : Colors.white.withAlpha(20),
                            ),
                            onSelected: (selected) {
                              if (selected) _onAreaChanged(area);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Interactive Map View
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _initialCenter,
                      initialZoom: 11.5,
                      minZoom: 4,
                      maxZoom: 18,
                      onMapReady: () => _mapReady = true,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.harvesthub_app',
                      ),
                      MarkerLayer(markers: _buildMarkers(farmers)),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            '© OpenStreetMap contributors',
                            onTap: () => launchUrl(
                              Uri.parse('https://www.openstreetmap.org/copyright'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Info Badge on Top-Left
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15281E).withAlpha(235),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(30)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.agriculture_rounded,
                              color: Color(0xFFA1C68A), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${farmers.length} Farmers in $_selectedCity',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF0F5F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recenter to selected city button
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'map_recenter',
                      backgroundColor: const Color(0xFF15281E),
                      foregroundColor: const Color(0xFFA1C68A),
                      onPressed: () {
                        final cityData = _currentCityData;
                        if (cityData != null) {
                          _mapController.move(cityData.center, cityData.defaultZoom);
                        } else {
                          _mapController.move(PakistanLocations.pakistanCenter, PakistanLocations.pakistanZoom);
                        }
                      },
                      child: const Icon(Icons.center_focus_strong_rounded),
                    ),
                  ),

                  if (farmers.isEmpty)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15281E).withAlpha(245),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withAlpha(25)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_off_rounded,
                              size: 36,
                              color: Color(0xFFE5B94C),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No farmers found in $_selectedCity ($_selectedArea)',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF0F5F1),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try selecting "All Pakistan" or another city.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF8FA497),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom horizontal carousel of mapped farmers
            if (farmers.isNotEmpty)
              Container(
                height: 145,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: const Color(0xFF0D1A13),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: farmers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final f = farmers[index];
                    final isSelected = f.id == _selectedFarmer?.id;
                    return GestureDetector(
                      onTap: () => _selectFarmer(f),
                      child: Container(
                        width: 240,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15281E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF88AB75)
                                : Colors.white.withAlpha(20),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF1E3A2B),
                                  backgroundImage: f.imageUrl.isNotEmpty
                                      ? NetworkImage(f.imageUrl)
                                      : null,
                                  child: f.imageUrl.isEmpty
                                      ? const Icon(Icons.person,
                                          color: Color(0xFFA1C68A), size: 18)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFF0F5F1),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        f.farmName,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFF8FA497),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                    const SizedBox(width: 3),
                                    Text(
                                      f.rating.toStringAsFixed(1),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFFF0F5F1),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  f.location.isNotEmpty ? f.location : 'Market Stall',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFFA1C68A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
