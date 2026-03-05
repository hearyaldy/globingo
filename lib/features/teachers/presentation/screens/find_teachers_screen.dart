import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../../../../core/widgets/skill_radar_chart.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../data/models/teacher_model.dart';
import '../../data/repositories/teacher_repository.dart';

class FindTeachersScreen extends StatefulWidget {
  const FindTeachersScreen({super.key});

  @override
  State<FindTeachersScreen> createState() => _FindTeachersScreenState();
}

class _FindTeachersScreenState extends State<FindTeachersScreen> {
  final TeacherRepository _teacherRepository = TeacherRepository();

  String _selectedLanguage = 'All Languages';
  RangeValues _priceRange = const RangeValues(0, 50);
  double _minRating = 0;
  final TextEditingController _searchController = TextEditingController();

  List<Teacher> filteredTeachers(List<Teacher> teachers) {
    final query = _searchController.text.trim().toLowerCase();
    return teachers.where((teacher) {
      if (query.isNotEmpty) {
        final matchesName = teacher.name.toLowerCase().contains(query);
        final matchesBio = teacher.bio.toLowerCase().contains(query);
        final matchesTeachingLanguage = teacher.teachingLanguages.any(
          (lang) => lang.toLowerCase().contains(query),
        );
        final matchesSpeakingLanguage = teacher.speakingLanguages.any(
          (lang) => lang.toLowerCase().contains(query),
        );
        if (!matchesName &&
            !matchesBio &&
            !matchesTeachingLanguage &&
            !matchesSpeakingLanguage) {
          return false;
        }
      }
      if (_selectedLanguage != 'All Languages' &&
          !teacher.teachingLanguages.contains(_selectedLanguage)) {
        return false;
      }
      if (teacher.hourlyRate < _priceRange.start ||
          teacher.hourlyRate > _priceRange.end) {
        return false;
      }
      if (teacher.rating < _minRating) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.filters, style: AppTypography.h4),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedLanguage = 'All Languages';
                          _priceRange = const RangeValues(0, 50);
                          _minRating = 0;
                        });
                      },
                      child: Text(
                        'Reset',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFilterContent(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Apply Filters', style: AppTypography.button),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.screenPadding(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _teacherRepository.watchTeachers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const AppErrorState(message: 'Failed to load teachers.');
        }
        if (!snapshot.hasData) {
          return const AppLoadingState();
        }

        final teachers = snapshot.data!.docs
            .where((doc) {
              final data = doc.data();
              final uid = (data['uid'] as String?)?.trim() ?? '';
              final isActive = data['isActive'] == true;
              return uid.isNotEmpty && isActive;
            })
            .map((doc) => Teacher.fromFirestore(doc.id, doc.data()))
            .toList();
        final results = filteredTeachers(teachers);

        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.findPerfectTeacher,
                style: isMobile ? AppTypography.h3 : AppTypography.h1,
              ),
              const SizedBox(height: 8),
              Text(
                'Found ${results.length} amazing teachers',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Search Bar with Filter Button on Mobile
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: AppStrings.searchTeachers,
                                border: InputBorder.none,
                                hintStyle: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isMobile) ...[
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _showFiltersBottomSheet,
                        icon: const Icon(Icons.tune, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Main Content
              if (isMobile)
                // Mobile: Teacher cards only
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final teacher = results[index];
                    return _TeacherCard(
                      teacher: teacher,
                      onViewProfile: () => context.go('/teacher/${teacher.id}'),
                      onBookNow: () => context.go('/booking/${teacher.id}'),
                      isMobile: true,
                    );
                  },
                )
              else
                // Desktop: Sidebar + Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filters Sidebar
                    SizedBox(
                      width: 280,
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
                            Text(AppStrings.filters, style: AppTypography.h4),
                            const SizedBox(height: 24),
                            _buildFilterContent(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),

                    // Teachers Grid
                    Expanded(
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: results
                            .map(
                              (teacher) => _TeacherCard(
                                teacher: teacher,
                                onViewProfile: () =>
                                    context.go('/teacher/${teacher.id}'),
                                onBookNow: () =>
                                    context.go('/booking/${teacher.id}'),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Teaching Language
        Text(AppStrings.teachingLanguage, style: AppTypography.labelLarge),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              items:
                  [
                        'All Languages',
                        'English',
                        'Japanese',
                        'Chinese',
                        'Korean',
                        'Italian',
                      ]
                      .map(
                        (lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(lang, style: AppTypography.bodyMedium),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Price Range
        Text(AppStrings.priceRange, style: AppTypography.labelLarge),
        const SizedBox(height: 12),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 50,
          divisions: 10,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.borderLight,
          onChanged: (values) {
            setState(() => _priceRange = values);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${_priceRange.start.round()}',
              style: AppTypography.bodySmall,
            ),
            Text(
              '\$${_priceRange.end.round()}+',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Minimum Rating
        Text(AppStrings.minimumRating, style: AppTypography.labelLarge),
        const SizedBox(height: 12),
        Slider(
          value: _minRating,
          min: 0,
          max: 5,
          divisions: 10,
          activeColor: AppColors.warning,
          inactiveColor: AppColors.borderLight,
          onChanged: (value) {
            setState(() => _minRating = value);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: AppTypography.bodySmall),
            Text(
              '${_minRating.toStringAsFixed(1)}+',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onViewProfile;
  final VoidCallback onBookNow;
  final bool isMobile;

  const _TeacherCard({
    required this.teacher,
    required this.onViewProfile,
    required this.onBookNow,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : 380,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: const BoxDecoration(
              gradient: AppColors.teacherCardGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                AvatarWidget(name: teacher.name, size: isMobile ? 48 : 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.name,
                        style:
                            (isMobile
                                    ? AppTypography.labelLarge
                                    : AppTypography.h4)
                                .copyWith(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.starFilled,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${teacher.rating} (${teacher.reviewCount})',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: SkillRadarChart(
                      rating: teacher.skillRating,
                      size: 70,
                      showLabels: false,
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${teacher.hourlyRate.round()}',
                      style: (isMobile ? AppTypography.h4 : AppTypography.h3)
                          .copyWith(color: Colors.white),
                    ),
                    Text(
                      '/hour',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language chip
                Wrap(
                  spacing: 8,
                  children: teacher.teachingLanguages
                      .map(
                        (lang) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lang,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),

                // Stats
                Wrap(
                  spacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${teacher.lessonCount} ${AppStrings.lessons}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                    const Text(
                      '·',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      '${teacher.studentCount} students',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bio
                Text(
                  teacher.bio,
                  style: AppTypography.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewProfile,
                        child: Text(
                          isMobile ? 'Profile' : AppStrings.viewProfile,
                          style: AppTypography.labelMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onBookNow,
                        child: Text(
                          AppStrings.bookNow,
                          style: AppTypography.button,
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
    );
  }
}
