import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../data/dummy_categories.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';

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
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
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
        images: const [],
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      await ProductService().addProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing posted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Post a Listing',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image placeholder
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: AppColors.primary.withValues(alpha: 0.6)),
                    const SizedBox(height: 8),
                    Text('Add Photos (coming soon)',
                        style: TextStyle(
                            color: AppColors.primary.withValues(alpha: 0.7),
                            fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: _dec('Title', Icons.title, hint: 'e.g. Calculus Textbook'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required.' : null,
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descController,
                decoration: _dec('Description', Icons.description_outlined,
                    hint: 'Describe your item...'),
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required.'
                    : null,
              ),
              const SizedBox(height: 14),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: _dec('Price (JD)', Icons.attach_money_rounded,
                    hint: '0.00'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required.';
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
                    .map((cat) => DropdownMenuItem(
                          value: cat.name,
                          child: Row(
                            children: [
                              Icon(cat.icon, color: cat.color, size: 18),
                              const SizedBox(width: 8),
                              Text(cat.name),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) =>
                    v == null ? 'Please select a category.' : null,
              ),
              const SizedBox(height: 14),

              // Course code (optional)
              TextFormField(
                controller: _courseController,
                decoration: _dec('Course Code (optional)',
                    Icons.book_outlined, hint: 'e.g. CS101'),
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
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.publish_rounded,
                          color: Colors.white),
                      label: const Text(
                        'Post Listing',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
