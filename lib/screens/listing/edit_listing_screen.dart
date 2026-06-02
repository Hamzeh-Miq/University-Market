import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../data/dummy_categories.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../services/storage_service.dart';

/// Screen that lets a post owner edit their listing.
///
/// **Discount changes** — applied instantly with no admin re-approval needed.
/// **Other changes** (title, description, category, courseCode, images) — sets
/// the listing back to pending so an admin must re-approve before it is
/// visible again in the marketplace.
class EditListingScreen extends ConsumerStatefulWidget {
  /// The product to edit — passed as a route argument.
  final ProductModel product;

  const EditListingScreen({super.key, required this.product});

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Discount tab ──────────────────────────────────────────────────────────
  final _discountFormKey = GlobalKey<FormState>();
  late final TextEditingController _discountPriceController;
  bool _savingDiscount = false;

  // ── Edit details tab ──────────────────────────────────────────────────────
  final _detailsFormKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _courseController;
  String? _selectedCategory;

  /// Network URLs already on the product (kept unless removed by user).
  late List<String> _existingImageUrls;

  /// New local images the user picked in this session.
  final List<XFile> _newImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _savingDetails = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Discount tab pre-fill
    _discountPriceController = TextEditingController(
      text: widget.product.discountedPrice?.toStringAsFixed(2) ?? '',
    );

    // Details tab pre-fill
    _titleController = TextEditingController(text: widget.product.title);
    _descController = TextEditingController(text: widget.product.description);
    _courseController = TextEditingController(
      text: widget.product.courseCode ?? '',
    );
    _selectedCategory = widget.product.category;
    _existingImageUrls = List<String>.from(widget.product.images);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _discountPriceController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  // ── Shared input decoration ───────────────────────────────────────────────

  InputDecoration _dec(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }

  // ── Discount tab logic ────────────────────────────────────────────────────

  Future<void> _saveDiscount() async {
    if (!_discountFormKey.currentState!.validate()) return;
    setState(() => _savingDiscount = true);

    final input = _discountPriceController.text.trim();
    final double? discountedPrice = input.isEmpty
        ? null
        : double.tryParse(input);

    try {
      await ref
          .read(productServiceProvider)
          .applyDiscount(
            widget.product.productId,
            discountedPrice: discountedPrice,
          );

      ref.invalidate(singleProductProvider(widget.product.productId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              discountedPrice == null
                  ? 'Discount removed. Your listing is still live.'
                  : 'Discount applied instantly! Listing is still live.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            content: const Text('Failed to apply discount. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingDiscount = false);
    }
  }

  // ── Details tab logic ─────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          final total = _existingImageUrls.length + _newImages.length;
          if (total < 5) {
            _newImages.add(image);
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

  Future<void> _saveDetails() async {
    if (!_detailsFormKey.currentState!.validate()) return;
    setState(() => _savingDetails = true);

    try {
      // Upload any newly picked images
      final List<String> allUrls = List<String>.from(_existingImageUrls);
      if (_newImages.isNotEmpty) {
        final storageService = StorageService();
        for (final file in _newImages) {
          final url = await storageService.compressAndUploadImage(file);
          allUrls.add(url);
        }
      }

      await ref
          .read(productServiceProvider)
          .editProduct(
            productId: widget.product.productId,
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            category: _selectedCategory!,
            courseCode: _courseController.text.trim().isEmpty
                ? null
                : _courseController.text.trim().toUpperCase(),
            images: allUrls,
          );

      ref.invalidate(singleProductProvider(widget.product.productId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
            content: const Text(
              'Changes saved. Your listing is now pending admin approval '
              'and won\'t be visible until approved.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save changes. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingDetails = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Edit Listing',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.local_offer_outlined), text: 'Discount'),
            Tab(icon: Icon(Icons.edit_note_outlined), text: 'Edit Details'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DiscountTab(
            product: widget.product,
            formKey: _discountFormKey,
            controller: _discountPriceController,
            isSaving: _savingDiscount,
            onSave: _saveDiscount,
          ),
          _DetailsTab(
            product: widget.product,
            formKey: _detailsFormKey,
            titleController: _titleController,
            descController: _descController,
            courseController: _courseController,
            selectedCategory: _selectedCategory,
            existingImageUrls: _existingImageUrls,
            newImages: _newImages,
            isSaving: _savingDetails,
            onCategoryChanged: (v) => setState(() => _selectedCategory = v),
            onRemoveExisting: (i) =>
                setState(() => _existingImageUrls.removeAt(i)),
            onRemoveNew: (i) => setState(() => _newImages.removeAt(i)),
            onPickImage: _pickImage,
            onSave: _saveDetails,
            dec: _dec,
          ),
        ],
      ),
    );
  }
}

// ── Discount Tab ──────────────────────────────────────────────────────────────

class _DiscountTab extends StatelessWidget {
  final ProductModel product;
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isSaving;
  final VoidCallback onSave;

  const _DiscountTab({
    required this.product,
    required this.formKey,
    required this.controller,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Discounts are applied instantly — no admin approval '
                      'needed. Your listing stays visible and live.',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Original price display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sell_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Original Price',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'JD ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Discounted price input
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'Discounted Price (JD)',
                hintText: 'Enter a price lower than the original',
                prefixIcon: const Icon(
                  Icons.local_offer_outlined,
                  color: AppColors.primary,
                ),
                suffixText: 'JD',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return null; // allow empty = remove discount
                }
                final parsed = double.tryParse(v.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid price greater than 0.';
                }
                if (parsed >= product.price) {
                  return 'Discounted price must be lower than JD ${product.price.toStringAsFixed(2)}.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Leave empty to remove an existing discount.',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
            const SizedBox(height: 28),

            // Save button
            isSaving
                ? const Center(child: CircularProgressIndicator())
                : FilledButton.icon(
                    onPressed: onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.local_offer_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Apply Discount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Details Tab ───────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  final ProductModel product;
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController courseController;
  final String? selectedCategory;
  final List<String> existingImageUrls;
  final List<XFile> newImages;
  final bool isSaving;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;
  final VoidCallback onPickImage;
  final VoidCallback onSave;
  final InputDecoration Function(String, IconData, {String? hint}) dec;

  const _DetailsTab({
    required this.product,
    required this.formKey,
    required this.titleController,
    required this.descController,
    required this.courseController,
    required this.selectedCategory,
    required this.existingImageUrls,
    required this.newImages,
    required this.isSaving,
    required this.onCategoryChanged,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    required this.onPickImage,
    required this.onSave,
    required this.dec,
  });

  @override
  Widget build(BuildContext context) {
    final totalImages = existingImageUrls.length + newImages.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Changes to title, description, category, or images '
                      'require admin approval. Your listing will be hidden '
                      'from the marketplace until an admin re-approves it.',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Image section
            const Text(
              'Images',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Existing network images
                  ...List.generate(existingImageUrls.length, (i) {
                    return _ImageTile(
                      child: Image.network(
                        existingImageUrls[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textHint,
                        ),
                      ),
                      onRemove: () => onRemoveExisting(i),
                    );
                  }),
                  // Newly picked local images
                  ...List.generate(newImages.length, (i) {
                    return _ImageTile(
                      child: kIsWeb
                          ? Image.network(newImages[i].path, fit: BoxFit.cover)
                          : Image.file(
                              File(newImages[i].path),
                              fit: BoxFit.cover,
                            ),
                      onRemove: () => onRemoveNew(i),
                    );
                  }),
                  // Add button (max 5)
                  if (totalImages < 5)
                    GestureDetector(
                      onTap: onPickImage,
                      child: Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 30,
                              color: AppColors.primary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                color: AppColors.primary.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: titleController,
              decoration: dec(
                'Title',
                Icons.title,
                hint: 'e.g. Calculus Textbook',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required.' : null,
            ),
            const SizedBox(height: 14),

            // Description
            TextFormField(
              controller: descController,
              decoration: dec(
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

            // Category dropdown
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: dec('Category', Icons.category_outlined),
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
              onChanged: onCategoryChanged,
              validator: (v) => v == null ? 'Please select a category.' : null,
            ),
            const SizedBox(height: 14),

            // Course code
            TextFormField(
              controller: courseController,
              decoration: dec(
                'Course Code (optional)',
                Icons.book_outlined,
                hint: 'e.g. CS101',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 28),

            // Save button
            isSaving
                ? const Center(child: CircularProgressIndicator())
                : FilledButton.icon(
                    onPressed: onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.save_outlined, color: Colors.white),
                    label: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Image tile helper ─────────────────────────────────────────────────────────

class _ImageTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _ImageTile({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(width: 110, height: 110, child: child),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
