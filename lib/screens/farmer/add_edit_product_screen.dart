import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/farmer_model.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataService = DataService();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _unitCtrl;

  String? _selectedCategory;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  List<String> get _categories =>
      _dataService.categories.map((category) => category.name).toList();

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _descCtrl = TextEditingController(text: widget.product?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.product != null
          ? widget.product!.price.toStringAsFixed(0)
          : '',
    );
    _stockCtrl = TextEditingController(
      text: widget.product != null ? widget.product!.stockKg.toString() : '',
    );
    _unitCtrl = TextEditingController(text: widget.product?.unit ?? 'kg');
    _selectedCategory = widget.product?.category;
    _imageUrl = widget.product?.imageUrl;
    _dataService
        .loadCatalog()
        .then((_) {
          if (!mounted || _selectedCategory != null || _categories.isEmpty)
            return;
          setState(() => _selectedCategory = _categories.first);
        })
        .catchError((error) {
          debugPrint('Could not load product categories: $error');
        });
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _unitCtrl.dispose();
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  Future<void> _uploadImageToCloudinary() async {
    // Step 1: Gallery se user khud image chunta hai
    final pickedFile = await CloudinaryService.pickImageFromGallery();
    if (pickedFile == null) {
      // User ne gallery dialog cancel kar diya, kuch nahi karna
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Step 2: Real Cloudinary upload
      final url = await CloudinaryService.uploadImage(
        pickedFile,
        folder: 'produce',
      );
      setState(() {
        _imageUrl = url;
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully.'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create or select a category first.')),
      );
      return;
    }
    if (AuthService().currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in as a farmer first.')),
      );
      return;
    }
    _imageUrl ??= CloudinaryService.getCategoryPlaceholder(_selectedCategory!);

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final uid = AuthService().currentUser?.uid;
    FarmerModel? currentFarmer;
    for (final f in DataService().farmers) {
      if (f.id == uid) {
        currentFarmer = f;
        break;
      }
    }
    final resolvedMarketName = (widget.product != null &&
            widget.product!.marketName.isNotEmpty &&
            !widget.product!.marketName.toLowerCase().contains('model town'))
        ? widget.product!.marketName
        : (currentFarmer?.marketName.isNotEmpty == true
            ? currentFarmer!.marketName
            : (currentFarmer?.location.isNotEmpty == true
                ? currentFarmer!.location
                : (AuthService().userModel?.address.isNotEmpty == true
                    ? AuthService().userModel!.address
                    : 'Local Farmer Market')));

    final newProduct = ProductModel(
      id: widget.product?.id ?? 'prod_${DateTime.now().millisecondsSinceEpoch}',
      title: _nameCtrl.text.trim(),
      category: _selectedCategory!,
      price: double.tryParse(_priceCtrl.text.trim()) ?? 100.0,
      unit: _unitCtrl.text.trim(),
      imageUrl: _imageUrl!,
      stock: int.tryParse(_stockCtrl.text.trim()) ?? 20,
      farmerId:
          widget.product?.farmerId ?? AuthService().currentUser?.uid ?? '',
      farmerName:
          widget.product?.farmerName ??
          AuthService().userModel?.fullName ??
          'My Farm',
      farmerPhone:
          widget.product?.farmerPhone ?? AuthService().userModel?.phone ?? '',
      farmerFarm: widget.product?.farmerFarm ?? currentFarmer?.farmName ?? 'My Farm',
      rating: widget.product?.rating ?? 4.9,
      distanceKm: widget.product?.distanceKm ?? currentFarmer?.distanceKm ?? 0.0,
      marketName: resolvedMarketName,
      description: _descCtrl.text.trim(),
      isOrganic: true,
      freshnessScore: widget.product?.freshnessScore ?? 96,
      priceInsight: 'Direct farm price within standard wholesale range.',
      reviewsCount: widget.product?.reviewsCount ?? 12,
      harvestDate: DateTime.now().subtract(const Duration(hours: 6)),
    );

    if (widget.product != null) {
      await DataService().updateProduct(newProduct);
    } else {
      await DataService().addProduct(newProduct);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.product != null
              ? 'Product updated successfully!'
              : 'New produce added to store!',
        ),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          isEdit ? 'Edit Produce' : 'Add New Produce',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker / Cloudinary Uploader
              Text(
                'Produce Image (Cloudinary Hosted)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF0F5F1),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isUploading ? null : _uploadImageToCloudinary,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF15281E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withAlpha(25),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _isUploading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Uploading to Cloudinary...',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : _imageUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.black.withValues(alpha: 0.3),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to Upload Image to Cloudinary',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              'Supports JPEG, PNG up to 10MB',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Produce Name
              Text(
                'Produce Name',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF0F5F1),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                decoration: const InputDecoration(
                  hintText: 'e.g. Farm Fresh Tomatoes',
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please enter produce name'
                    : null,
              ),
              const SizedBox(height: 16),

              // Category Selector
              Text(
                'Category',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF0F5F1),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF15281E),
                style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                initialValue: _categories.contains(_selectedCategory)
                    ? _selectedCategory
                    : null,
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFF0F5F1),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: const InputDecoration(
                  hintText: 'Select a category',
                ),
                validator: (value) =>
                    value == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 16),

              // Price & Stock
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price (Rs.)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF0F5F1),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFF0F5F1),
                          ),
                          decoration: const InputDecoration(hintText: '120'),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock Available',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF0F5F1),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _stockCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFF0F5F1),
                          ),
                          decoration: const InputDecoration(hintText: '50'),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Unit
              Text(
                'Unit (e.g. kg, bunch, liter, dozen)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF0F5F1),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _unitCtrl,
                style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                decoration: const InputDecoration(hintText: 'kg'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Description & Harvest Notes',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF0F5F1),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                decoration: const InputDecoration(
                  hintText:
                      'Describe how this crop was harvested, organic methods used, etc.',
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? 'Save Changes' : 'List Produce on Market',
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
