import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/async_state_widgets.dart';
import '../../../../../core/widgets/skill_radar_chart.dart';
import '../../../../../core/widgets/avatar_widget.dart';
import '../../../../booking/domain/booking_status_transition.dart';

class TeachingDashboardScreen extends StatelessWidget {
  const TeachingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.screenPadding(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const AppEmptyState(
        message: 'Please log in to view teaching dashboard.',
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return const AppErrorState(message: 'Failed to load user profile.');
        }
        if (!userSnapshot.hasData) {
          return const AppLoadingState();
        }

        final userData = userSnapshot.data!.data() ?? const {};
        final canTeach = (userData['teachingModeEnabled'] as bool?) ?? false;
        if (!canTeach) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Teaching access required', style: AppTypography.h4),
                  const SizedBox(height: 8),
                  Text(
                    'Complete teacher setup to access this dashboard.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/onboarding?role=teacher'),
                    child: Text(
                      'Set Up Teacher Profile',
                      style: AppTypography.button,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('teacherId', isEqualTo: currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const AppErrorState(
                message: 'Failed to load teaching dashboard.',
              );
            }
            if (!snapshot.hasData) {
              return const AppLoadingState();
            }

            final allBookings = snapshot.data!.docs;
            final pendingBookings =
                allBookings
                    .where(
                      (doc) => (doc.data()['status'] as String?) == 'pending',
                    )
                    .map(_mapPendingBooking)
                    .toList()
                  ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
            final pendingCount = pendingBookings.length;
            final totalStudents = _calculateTotalStudents(allBookings);
            final monthlyIncome = _calculateMonthlyIncome(allBookings);

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('teacherId', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, reviewsSnapshot) {
                if (reviewsSnapshot.hasError) {
                  return const AppErrorState(
                    message: 'Failed to load review metrics.',
                  );
                }
                if (!reviewsSnapshot.hasData) {
                  return const AppLoadingState();
                }

                final reviewMetrics = _aggregateReviewMetrics(
                  reviewsSnapshot.data!.docs,
                );

                return SingleChildScrollView(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${AppStrings.welcomeBack}, ${currentUser.displayName?.trim().isNotEmpty == true ? currentUser.displayName!.trim() : (currentUser.email ?? 'User')}! ',
                            style: isMobile
                                ? AppTypography.h3
                                : AppTypography.h1,
                          ),
                          const Text('👋', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.checkProgress,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/teacher-offers'),
                        icon: const Icon(
                          Icons.library_books_outlined,
                          size: 16,
                        ),
                        label: Text(
                          'Manage Lesson Offers',
                          style: AppTypography.labelMedium,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats Cards - Responsive Grid
                      if (isMobile)
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    title: AppStrings.monthlyIncome,
                                    value:
                                        '\$${monthlyIncome.toStringAsFixed(0)}',
                                    icon: Icons.attach_money,
                                    iconColor: AppColors.warning,
                                    compact: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    title: AppStrings.pendingBookings,
                                    value: pendingCount.toString(),
                                    icon: Icons.menu_book_outlined,
                                    iconColor: AppColors.secondary,
                                    compact: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    title: AppStrings.totalStudents,
                                    value: totalStudents.toString(),
                                    icon: Icons.people_outline,
                                    iconColor: AppColors.primary,
                                    compact: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    title: AppStrings.averageRating,
                                    value: reviewMetrics.averageRating
                                        .toStringAsFixed(1),
                                    icon: Icons.star_outline,
                                    iconColor: AppColors.starFilled,
                                    compact: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: AppStrings.monthlyIncome,
                                value: '\$${monthlyIncome.toStringAsFixed(0)}',
                                icon: Icons.attach_money,
                                iconColor: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _StatCard(
                                title: AppStrings.pendingBookings,
                                value: pendingCount.toString(),
                                icon: Icons.menu_book_outlined,
                                iconColor: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _StatCard(
                                title: AppStrings.totalStudents,
                                value: totalStudents.toString(),
                                icon: Icons.people_outline,
                                iconColor: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _StatCard(
                                title: AppStrings.averageRating,
                                value: reviewMetrics.averageRating
                                    .toStringAsFixed(1),
                                icon: Icons.star_outline,
                                iconColor: AppColors.starFilled,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),

                      // Skill Radar and Pending Bookings - Responsive
                      if (isMobile)
                        Column(
                          children: [
                            // Skill Radar
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.borderLight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppStrings.mySkillRadar,
                                        style: AppTypography.labelLarge,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: SkillRadarChart(
                                      rating: reviewMetrics.skillRating,
                                      size: 220,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Pending Bookings
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.borderLight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppStrings.pendingBookings,
                                        style: AppTypography.labelLarge,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _PendingBookingsList(
                                    bookings: pendingBookings,
                                    isMobile: true,
                                    onUpdateStatus: (bookingId, status) =>
                                        _updateBookingStatus(
                                          context,
                                          bookingId,
                                          status,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Skill Radar
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.trending_up,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppStrings.mySkillRadar,
                                          style: AppTypography.h4,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Center(
                                      child: SkillRadarChart(
                                        rating: reviewMetrics.skillRating,
                                        size: 280,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Pending Bookings
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppStrings.pendingBookings,
                                          style: AppTypography.h4,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _PendingBookingsList(
                                      bookings: pendingBookings,
                                      onUpdateStatus: (bookingId, status) =>
                                          _updateBookingStatus(
                                            context,
                                            bookingId,
                                            status,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  _PendingBooking _mapPendingBooking(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final scheduledAt =
        (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return _PendingBooking(
      id: doc.id,
      learnerName: (data['learnerName'] as String?) ?? 'Learner',
      scheduledAt: scheduledAt,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 60,
    );
  }

  int _calculateTotalStudents(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> bookingDocs,
  ) {
    final learnerIds = bookingDocs
        .map((doc) => doc.data()['learnerId'])
        .whereType<String>()
        .toSet();
    return learnerIds.length;
  }

  double _calculateMonthlyIncome(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> bookingDocs,
  ) {
    final now = DateTime.now();
    double total = 0;
    for (final doc in bookingDocs) {
      final data = doc.data();
      final status = (data['status'] as String?) ?? '';
      if (status != 'accepted' && status != 'completed') {
        continue;
      }
      final scheduledAt = (data['scheduledAt'] as Timestamp?)?.toDate();
      if (scheduledAt == null ||
          scheduledAt.year != now.year ||
          scheduledAt.month != now.month) {
        continue;
      }
      total +=
          (data['lessonFee'] as num?)?.toDouble() ??
          (data['totalAmount'] as num?)?.toDouble() ??
          0;
    }
    return total;
  }

  Future<void> _updateBookingStatus(
    BuildContext context,
    String bookingId,
    String status,
  ) async {
    if (!isValidTeacherDecisionStatus(status)) return;
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update booking status.')),
      );
    }
  }

  _ReviewMetrics _aggregateReviewMetrics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> reviewDocs,
  ) {
    if (reviewDocs.isEmpty) {
      return const _ReviewMetrics(
        averageRating: 0,
        skillRating: SkillRating(
          clearExplanation: 0,
          patient: 0,
          wellPrepared: 0,
          helpful: 0,
          fun: 0,
        ),
      );
    }

    double totalOverall = 0;
    double totalClearExplanation = 0;
    double totalPatient = 0;
    double totalWellPrepared = 0;
    double totalHelpful = 0;
    double totalFun = 0;

    for (final reviewDoc in reviewDocs) {
      final data = reviewDoc.data();
      totalOverall += (data['overall'] as num?)?.toDouble() ?? 0;
      totalClearExplanation +=
          (data['clearExplanation'] as num?)?.toDouble() ?? 0;
      totalPatient += (data['patient'] as num?)?.toDouble() ?? 0;
      totalWellPrepared += (data['wellPrepared'] as num?)?.toDouble() ?? 0;
      totalHelpful += (data['helpful'] as num?)?.toDouble() ?? 0;
      totalFun += (data['fun'] as num?)?.toDouble() ?? 0;
    }

    final count = reviewDocs.length;
    return _ReviewMetrics(
      averageRating: totalOverall / count,
      skillRating: SkillRating(
        clearExplanation: totalClearExplanation / count,
        patient: totalPatient / count,
        wellPrepared: totalWellPrepared / count,
        helpful: totalHelpful / count,
        fun: totalFun / count,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool compact;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppTypography.h3.copyWith(color: AppColors.primary),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(value, style: AppTypography.stat),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
              ],
            ),
    );
  }
}

class _PendingBookingItem extends StatelessWidget {
  final _PendingBooking booking;
  final Future<void> Function(String status) onUpdateStatus;
  final bool isMobile;

  const _PendingBookingItem({
    required this.booking,
    required this.onUpdateStatus,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AvatarWidget(name: booking.learnerName, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.learnerName,
                            style: AppTypography.labelLarge,
                          ),
                          Text(
                            booking.displayText,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onUpdateStatus('rejected'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          AppStrings.reject,
                          style: AppTypography.labelMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onUpdateStatus('accepted'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          AppStrings.accept,
                          style: AppTypography.button,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                AvatarWidget(name: booking.learnerName, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.learnerName,
                        style: AppTypography.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(booking.displayText, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => onUpdateStatus('rejected'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    AppStrings.reject,
                    style: AppTypography.labelMedium,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => onUpdateStatus('accepted'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(AppStrings.accept, style: AppTypography.button),
                ),
              ],
            ),
    );
  }
}

class _PendingBookingsList extends StatelessWidget {
  final List<_PendingBooking> bookings;
  final bool isMobile;
  final Future<void> Function(String bookingId, String status) onUpdateStatus;

  const _PendingBookingsList({
    required this.bookings,
    required this.onUpdateStatus,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Text(
        'No pending bookings right now.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    return Column(
      children: bookings
          .map(
            (booking) => _PendingBookingItem(
              booking: booking,
              isMobile: isMobile,
              onUpdateStatus: (status) => onUpdateStatus(booking.id, status),
            ),
          )
          .toList(),
    );
  }
}

class _PendingBooking {
  final String id;
  final String learnerName;
  final DateTime scheduledAt;
  final int durationMinutes;

  const _PendingBooking({
    required this.id,
    required this.learnerName,
    required this.scheduledAt,
    required this.durationMinutes,
  });

  String get displayText {
    final date =
        '${scheduledAt.year}-${scheduledAt.month.toString().padLeft(2, '0')}-${scheduledAt.day.toString().padLeft(2, '0')}';
    final time =
        '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    return '$date · $time · $durationMinutes min';
  }
}

class _ReviewMetrics {
  final double averageRating;
  final SkillRating skillRating;

  const _ReviewMetrics({
    required this.averageRating,
    required this.skillRating,
  });
}
