import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../booking/data/repositories/booking_repository.dart';
import '../../../reviews/data/repositories/review_repository.dart';
import '../../../teachers/data/repositories/teacher_repository.dart';

enum LessonStatus { upcoming, completed, cancelled }

class Lesson {
  final String id;
  final String teacherName;
  final String language;
  final DateTime date;
  final String time;
  final int duration;
  final double price;
  final LessonStatus status;
  final String bookingStatus;
  final bool hasReview;

  const Lesson({
    required this.id,
    required this.teacherName,
    required this.language,
    required this.date,
    required this.time,
    required this.duration,
    required this.price,
    required this.status,
    required this.bookingStatus,
    this.hasReview = false,
  });
}

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen>
    with SingleTickerProviderStateMixin {
  final BookingRepository _bookingRepository = BookingRepository();
  final TeacherRepository _teacherRepository = TeacherRepository();
  final ReviewRepository _reviewRepository = ReviewRepository();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMobile = Responsive.isMobile(context);

    if (currentUser == null) {
      return const AppEmptyState(
        message: 'Please log in to view your courses.',
      );
    }

    return SingleChildScrollView(
      padding: Responsive.screenPadding(context),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _bookingRepository.watchLearnerBookings(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Failed to load lessons: ${snapshot.error}',
            );
          }
          if (!snapshot.hasData) {
            return const AppLoadingState();
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _teacherRepository.watchTeachers(),
            builder: (context, teachersSnapshot) {
              if (teachersSnapshot.hasError) {
                return const AppErrorState(
                  message: 'Failed to load teacher data.',
                );
              }
              if (!teachersSnapshot.hasData) {
                return const AppLoadingState();
              }

              final activeTeacherNames = <String, String>{};
              for (final teacherDoc in teachersSnapshot.data!.docs) {
                final data = teacherDoc.data();
                final uid = (data['uid'] as String?)?.trim() ?? '';
                final isActive =
                    data['isActive'] == true || data['active'] == true;
                if (uid.isEmpty || !isActive) continue;
                final name = (data['name'] as String?)?.trim();
                if (name != null && name.isNotEmpty) {
                  activeTeacherNames[teacherDoc.id] = name;
                  activeTeacherNames[uid] = name;
                }
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _reviewRepository.watchReviewsByReviewer(
                  currentUser.uid,
                ),
                builder: (context, reviewsSnapshot) {
                  if (reviewsSnapshot.hasError) {
                    return const AppErrorState(
                      message: 'Failed to load review status.',
                    );
                  }
                  if (!reviewsSnapshot.hasData) {
                    return const AppLoadingState();
                  }

                  final reviewedBookingIds = reviewsSnapshot.data!.docs
                      .map((doc) => doc.data()['bookingId'])
                      .whereType<String>()
                      .toSet();

                  final lessons = snapshot.data!.docs
                      .where((doc) {
                        final teacherKey = _bookingTeacherLookupKey(doc.data());
                        return teacherKey != null &&
                            activeTeacherNames.containsKey(teacherKey);
                      })
                      .map(
                        (doc) => _mapBookingToLesson(
                          doc,
                          reviewedBookingIds,
                          teacherNameOverride:
                              activeTeacherNames[_bookingTeacherLookupKey(
                                doc.data(),
                              )],
                        ),
                      )
                      .toList();
                  lessons.sort((a, b) => b.date.compareTo(a.date));
                  final upcomingLessons = lessons
                      .where((l) => l.status == LessonStatus.upcoming)
                      .toList();
                  final completedLessons = lessons
                      .where((l) => l.status == LessonStatus.completed)
                      .toList();
                  final cancelledLessons = lessons
                      .where((l) => l.status == LessonStatus.cancelled)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.myCourses, style: AppTypography.h1),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: isMobile,
                          indicator: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary),
                          ),
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          dividerColor: Colors.transparent,
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(AppStrings.upcoming),
                                  const SizedBox(width: 8),
                                  _CountBadge(count: upcomingLessons.length),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(AppStrings.completed),
                                  const SizedBox(width: 8),
                                  _CountBadge(count: completedLessons.length),
                                ],
                              ),
                            ),
                            Tab(text: AppStrings.cancelled),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isMobile)
                        _buildActiveTabContent(
                          upcomingLessons,
                          completedLessons,
                          cancelledLessons,
                          true,
                        )
                      else
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildLessonGrid(upcomingLessons, false),
                              _buildLessonGrid(completedLessons, false),
                              _buildLessonGrid(cancelledLessons, false),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String? _bookingTeacherLookupKey(Map<String, dynamic> bookingData) {
    final teacherDocId = (bookingData['teacherDocId'] as String?)?.trim();
    if (teacherDocId != null && teacherDocId.isNotEmpty) {
      return teacherDocId;
    }
    final teacherId = (bookingData['teacherId'] as String?)?.trim();
    if (teacherId != null && teacherId.isNotEmpty) {
      return teacherId;
    }
    return null;
  }

  Lesson _mapBookingToLesson(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Set<String> reviewedBookingIds, {
    String? teacherNameOverride,
  }) {
    final data = doc.data();
    final scheduledAt =
        (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final status = _statusFromBooking(data['status'] as String?);
    final bookingStatus = (data['status'] as String?) ?? 'pending';
    final hour = scheduledAt.hour.toString().padLeft(2, '0');
    final minute = scheduledAt.minute.toString().padLeft(2, '0');

    return Lesson(
      id: doc.id,
      teacherName:
          teacherNameOverride ?? (data['teacherName'] as String?) ?? 'Teacher',
      language: (data['language'] as String?) ?? 'Language',
      date: scheduledAt,
      time: '$hour:$minute',
      duration: (data['durationMinutes'] as num?)?.toInt() ?? 60,
      price:
          (data['lessonFee'] as num?)?.toDouble() ??
          (data['totalAmount'] as num?)?.toDouble() ??
          0,
      status: status,
      bookingStatus: bookingStatus,
      hasReview: reviewedBookingIds.contains(doc.id),
    );
  }

  LessonStatus _statusFromBooking(String? status) {
    switch (status) {
      case 'completed':
        return LessonStatus.completed;
      case 'cancelled':
      case 'rejected':
        return LessonStatus.cancelled;
      case 'in_progress':
      case 'accepted':
      case 'pending':
        return LessonStatus.upcoming;
      default:
        return LessonStatus.upcoming;
    }
  }

  Widget _buildActiveTabContent(
    List<Lesson> upcomingLessons,
    List<Lesson> completedLessons,
    List<Lesson> cancelledLessons,
    bool isMobile,
  ) {
    switch (_tabController.index) {
      case 0:
        return _buildLessonGrid(upcomingLessons, isMobile);
      case 1:
        return _buildLessonGrid(completedLessons, isMobile);
      case 2:
      default:
        return _buildLessonGrid(cancelledLessons, isMobile);
    }
  }

  Widget _buildLessonGrid(List<Lesson> lessons, bool isMobile) {
    if (lessons.isEmpty) {
      return const AppEmptyState(message: 'No lessons found.');
    }

    final cards = lessons
        .map(
          (lesson) => _LessonCard(
            lesson: lesson,
            isMobile: isMobile,
            onEnter: () => _handleEnterLesson(lesson),
            onReview:
                lesson.status == LessonStatus.completed && !lesson.hasReview
                ? () => context.go('/review/${lesson.id}')
                : null,
          ),
        )
        .toList();

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Wrap(spacing: 24, runSpacing: 24, children: cards);
  }

  void _handleEnterLesson(Lesson lesson) {
    final now = DateTime.now();
    final windowOpen = lesson.date.subtract(const Duration(minutes: 15));
    final windowClose = lesson.date.add(
      Duration(minutes: lesson.duration + 30),
    );
    final statusAllowed =
        lesson.bookingStatus == 'accepted' ||
        lesson.bookingStatus == 'in_progress';
    final inTimeWindow = now.isAfter(windowOpen) && now.isBefore(windowClose);

    if (!statusAllowed || !inTimeWindow) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lesson can be entered only when accepted and within 15 minutes before start until 30 minutes after end.',
          ),
        ),
      );
      return;
    }
    context.go('/lesson/${lesson.id}');
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: AppTypography.labelMedium.copyWith(color: Colors.white),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isMobile;
  final VoidCallback? onEnter;
  final VoidCallback? onReview;

  const _LessonCard({
    required this.lesson,
    required this.isMobile,
    this.onEnter,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = lesson.status == LessonStatus.completed;

    return Container(
      width: isMobile ? double.infinity : 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.teacherCardGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                AvatarWidget(name: lesson.teacherName, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.teacherName,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          lesson.language,
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Text(
                    'Completed',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),

          // Body
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${lesson.date.year}-${lesson.date.month.toString().padLeft(2, '0')}-${lesson.date.day.toString().padLeft(2, '0')}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(lesson.time, style: AppTypography.bodySmall),
                      ],
                    ),
                    Text(
                      '${lesson.duration} min',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${lesson.price.round()}',
                      style: AppTypography.labelLarge,
                    ),
                    if (isCompleted && !lesson.hasReview && onReview != null)
                      ElevatedButton.icon(
                        onPressed: onReview,
                        icon: const Icon(Icons.star_outline, size: 16),
                        label: Text(
                          AppStrings.leaveReview,
                          style: AppTypography.button,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      )
                    else if (isCompleted && lesson.hasReview)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.starFilled.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.starFilled,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.reviewed,
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.starFilled,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!isCompleted)
                      ElevatedButton(
                        onPressed: onEnter,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          AppStrings.enterLesson,
                          style: AppTypography.button,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
