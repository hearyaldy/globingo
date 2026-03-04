import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final bool showValue;
  final int? reviewCount;

  const RatingStars({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 16,
    this.showValue = true,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          color: AppColors.starFilled,
          size: size,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (reviewCount != null) ...[
          Text(
            ' ($reviewCount)',
            style: AppTypography.bodySmall,
          ),
        ],
      ],
    );
  }
}

class RatingStarsRow extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;

  const RatingStarsRow({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starValue = index + 1;
        if (rating >= starValue) {
          return Icon(Icons.star_rounded, color: AppColors.starFilled, size: size);
        } else if (rating >= starValue - 0.5) {
          return Icon(Icons.star_half_rounded, color: AppColors.starFilled, size: size);
        } else {
          return Icon(Icons.star_outline_rounded, color: AppColors.starEmpty, size: size);
        }
      }),
    );
  }
}
