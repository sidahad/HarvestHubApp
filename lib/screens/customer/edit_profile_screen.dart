import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../services/auth_service.dart';

// =========================================================================
// CLOUDINARY CONFIG
// Replace these with your own Cloudinary cloud name + an UNSIGNED upload
// preset (Cloudinary Dashboard -> Settings -> Upload -> Add upload preset,
// set "Signing Mode" to "Unsigned").
// =========================================================================
const String kCloudinaryCloudName = 'dmlxze89y';
const String kCloudinaryUploadPreset = 'FireGuard';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isFetchingLocation = false;

  File? _pickedImageFile;
  String? _profileImageUrl; // existing image URL (from Firestore) if any

  @override
  void initState() {
    super.initState();
    final user = _authService.userModel;
    _nameController = TextEditingController(
      text: user?.fullName ?? 'Harvest Customer',
    );
    _phoneController = TextEditingController(
      text: user?.phone ?? '+92 300 1234567',
    );
    _addressController = TextEditingController(
      text: user?.address ?? 'House 42, Street 8, Green Farm Town, Lahore',
    );
    // Preload existing profile photo (if any) from the user model.
    _profileImageUrl = user?.profilePic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // IMAGE PICK + CLOUDINARY UPLOAD
  // -----------------------------------------------------------------------
  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15281E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: Color(0xFF88AB75),
                ),
                title: Text(
                  'Take a photo',
                  style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF88AB75),
                ),
                title: Text(
                  'Choose from gallery',
                  style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (picked == null) return;

      setState(() {
        _pickedImageFile = File(picked.path);
        _isUploadingImage = true;
      });

      final uploadedUrl = await _uploadImageToCloudinary(_pickedImageFile!);

      if (uploadedUrl != null) {
        setState(() => _profileImageUrl = uploadedUrl);
      } else {
        _showError('Image upload failed. Please try again.');
      }
    } catch (e) {
      _showError('Could not pick image: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  /// Uploads [imageFile] to Cloudinary using an unsigned upload preset and
  /// returns the resulting `secure_url`, or null on failure.
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$kCloudinaryCloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = kCloudinaryUploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      } else {
        debugPrint(
          'Cloudinary upload failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }

  // -----------------------------------------------------------------------
  // LIVE LOCATION -> ADDRESS
  // -----------------------------------------------------------------------
  Future<void> _useCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable GPS.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied.';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied. Enable it from app settings.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts =
            [p.street, p.subLocality, p.locality, p.administrativeArea]
                .whereType<String>()
                .map((part) => part.trim())
                .where((part) => part.isNotEmpty)
                .toList();

        final address = parts.join(', ');
        setState(() => _addressController.text = address);
      } else {
        _showError('Could not resolve address from current location.');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  // -----------------------------------------------------------------------
  // SAVE PROFILE (Firestore, via AuthService)
  // -----------------------------------------------------------------------
  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        photoUrl:
            _profileImageUrl, // <-- add a `photoUrl` param to AuthService.updateProfile
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF1E3827),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD9534F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1A13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Color(0xFFF0F5F1),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF0F5F1),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 14),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Visual with camera badge (tappable now)
                Center(
                  child: GestureDetector(
                    onTap: _isUploadingImage ? null : _showImageSourceSheet,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF88AB75).withAlpha(80),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: const Color(0xFF1F3A2B),
                            backgroundImage: _pickedImageFile != null
                                ? FileImage(_pickedImageFile!)
                                : (_profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                            as ImageProvider
                                      : null),
                            child:
                                (_pickedImageFile == null &&
                                    _profileImageUrl == null)
                                ? const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF88AB75),
                                    size: 44,
                                  )
                                : null,
                          ),
                        ),
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black45,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF88AB75),
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF88AB75),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 15,
                              color: Color(0xFF0D1A13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Full Name
                _label('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFF0F5F1),
                    fontSize: 14,
                  ),
                  decoration: _inputDecoration(
                    'Full Name',
                    Icons.person_outline,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 18),

                // Phone
                _label('Phone Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFF0F5F1),
                    fontSize: 14,
                  ),
                  decoration: _inputDecoration(
                    'Phone Number',
                    Icons.phone_outlined,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Phone number is required'
                      : null,
                ),
                const SizedBox(height: 18),

                // Address + Live location button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _label('Delivery Address'),
                    TextButton.icon(
                      onPressed: _isFetchingLocation
                          ? null
                          : _useCurrentLocation,
                      icon: _isFetchingLocation
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Color(0xFF88AB75),
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.my_location,
                              size: 15,
                              color: Color(0xFF88AB75),
                            ),
                      label: Text(
                        'Use current location',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF88AB75),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFF0F5F1),
                    fontSize: 14,
                  ),
                  decoration: _inputDecoration(
                    'Delivery Address',
                    Icons.location_on_outlined,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Address is required'
                      : null,
                ),
                const SizedBox(height: 36),

                // Save Changes Pill Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isUploadingImage)
                        ? null
                        : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF88AB75),
                      foregroundColor: const Color(0xFF0D1A13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Color(0xFF0D1A13),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Save Changes',
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
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF6B8A74),
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF88AB75), size: 20),
      filled: true,
      fillColor: const Color(0xFF15281E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withAlpha(20)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withAlpha(20)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF88AB75), width: 1.5),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFF0F5F1),
      ),
    );
  }
}
