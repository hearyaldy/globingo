import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/avatar_widget.dart';
import '../../../../../core/widgets/rating_stars.dart';
import '../../../../booking/data/repositories/booking_repository.dart';
import '../../../../teachers/data/models/teacher_model.dart';
import '../../../../teachers/data/repositories/teacher_repository.dart';

class LearningDashboardScreen extends StatelessWidget {
  const LearningDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.screenPadding(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final userName = currentUser?.displayName?.trim().isNotEmpty == true
        ? currentUser!.displayName!.trim()
        : (currentUser?.email ?? 'User');

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
                '${AppStrings.welcomeBack}, $userName! ',
                style: isMobile ? AppTypography.h3 : AppTypography.h1,
              ),
              const Text('👋', style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.readyToLearn,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _UpcomingLessonsSection(userId: currentUser?.uid, isMobile: isMobile),
          const SizedBox(height: 32),
          _RecentTeachersSection(isMobile: isMobile),
        ],
      ),
    );
  }
}

class _UpcomingLessonsSection extends StatelessWidget {
  final String? userId;
  final bool isMobile;

  const _UpcomingLessonsSection({required this.userId, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final teacherRepository = TeacherRepository();
    final bookingRepository = BookingRepository();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppStrings.upcomingLessons,
                      style: isMobile
                          ? AppTypography.labelLarge
                          : AppTypography.h4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/my-courses'),
              child: Text(
                AppStrings.viewAll,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (userId == null)
          Text(
            'Please log in to view upcoming lessons.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: teacherRepository.watchTeachers(),
            builder: (context, teachersSnapshot) {
              if (teachersSnapshot.hasError) {
                return const Text('Failed to load teachers.');
              }
              if (!teachersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
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
                stream: bookingRepository.watchLearnerBookings(userId!),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Failed to load upcoming lessons.');
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final now = DateTime.now();
                  final lessons =
                      snapshot.data!.docs.map((doc) => doc.data()).where((
                        data,
                      ) {
                        final status = (data['status'] as String?) ?? '';
                        if (status != 'pending' && status != 'accepted') {
                          return false;
                        }
                        final teacherKey = _bookingTeacherLookupKey(data);
                        if (teacherKey == null ||
                            !activeTeacherNames.containsKey(teacherKey)) {
                          return false;
                        }
                        final scheduledAt = (data['scheduledAt'] as Timestamp?)
                            ?.toDate();
                        return scheduledAt != null && scheduledAt.isAfter(now);
                      }).toList()..sort((a, b) {
                        final aTime =
                            (a['scheduledAt'] as Timestamp?)?.toDate() ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        final bTime =
                            (b['scheduledAt'] as Timestamp?)?.toDate() ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        return aTime.compareTo(bTime);
                      });

                  final topLessons = lessons.take(2).toList();
                  if (topLessons.isEmpty) {
                    return Text(
                      'No upcoming lessons yet.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  }

                  final cards = topLessons.map((lesson) {
                    final scheduledAt = (lesson['scheduledAt'] as Timestamp?)
                        ?.toDate();
                    final date = scheduledAt == null
                        ? '--'
                        : '${scheduledAt.year}-${scheduledAt.month.toString().padLeft(2, '0')}-${scheduledAt.day.toString().padLeft(2, '0')}';
                    final time = scheduledAt == null
                        ? '--:--'
                        : '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
                    final teacherLookupKey = _bookingTeacherLookupKey(lesson);
                    return _UpcomingLessonCard(
                      teacherName:
                          (teacherLookupKey == null
                              ? null
                              : activeTeacherNames[teacherLookupKey]) ??
                          (lesson['teacherName'] as String?) ??
                          'Teacher',
                      language: (lesson['language'] as String?) ?? 'Language',
                      languageColor: AppColors.primary,
                      date: date,
                      time: time,
                    );
                  }).toList();

                  if (isMobile) {
                    return Column(
                      children: [
                        cards[0],
                        if (cards.length > 1) ...[
                          const SizedBox(height: 16),
                          cards[1],
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: cards[0]),
                      if (cards.length > 1) ...[
                        const SizedBox(width: 24),
                        Expanded(child: cards[1]),
                      ],
                    ],
                  );
                },
              );
            },
          ),
      ],
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
}

class _RecentTeachersSection extends StatelessWidget {
  final bool isMobile;

  const _RecentTeachersSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final teacherRepository = TeacherRepository();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.recentTeachers,
          style: isMobile ? AppTypography.labelLarge : AppTypography.h4,
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: teacherRepository.watchTeachers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Failed to load teachers.');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final teachers = snapshot.data!.docs
                .where((doc) {
                  final uid = (doc.data()['uid'] as String?)?.trim() ?? '';
                  final isActive =
                      doc.data()['isActive'] == true ||
                      doc.data()['active'] == true;
                  return uid.isNotEmpty && isActive;
                })
                .map((doc) => Teacher.fromFirestore(doc.id, doc.data()))
                .take(3)
                .toList();
            if (teachers.isEmpty) {
              return Text(
                'No teachers available yet.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              );
            }

            if (isMobile) {
              return Column(
                children: [
                  for (int i = 0; i < teachers.length; i++) ...[
                    _RecentTeacherCard(
                      teacher: teachers[i],
                      onTap: () => context.go('/teacher/${teachers[i].id}'),
                      isMobile: true,
                    ),
                    if (i < teachers.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (int i = 0; i < teachers.length; i++) ...[
                  Expanded(
                    child: _RecentTeacherCard(
                      teacher: teachers[i],
                      onTap: () => context.go('/teacher/${teachers[i].id}'),
                    ),
                  ),
                  if (i < teachers.length - 1) const SizedBox(width: 24),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UpcomingLessonCard extends StatelessWidget {
  final String teacherName;
  final String language;
  final Color languageColor;
  final String date;
  final String time;

  const _UpcomingLessonCard({
    required this.teacherName,
    required this.language,
    required this.languageColor,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              AvatarWidget(name: teacherName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacherName,
                      style: AppTypography.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: languageColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        language,
                        style: AppTypography.labelMedium.copyWith(
                          color: languageColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(date, style: AppTypography.bodySmall),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(time, style: AppTypography.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: Text(AppStrings.enterLesson, style: AppTypography.button),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTeacherCard extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onTap;
  final bool isMobile;

  const _RecentTeacherCard({
    required this.teacher,
    required this.onTap,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          AvatarWidget(name: teacher.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.name,
                  style: AppTypography.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                RatingStars(rating: teacher.rating),
              ],
            ),
          ),
          if (isMobile)
            IconButton(
              onPressed: onTap,
              icon: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            )
          else
            OutlinedButton(
              onPressed: onTap,
              child: Text(
                AppStrings.viewDetails,
                style: AppTypography.labelMedium,
              ),
            ),
        ],
      ),
    );
  }
}
