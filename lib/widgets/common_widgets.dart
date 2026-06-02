import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

/// A standardised loading shimmer placeholder for lists/grids.
class LoadingPlaceholder extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const LoadingPlaceholder({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A reusable empty-state widget.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Rounded gradient button used for premium primary actions.
class GradientActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const GradientActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : AppColors.brandGradient,
        color: onPressed == null ? AppColors.textHint : null,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.arrow_forward_rounded, size: 18),
        label: Text(label.toUpperCase(), overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.72),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: AppTextStyles.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}

/// Soft circular icon button with an optional numeric badge.
class PremiumIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int badgeCount;

  const PremiumIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Tooltip(
              message: tooltip,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, color: AppColors.textPrimary, size: 22),
              ),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.favourite,
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Rounded search field shell with filter affordance.
class PremiumSearchField extends StatelessWidget {
  final String hintText;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;

  const PremiumSearchField({
    super.key,
    this.hintText = 'Search campus listings',
    this.onFilterTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.7),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.bodyMedium,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
          ),
          suffixIcon: IconButton(
            tooltip: 'Filters',
            onPressed: onFilterTap,
            icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

/// Section title row with an optional trailing action.
class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionTitle,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionLabel!, style: AppTextStyles.actionLink),
          ),
      ],
    );
  }
}

/// Circular category badge for compact marketplace filters.
class CategoryBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const CategoryBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.16)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.metadata.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium empty state with a tinted icon plate and optional action.
class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final Color color;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 26,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 42),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          if (action != null) ...[const SizedBox(height: 22), action!],
        ],
      ),
    );
  }
}
