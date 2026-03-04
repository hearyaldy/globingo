import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/language_chip.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/skill_radar_chart.dart';
import '../../data/models/teacher_model.dart';

class TeacherProfileScreen extends StatelessWidget {
  final String teacherId;

  const TeacherProfileScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolveTeacherDocId(),
      builder: (context, resolveSnapshot) {
        if (resolveSnapshot.hasError) {
          return const AppErrorState(
            message: 'Failed to resolve teacher profile.',
          );
        }
        if (!resolveSnapshot.hasData) {
          return const AppLoadingState();
        }
        final resolvedTeacherDocId = resolveSnapshot.data;
        if (resolvedTeacherDocId == null) {
          return const AppEmptyState(message: 'Teacher not found.');
        }

        return _buildProfileByDocId(context, resolvedTeacherDocId);
      },
    );
  }

  Widget _buildProfileByDocId(
    BuildContext context,
    String resolvedTeacherDocId,
  ) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('teachers')
          .doc(resolvedTeacherDocId)
          .snapshots(),
      builder: (context, teacherSnapshot) {
        if (teacherSnapshot.hasError) {
          return const AppErrorState(
            message: 'Failed to load teacher profile.',
          );
        }
        if (!teacherSnapshot.hasData) {
          return const AppLoadingState();
        }
        if (!teacherSnapshot.data!.exists) {
          return const AppEmptyState(message: 'Teacher not found.');
        }

        final teacher = Teacher.fromFirestore(
          teacherSnapshot.data!.id,
          teacherSnapshot.data!.data() ?? const {},
        );

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('teacherId', isEqualTo: teacher.id)
              .snapshots(),
          builder: (context, reviewSnapshot) {
            if (reviewSnapshot.hasError) {
              return const AppErrorState(
                message: 'Failed to load teacher reviews.',
              );
            }
            if (!reviewSnapshot.hasData) {
              return const AppLoadingState();
            }

            final firestoreReviews =
                reviewSnapshot.data!.docs.map(_mapFirestoreReview).toList()
                  ..sort((a, b) => b.date.compareTo(a.date));
            final reviewCount = firestoreReviews.length;
            final averageRating = reviewCount == 0
                ? teacher.rating
                : firestoreReviews
                          .map((review) => review.rating)
                          .reduce((a, b) => a + b) /
                      reviewCount;
            final aggregatedSkillRating = reviewCount == 0
                ? teacher.skillRating
                : _aggregateSkillRating(firestoreReviews);
            final isMobile = Responsive.isMobile(context);

            return SingleChildScrollView(
              padding: Responsive.screenPadding(context),
              child: Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            gradient: AppColors.teacherCardGradient,
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              AvatarWidget(
                                name: teacher.name,
                                size: isMobile ? 72 : 100,
                              ),
                              SizedBox(width: isMobile ? 16 : 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teacher.name,
                                      style: AppTypography.h2.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        RatingStars(
                                          rating: averageRating,
                                          reviewCount: reviewCount,
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${teacher.lessonCount} lessons',
                                          style: AppTypography.bodyMedium
                                              .copyWith(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.people_outline,
                                          size: 16,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${teacher.studentCount} students',
                                          style: AppTypography.bodyMedium
                                              .copyWith(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${teacher.hourlyRate.round()}',
                                    style:
                                        (isMobile
                                                ? AppTypography.h2
                                                : AppTypography.h1)
                                            .copyWith(color: Colors.white),
                                  ),
                                  Text(
                                    '/hour',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 24,
                          runSpacing: 16,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.teaches,
                                  style: AppTypography.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: teacher.teachingLanguages
                                      .map(
                                        (lang) => LanguageChip(
                                          language: lang,
                                          isPrimary: true,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.speaks,
                                  style: AppTypography.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: teacher.speakingLanguages
                                      .map(
                                        (lang) => LanguageChip(language: lang),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppStrings.aboutMe, style: AppTypography.h4),
                              const SizedBox(height: 12),
                              Text(
                                teacher.bio,
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _LessonOffersSection(teacherUid: teacher.uid),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.skillRadar,
                                style: AppTypography.h4,
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: SkillRadarChart(
                                  rating: aggregatedSkillRating,
                                  size: 300,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
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
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 20,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${AppStrings.studentReviews} ($reviewCount)',
                                    style: AppTypography.h4,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (firestoreReviews.isEmpty)
                                Text(
                                  'No reviews yet.',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              else
                                ...firestoreReviews.map(
                                  (review) => _ReviewItem(review: review),
                                ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              gradient: AppColors.teacherCardGradient,
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                AvatarWidget(name: teacher.name, size: 100),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        teacher.name,
                                        style: AppTypography.h2.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          RatingStars(
                                            rating: averageRating,
                                            reviewCount: reviewCount,
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.white70,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${teacher.lessonCount} lessons',
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                  color: Colors.white70,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.people_outline,
                                            size: 16,
                                            color: Colors.white70,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${teacher.studentCount} students',
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                  color: Colors.white70,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${teacher.hourlyRate.round()}',
                                      style: AppTypography.h1.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '/hour',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.teaches,
                                    style: AppTypography.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: teacher.teachingLanguages
                                        .map(
                                          (lang) => LanguageChip(
                                            language: lang,
                                            isPrimary: true,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 32),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.speaks,
                                    style: AppTypography.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: teacher.speakingLanguages
                                        .map(
                                          (lang) =>
                                              LanguageChip(language: lang),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.aboutMe,
                                  style: AppTypography.h4,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  teacher.bio,
                                  style: AppTypography.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _LessonOffersSection(teacherUid: teacher.uid),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.skillRadar,
                                  style: AppTypography.h4,
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: SkillRadarChart(
                                    rating: aggregatedSkillRating,
                                    size: 300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
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
                                    const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${AppStrings.studentReviews} ($reviewCount)',
                                      style: AppTypography.h4,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (firestoreReviews.isEmpty)
                                  Text(
                                    'No reviews yet.',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                else
                                  ...firestoreReviews.map(
                                    (review) => _ReviewItem(review: review),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(width: isMobile ? 0 : 32, height: isMobile ? 24 : 0),
                  SizedBox(
                    width: isMobile ? double.infinity : 320,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.bookALesson, style: AppTypography.h4),
                          const SizedBox(height: 24),
                          Text(
                            AppStrings.lessonPricing,
                            style: AppTypography.labelLarge,
                          ),
                          const SizedBox(height: 12),
                          _PriceOption(
                            duration: '30 ${AppStrings.minutes}',
                            price: '\$${teacher.price30Min}',
                            isSelected: false,
                          ),
                          _PriceOption(
                            duration: '60 ${AppStrings.minutes}',
                            price: '\$${teacher.price60Min}',
                            isSelected: true,
                          ),
                          _PriceOption(
                            duration: '90 ${AppStrings.minutes}',
                            price: '\$${teacher.price90Min}',
                            isSelected: false,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.availability,
                                style: AppTypography.labelLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (isMobile)
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children:
                                  [
                                        'Mon',
                                        'Tue',
                                        'Wed',
                                        'Thu',
                                        'Fri',
                                        'Sat',
                                        'Sun',
                                      ]
                                      .map(
                                        (day) => _DayIndicator(
                                          day: day,
                                          isAvailable: teacher.availableDays
                                              .contains(day),
                                        ),
                                      )
                                      .toList(),
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children:
                                  [
                                        'Mon',
                                        'Tue',
                                        'Wed',
                                        'Thu',
                                        'Fri',
                                        'Sat',
                                        'Sun',
                                      ]
                                      .map(
                                        (day) => _DayIndicator(
                                          day: day,
                                          isAvailable: teacher.availableDays
                                              .contains(day),
                                        ),
                                      )
                                      .toList(),
                            ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  context.go('/booking/${teacher.id}'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                AppStrings.bookALesson,
                                style: AppTypography.button,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _resolveTeacherDocId() async {
    final teachers = FirebaseFirestore.instance.collection('teachers');
    final doc = await teachers.doc(teacherId).get();
    if (doc.exists) return doc.id;

    final byUid = await teachers
        .where('uid', isEqualTo: teacherId)
        .limit(1)
        .get();
    if (byUid.docs.isNotEmpty) {
      return byUid.docs.first.id;
    }
    return null;
  }

  _FirestoreReview _mapFirestoreReview(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _FirestoreReview(
      reviewerName: (data['reviewerName'] as String?) ?? 'Anonymous',
      rating: (data['overall'] as num?)?.toDouble() ?? 0,
      comment: data['comment'] as String?,
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      clearExplanation: (data['clearExplanation'] as num?)?.toDouble() ?? 0,
      patient: (data['patient'] as num?)?.toDouble() ?? 0,
      wellPrepared: (data['wellPrepared'] as num?)?.toDouble() ?? 0,
      helpful: (data['helpful'] as num?)?.toDouble() ?? 0,
      fun: (data['fun'] as num?)?.toDouble() ?? 0,
    );
  }

  SkillRating _aggregateSkillRating(List<_FirestoreReview> reviews) {
    final count = reviews.length;
    if (count == 0) {
      return const SkillRating(
        clearExplanation: 0,
        patient: 0,
        wellPrepared: 0,
        helpful: 0,
        fun: 0,
      );
    }

    double sumClearExplanation = 0;
    double sumPatient = 0;
    double sumWellPrepared = 0;
    double sumHelpful = 0;
    double sumFun = 0;

    for (final review in reviews) {
      sumClearExplanation += review.clearExplanation;
      sumPatient += review.patient;
      sumWellPrepared += review.wellPrepared;
      sumHelpful += review.helpful;
      sumFun += review.fun;
    }

    return SkillRating(
      clearExplanation: sumClearExplanation / count,
      patient: sumPatient / count,
      wellPrepared: sumWellPrepared / count,
      helpful: sumHelpful / count,
      fun: sumFun / count,
    );
  }
}

class _LessonOffersSection extends StatelessWidget {
  final String teacherUid;

  const _LessonOffersSection({required this.teacherUid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('lesson_offers')
            .where('teacherId', isEqualTo: teacherUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const AppErrorState(
              message: 'Failed to load lesson offers.',
              centered: false,
            );
          }
          if (!snapshot.hasData) {
            return const AppLoadingState(centered: false);
          }

          final offers = snapshot.data!.docs
              .map((doc) => doc.data())
              .where((data) => data['isActive'] != false)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Lessons', style: AppTypography.h4),
              const SizedBox(height: 12),
              if (offers.isEmpty)
                Text(
                  'No lesson offers available yet.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...offers.map(
                  (data) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (data['title'] as String?) ?? 'Lesson',
                                style: AppTypography.labelLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(data['language'] as String?) ?? 'Language'} • ${(data['level'] as String?) ?? 'All levels'} • ${((data['durationMin'] as num?)?.toInt() ?? 60)} min',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '\$${((data['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                          style: AppTypography.h4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PriceOption extends StatelessWidget {
  final String duration;
  final String price;
  final bool isSelected;

  const _PriceOption({
    required this.duration,
    required this.price,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(duration, style: AppTypography.bodyMedium),
          Text(
            price,
            style: AppTypography.labelLarge.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayIndicator extends StatelessWidget {
  final String day;
  final bool isAvailable;

  const _DayIndicator({required this.day, required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(day, style: AppTypography.bodySmall),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 4,
          decoration: BoxDecoration(
            color: isAvailable ? AppColors.primary : AppColors.borderLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final _FirestoreReview review;

  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.borderLight,
                child: Text(
                  '?',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName, style: AppTypography.labelMedium),
                    Text(
                      '${review.date.year}-${review.date.month.toString().padLeft(2, '0')}-${review.date.day.toString().padLeft(2, '0')}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              RatingStars(rating: review.rating),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 12),
            Text(review.comment!, style: AppTypography.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _FirestoreReview {
  final String reviewerName;
  final double rating;
  final String? comment;
  final DateTime date;
  final double clearExplanation;
  final double patient;
  final double wellPrepared;
  final double helpful;
  final double fun;

  const _FirestoreReview({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.date,
    required this.clearExplanation,
    required this.patient,
    required this.wellPrepared,
    required this.helpful,
    required this.fun,
  });
}
