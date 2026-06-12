import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/product_status.dart';
import '../../data/dummy_categories.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/subscription_gate.dart';

/// Screen for posting a new product listing to the marketplace.
class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _courseController = TextEditingController();

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      // All fill/border styles come from InputDecorationTheme in main.dart
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          if (_selectedImages.length < 5) {
            _selectedImages.add(image);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maximum 5 images allowed.')),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to post.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> uploadedUrls = [];
      if (_selectedImages.isNotEmpty) {
        final storageService = ref.read(storageServiceProvider);
        for (final file in _selectedImages) {
          final url = await storageService.compressAndUploadImage(file);
          uploadedUrls.add(url);
        }
      }

      final userProfile = ref.read(currentUserModelProvider).value;
      final university = userProfile?.university;

      final product = ProductModel(
        productId: '',
        sellerId: user.uid,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory!,
        courseCode: _courseController.text.trim().isEmpty
            ? null
            : _courseController.text.trim().toUpperCase(),
        images: uploadedUrls,
        status: ProductStatus.legacyPending, // Required by Firestore rules
        createdAt: DateTime.now(),
        sellerUniversity: university,
      );

      await ref.read(productServiceProvider).addProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Listing submitted! It will appear after admin approval.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit listing. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubscribed = ref.watch(hasActiveSubscriptionProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final hasAccess = isSubscribed || isAdmin;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Post a Listing',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: hasAccess
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image picker row
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length < 5
                            ? _selectedImages.length + 1
                            : 5,
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length &&
                              _selectedImages.length < 5) {
                            return GestureDetector(
                              onTap: _showImagePickerModal,
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.07,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 32,
                                      color: AppColors.primary.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: kIsWeb
                                      ? Image.network(
                                          _selectedImages[index].path,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(_selectedImages[index].path),
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
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
                    const SizedBox(height: 20),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: _dec(
                        'Title',
                        Icons.title,
                        hint: 'e.g. Calculus Textbook',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required.'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Description
                    TextFormField(
                      controller: _descController,
                      decoration: _dec(
                        'Description',
                        Icons.description_outlined,
                        hint: 'Describe your item...',
                      ),
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Description is required.'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      decoration: _dec(
                        'Price (JD)',
                        Icons.attach_money_rounded,
                        hint: '0.00',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Price is required.';
                        }
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null || parsed < 0) {
                          return 'Enter a valid price.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _dec('Category', Icons.category_outlined),
                      items: dummyCategories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat.name,
                              child: Row(
                                children: [
                                  Icon(cat.icon, color: cat.color, size: 18),
                                  const SizedBox(width: 8),
                                  Text(cat.name),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      validator: (v) =>
                          v == null ? 'Please select a category.' : null,
                    ),
                    const SizedBox(height: 14),

                    // Course code (optional)
                    TextFormField(
                      controller: _courseController,
                      decoration: _dec(
                        'Course Code (optional)',
                        Icons.book_outlined,
                        hint: 'e.g. CS101',
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 28),

                    // Submit button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : FilledButton.icon(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.publish_rounded,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Post Listing',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            )
          : const SubscriptionGate(
              featureLabel: 'posting listings',
              fullPage: true,
              child: SizedBox.shrink(),
            ),
    );
  }
}
