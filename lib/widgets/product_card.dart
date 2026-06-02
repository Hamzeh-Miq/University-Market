import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/product_model.dart';

/// A card widget used in product listing grids.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onWatchlistToggle;
  final bool isWatched;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onWatchlistToggle,
    this.isWatched = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radius),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppColors.radius),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.images.isNotEmpty
                      ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onWatchlistToggle,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            isWatched
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 19,
                            color: isWatched
                                ? AppColors.favourite
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          product.sellerUniversity ?? 'Campus marketplace',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.metadata,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'JD ${product.effectivePrice.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.priceLarge,
                        ),
                      ),
                      if (product.hasDiscount)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: Text(
                            '${product.discountPercent}% off',
                            style: AppTextStyles.metadata.copyWith(
                              color: AppColors.favourite,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.softBlueGradient),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.primary,
        size: 36,
      ),
    );
  }
}
