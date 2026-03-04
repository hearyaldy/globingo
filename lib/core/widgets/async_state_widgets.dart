import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AppLoadingState extends StatelessWidget {
  final String? message;
  final bool centered;

  const AppLoadingState({super.key, this.message, this.centered = true});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
    return centered ? Center(child: content) : content;
  }
}

class AppErrorState extends StatelessWidget {
  final String message;
  final bool centered;

  const AppErrorState({super.key, required this.message, this.centered = true});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
    return centered ? Center(child: content) : content;
  }
}

class AppEmptyState extends StatelessWidget {
  final String message;
  final bool centered;

  const AppEmptyState({super.key, required this.message, this.centered = true});

  @override
  Widget build(BuildContext context) {
    final content = Text(
      message,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
      textAlign: TextAlign.center,
    );
    return centered ? Center(child: content) : content;
  }
}
