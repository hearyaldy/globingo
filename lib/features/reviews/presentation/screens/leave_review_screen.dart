import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../../../../core/widgets/skill_radar_chart.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../booking/data/repositories/booking_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../domain/review_eligibility.dart';

class LeaveReviewScreen extends StatefulWidget {
  final String lessonId;

  const LeaveReviewScreen({super.key, required this.lessonId});

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  final BookingRepository _bookingRepository = BookingRepository();
  final ReviewRepository _reviewRepository = ReviewRepository();

  double _clearExplanation = 3.0;
  double _patient = 3.0;
  double _wellPrepared = 3.0;
  double _helpful = 3.0;
  double _fun = 3.0;
  bool _isSubmitting = false;

  SkillRating get _currentRating => SkillRating(
    clearExplanation: _clearExplanation,
    patient: _patient,
    wellPrepared: _wellPrepared,
    helpful: _helpful,
    fun: _fun,
  );

  Future<void> _submitReview(Map<String, dynamic> bookingData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review.')),
      );
      return;
    }

    if (_isSubmitting) return;
    final bookingStatus = (bookingData['status'] as String?) ?? '';
    if (!canSubmitReviewForBookingStatus(bookingStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only review a completed lesson.'),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final hasExistingReview = await _reviewRepository.hasReviewForBooking(
        bookingId: widget.lessonId,
        reviewerId: currentUser.uid,
      );

      if (hasExistingReview) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already reviewed this lesson.')),
        );
        context.go('/my-courses');
        return;
      }

      await _reviewRepository.createReview(
        bookingId: widget.lessonId,
        reviewerId: currentUser.uid,
        reviewerName:
            currentUser.displayName ?? currentUser.email ?? 'Anonymous',
        teacherId: (bookingData['teacherId'] as String?) ?? '',
        teacherName: (bookingData['teacherName'] as String?) ?? 'Teacher',
        clearExplanation: _clearExplanation,
        patient: _patient,
        wellPrepared: _wellPrepared,
        helpful: _helpful,
        fun: _fun,
        overall: _currentRating.average,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review submitted!')));
      context.go('/my-courses');
    } on FirebaseException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit review. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _bookingRepository.watchBooking(widget.lessonId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const AppErrorState(message: 'Failed to load lesson details.');
        }
        if (!snapshot.hasData) {
          return const AppLoadingState();
        }
        if (!snapshot.data!.exists) {
          return const AppEmptyState(message: 'Lesson not found.');
        }

        final bookingData = snapshot.data!.data()!;
        final bookingStatus = (bookingData['status'] as String?) ?? '';
        if (!canSubmitReviewForBookingStatus(bookingStatus)) {
          return const AppEmptyState(
            message: 'Review is available only after lesson completion.',
          );
        }
        final scheduledAt = (bookingData['scheduledAt'] as Timestamp?)
            ?.toDate();
        final dateLabel = scheduledAt == null
            ? 'Unknown date'
            : '${scheduledAt.year}-${scheduledAt.month.toString().padLeft(2, '0')}-${scheduledAt.day.toString().padLeft(2, '0')}';
        final timeLabel = scheduledAt == null
            ? '--:--'
            : '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
        final duration =
            (bookingData['durationMinutes'] as num?)?.toInt() ?? 60;
        final teacherName =
            (bookingData['teacherName'] as String?) ?? 'Teacher';

        return SingleChildScrollView(
          padding: Responsive.screenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Leave a Review', style: AppTypography.h1),
              const SizedBox(height: 32),
              if (isMobile)
                Column(
                  children: [
                    _buildReviewFormCard(
                      teacherName: teacherName,
                      dateLabel: dateLabel,
                      timeLabel: timeLabel,
                      duration: duration,
                    ),
                    const SizedBox(height: 16),
                    _buildPreviewCard(bookingData, true),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildReviewFormCard(
                        teacherName: teacherName,
                        dateLabel: dateLabel,
                        timeLabel: timeLabel,
                        duration: duration,
                      ),
                    ),
                    const SizedBox(width: 32),
                    SizedBox(
                      width: 350,
                      child: _buildPreviewCard(bookingData, false),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewFormCard({
    required String teacherName,
    required String dateLabel,
    required String timeLabel,
    required int duration,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(name: teacherName, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacherName, style: AppTypography.h4),
                    Text(
                      '$dateLabel · $timeLabel · $duration minutes',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Icon(Icons.star_outline, color: AppColors.starFilled),
              const SizedBox(width: 8),
              Text(AppStrings.rateThisLesson, style: AppTypography.h4),
            ],
          ),
          const SizedBox(height: 24),
          _RatingSlider(
            label: AppStrings.clearExplanation,
            value: _clearExplanation,
            onChanged: (v) => setState(() => _clearExplanation = v),
          ),
          _RatingSlider(
            label: AppStrings.patient,
            value: _patient,
            onChanged: (v) => setState(() => _patient = v),
          ),
          _RatingSlider(
            label: AppStrings.wellPrepared,
            value: _wellPrepared,
            onChanged: (v) => setState(() => _wellPrepared = v),
          ),
          _RatingSlider(
            label: AppStrings.helpful,
            value: _helpful,
            onChanged: (v) => setState(() => _helpful = v),
          ),
          _RatingSlider(
            label: AppStrings.fun,
            value: _fun,
            onChanged: (v) => setState(() => _fun = v),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(Map<String, dynamic> bookingData, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(AppStrings.ratingPreview, style: AppTypography.h4),
          const SizedBox(height: 24),
          SkillRadarChart(rating: _currentRating, size: isMobile ? 220 : 250),
          const SizedBox(height: 24),
          Text(AppStrings.overallRating, style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: AppColors.starFilled, size: 28),
              const SizedBox(width: 8),
              Text(
                _currentRating.average.toStringAsFixed(1),
                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () => _submitReview(bookingData),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppStrings.submitReview, style: AppTypography.button),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _RatingSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(value.toStringAsFixed(1), style: AppTypography.labelLarge),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.warning.withValues(alpha: 0.3),
              thumbColor: AppColors.surface,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: value,
              min: 1,
              max: 5,
              divisions: 8,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              5,
              (i) => Text(
                '${i + 1}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
