import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../models/farmer_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/pakistan_locations.dart';

class FarmerMarketLocationScreen extends StatefulWidget {
  const FarmerMarketLocationScreen({super.key});

  @override
  State<FarmerMarketLocationScreen> createState() =>
      _FarmerMarketLocationScreenState();
}

class _FarmerMarketLocationScreenState
    extends State<FarmerMarketLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _marketNameController = TextEditingController();
  final _marketHoursController = TextEditingController();
  final _locationController = TextEditingController();
  final _dataService = DataService();
  final MapController _mapController = MapController();

  String _selectedCity = 'Karachi';
  String _selectedArea = 'North Karachi';

  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _saving = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    final uid = AuthService().currentUser?.uid;
    FarmerModel? farmer;
    for (final entry in _dataService.farmers) {
      if (entry.id == uid) {
        farmer = entry;
        break;
      }
    }
    _marketNameController.text = farmer?.marketName ?? '';
    _marketHoursController.text = farmer?.marketHours ?? 'Mon-Sat: 8:00 AM - 6:00 PM';
    _locationController.text =
        farmer?.location ?? AuthService().userModel?.address ?? 'Karachi, Pakistan';
    _latitude = farmer?.latitude ?? 24.9961;
    _longitude = farmer?.longitude ?? 67.0658;
    _loadSavedLocation();
  }

  @override
  void dispose() {
    _marketNameController.dispose();
    _marketHoursController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLocation() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .get();
      final data = snapshot.data();
      if (!mounted || data == null) return;
      setState(() {
        _marketNameController.text =
            data['marketName'] as String? ?? _marketNameController.text;
        _marketHoursController.text =
            data['marketHours'] as String? ?? _marketHoursController.text;
        _locationController.text =
            data['location'] as String? ?? _locationController.text;
        _latitude = (data['latitude'] as num?)?.toDouble() ?? _latitude;
        _longitude = (data['longitude'] as num?)?.toDouble() ?? _longitude;
        if (data['city'] != null) _selectedCity = data['city'];
        if (data['area'] != null) _selectedArea = data['area'];
      });
      if (_mapReady && _latitude != null && _longitude != null) {
        _mapController.move(LatLng(_latitude!, _longitude!), 14);
      }
    } catch (error) {
      debugPrint('Could not load farmer market location: $error');
    }
  }

  LocationCity get _currentCityData {
    return PakistanLocations.cities.firstWhere(
      (c) => c.name.toLowerCase() == _selectedCity.toLowerCase(),
      orElse: () => PakistanLocations.cities.first,
    );
  }

  List<String> get _availableAreas {
    return _currentCityData.areas.map((a) => a.name).toList();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on Location Services and try again.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Allow location access to pin your market.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      if (_mapReady) {
        _mapController.move(LatLng(position.latitude, position.longitude), 15);
      }
      _showMessage('Market pin set to your current GPS position!');
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onCityChanged(String newCity) {
    setState(() {
      _selectedCity = newCity;
      final cityData = PakistanLocations.cities.firstWhere(
        (c) => c.name == newCity,
        orElse: () => PakistanLocations.cities.first,
      );
      _selectedArea = cityData.areas.isNotEmpty ? cityData.areas.first.name : 'Central';
      _latitude = cityData.center.latitude;
      _longitude = cityData.center.longitude;
      _locationController.text = '$_selectedArea, $_selectedCity';
    });
    if (_mapReady && _latitude != null && _longitude != null) {
      _mapController.move(LatLng(_latitude!, _longitude!), 13);
    }
  }

  void _onAreaChanged(String newArea) {
    setState(() {
      _selectedArea = newArea;
      final cityData = _currentCityData;
      final areaData = cityData.areas.firstWhere(
        (a) => a.name == newArea,
        orElse: () => cityData.areas.first,
      );
      _latitude = areaData.center.latitude;
      _longitude = areaData.center.longitude;
      _locationController.text = '$_selectedArea, $_selectedCity';
    });
    if (_mapReady && _latitude != null && _longitude != null) {
      _mapController.move(LatLng(_latitude!, _longitude!), 14.5);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      _showMessage('Sign in to save your market details.');
      return;
    }
    if (_latitude == null || _longitude == null) {
      _showMessage('Please select your location on the map.');
      return;
    }

    setState(() => _saving = true);
    try {
      final user = AuthService().userModel;
      final batch = FirebaseFirestore.instance.batch();

      final farmerRef = FirebaseFirestore.instance.collection('farmers').doc(uid);
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      final marketData = {
        'name': user?.fullName ?? 'Farmer',
        'farmName': _marketNameController.text.trim().isNotEmpty
            ? _marketNameController.text.trim()
            : '${user?.fullName ?? 'Farmer'} Farm',
        'location': _locationController.text.trim(),
        'city': _selectedCity,
        'area': _selectedArea,
        'latitude': _latitude,
        'longitude': _longitude,
        'marketName': _marketNameController.text.trim(),
        'marketHours': _marketHoursController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.set(farmerRef, marketData, SetOptions(merge: true));
      batch.set(userRef, {
        'address': _locationController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'marketName': _marketNameController.text.trim(),
        'marketHours': _marketHoursController.text.trim(),
        'city': _selectedCity,
        'area': _selectedArea,
      }, SetOptions(merge: true));

      await batch.commit();

      try {
        await _dataService.loadCatalog();
      } catch (error) {
        debugPrint('Market saved; catalog refresh failed: $error');
      }

      if (mounted) {
        _showMessage('Market location & hours saved successfully!');
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) _showMessage('Could not save market details: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E3A2B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPoint = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : const LatLng(24.8607, 67.0011);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Set Market Location & Hours',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                'Live Map Market Location',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF0F5F1),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set your exact farm or stall location on the map. Customers in your area will discover your produce directly on their map.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF8FA497),
                ),
              ),
              const SizedBox(height: 16),

              // City & Area Selector Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'City',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8FA497),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15281E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withAlpha(25)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedCity,
                              dropdownColor: const Color(0xFF15281E),
                              style: GoogleFonts.inter(
                                color: const Color(0xFFF0F5F1),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              items: PakistanLocations.cities.map((c) {
                                return DropdownMenuItem(
                                  value: c.name,
                                  child: Text(c.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _onCityChanged(val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Area / Neighborhood',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8FA497),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15281E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withAlpha(25)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _availableAreas.contains(_selectedArea)
                                  ? _selectedArea
                                  : (_availableAreas.isNotEmpty ? _availableAreas.first : null),
                              dropdownColor: const Color(0xFF15281E),
                              style: GoogleFonts.inter(
                                color: const Color(0xFFF0F5F1),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              items: _availableAreas.map((area) {
                                return DropdownMenuItem(
                                  value: area,
                                  child: Text(
                                    area,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _onAreaChanged(val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Interactive Map Picker Container
              Text(
                'Tap anywhere on map to position your exact pin:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFA1C68A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF88AB75), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: currentPoint,
                          initialZoom: 14,
                          minZoom: 4,
                          maxZoom: 18,
                          onMapReady: () => _mapReady = true,
                          onTap: (tapPosition, point) {
                            setState(() {
                              _latitude = point.latitude;
                              _longitude = point.longitude;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.harvesthub_app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentPoint,
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFFE76F51),
                                  size: 42,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: FloatingActionButton.small(
                          heroTag: 'farmer_gps_btn',
                          backgroundColor: const Color(0xFF15281E),
                          foregroundColor: const Color(0xFFA1C68A),
                          onPressed: _locating ? null : _useCurrentLocation,
                          child: _locating
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_latitude != null && _longitude != null)
                Text(
                  'Pin Coordinates: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFA1C68A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 18),

              // Form fields
              TextFormField(
                controller: _marketNameController,
                style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                decoration: InputDecoration(
                  labelText: 'Market / Stall Name',
                  hintText: 'e.g. Fresh Daily Market, Sunday Farm Bazaar',
                  prefixIcon: const Icon(Icons.storefront_outlined, color: Color(0xFFA1C68A)),
                  filled: true,
                  fillColor: const Color(0xFF15281E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF88AB75)),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter market name' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _locationController,
                style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                decoration: InputDecoration(
                  labelText: 'Full Address / Location Details',
                  hintText: 'e.g. 11-A North Karachi, near Power House',
                  prefixIcon: const Icon(Icons.place_outlined, color: Color(0xFFA1C68A)),
                  filled: true,
                  fillColor: const Color(0xFF15281E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF88AB75)),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _marketHoursController,
                style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                decoration: InputDecoration(
                  labelText: 'Market Operating Hours',
                  hintText: 'e.g. Daily: 7:00 AM - 9:00 PM',
                  prefixIcon: const Icon(Icons.schedule_rounded, color: Color(0xFFA1C68A)),
                  filled: true,
                  fillColor: const Color(0xFF15281E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF88AB75)),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter operating hours' : null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF88AB75),
                    foregroundColor: const Color(0xFF0D1A13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0D1A13),
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _saving ? 'Saving...' : 'Save Market Location & Hours',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
