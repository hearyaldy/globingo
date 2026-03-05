import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../../data/repositories/group_lesson_repository.dart';
import '../../../teachers/data/repositories/teacher_repository.dart';

class GroupLessonsManageScreen extends StatefulWidget {
  const GroupLessonsManageScreen({super.key});

  @override
  State<GroupLessonsManageScreen> createState() =>
      _GroupLessonsManageScreenState();
}

class _GroupLessonsManageScreenState extends State<GroupLessonsManageScreen> {
  final GroupLessonRepository _groupLessonRepository = GroupLessonRepository();
  final TeacherRepository _teacherRepository = TeacherRepository();
  late final Future<String> _teacherDocIdFuture;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    _teacherDocIdFuture = currentUser == null
        ? Future.value('')
        : _teacherRepository.resolveTeacherDocIdByUserId(currentUser.uid);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const AppEmptyState(
        message: 'Please log in to manage group lessons.',
      );
    }

    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.screenPadding(context);

    return FutureBuilder<String>(
      future: _teacherDocIdFuture,
      builder: (context, teacherDocIdSnapshot) {
        if (teacherDocIdSnapshot.hasError) {
          return const AppErrorState(
            message: 'Failed to resolve teacher profile.',
          );
        }
        if (!teacherDocIdSnapshot.hasData) {
          return const AppLoadingState();
        }

        final teacherDocId = teacherDocIdSnapshot.data!;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _groupLessonRepository.watchTeacherLessons(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const AppErrorState(
                message: 'Failed to load group lessons.',
              );
            }
            if (!snapshot.hasData) {
              return const AppLoadingState();
            }

            final lessons = [...snapshot.data!.docs]
              ..sort((a, b) {
                final aDate =
                    (a.data()['scheduledAt'] as Timestamp?)?.toDate() ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                final bDate =
                    (b.data()['scheduledAt'] as Timestamp?)?.toDate() ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                return bDate.compareTo(aDate);
              });
            return SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.go('/dashboard'),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Manage Group Lessons',
                                style: AppTypography.h3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _createLesson(currentUser.uid, teacherDocId),
                            icon: const Icon(Icons.add),
                            label: const Text('New Group'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/dashboard'),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Manage Group Lessons',
                            style: AppTypography.h2,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _createLesson(currentUser.uid, teacherDocId),
                          icon: const Icon(Icons.add),
                          label: const Text('New Group'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Create and manage your group sessions with seat limits.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (lessons.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        'No group lessons yet. Create your first one.',
                        style: AppTypography.bodyMedium,
                      ),
                    )
                  else
                    Column(
                      children: lessons
                          .map(
                            (lessonDoc) => _GroupLessonCard(
                              lesson: lessonDoc,
                              onEdit: () => _editLesson(lessonDoc),
                              onCancel: () => _cancelLesson(lessonDoc.id),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createLesson(String teacherId, String teacherDocId) async {
    final form = await _showLessonDialog();
    if (form == null) return;

    try {
      await _groupLessonRepository.createLesson(
        teacherId: teacherId,
        teacherDocId: teacherDocId,
        title: form.title,
        description: form.description,
        language: form.language,
        level: form.level,
        capacity: form.capacity,
        pricePerSeat: form.pricePerSeat,
        scheduledAt: form.scheduledAt,
        durationMinutes: form.durationMinutes,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create group lesson.')),
      );
    }
  }

  Future<void> _editLesson(
    QueryDocumentSnapshot<Map<String, dynamic>> lessonDoc,
  ) async {
    final data = lessonDoc.data();
    final existing = _GroupLessonFormData(
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      language: (data['language'] as String?) ?? '',
      level: (data['level'] as String?) ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 6,
      pricePerSeat: (data['pricePerSeat'] as num?)?.toDouble() ?? 0,
      scheduledAt:
          (data['scheduledAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 1)),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 60,
    );

    final form = await _showLessonDialog(existing: existing);
    if (form == null) return;

    try {
      await _groupLessonRepository.updateLesson(
        lessonId: lessonDoc.id,
        title: form.title,
        description: form.description,
        language: form.language,
        level: form.level,
        capacity: form.capacity,
        pricePerSeat: form.pricePerSeat,
        scheduledAt: form.scheduledAt,
        durationMinutes: form.durationMinutes,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update group lesson.')),
      );
    }
  }

  Future<void> _cancelLesson(String lessonId) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Group Lesson'),
        content: const Text('This will mark the group session as cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    try {
      await _groupLessonRepository.cancelLesson(lessonId: lessonId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel group lesson.')),
      );
    }
  }

  Future<_GroupLessonFormData?> _showLessonDialog({
    _GroupLessonFormData? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final languageController = TextEditingController(
      text: existing?.language ?? '',
    );
    final levelController = TextEditingController(text: existing?.level ?? '');
    final capacityController = TextEditingController(
      text: (existing?.capacity ?? 6).toString(),
    );
    final priceController = TextEditingController(
      text: (existing?.pricePerSeat ?? 0).toStringAsFixed(2),
    );
    final durationController = TextEditingController(
      text: (existing?.durationMinutes ?? 60).toString(),
    );
    DateTime selectedDate =
        existing?.scheduledAt ?? DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
      existing?.scheduledAt ?? DateTime.now().add(const Duration(days: 1)),
    );

    String? validationError;
    _GroupLessonFormData? result;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Create Group Lesson' : 'Edit Group Lesson',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    TextField(
                      controller: languageController,
                      decoration: const InputDecoration(labelText: 'Language'),
                    ),
                    TextField(
                      controller: levelController,
                      decoration: const InputDecoration(
                        labelText: 'Level (optional)',
                      ),
                    ),
                    TextField(
                      controller: capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Capacity'),
                    ),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Price per seat (USD)',
                      ),
                    ),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Schedule: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')} ${selectedTime.format(context)}',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (pickedDate == null) return;
                            if (!context.mounted) return;
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (pickedTime == null) return;
                            if (!context.mounted) return;
                            setDialogState(() {
                              selectedDate = pickedDate;
                              selectedTime = pickedTime;
                            });
                          },
                          child: const Text('Pick'),
                        ),
                      ],
                    ),
                    if (validationError != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            validationError!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final language = languageController.text.trim();
                    final capacity = int.tryParse(
                      capacityController.text.trim(),
                    );
                    final price = double.tryParse(priceController.text.trim());
                    final duration = int.tryParse(
                      durationController.text.trim(),
                    );

                    if (title.isEmpty || language.isEmpty) {
                      setDialogState(
                        () => validationError =
                            'Title and language are required.',
                      );
                      return;
                    }
                    if (capacity == null || capacity <= 1) {
                      setDialogState(
                        () => validationError = 'Capacity must be at least 2.',
                      );
                      return;
                    }
                    if (price == null || price < 0) {
                      setDialogState(() => validationError = 'Invalid price.');
                      return;
                    }
                    if (duration == null || duration <= 0) {
                      setDialogState(
                        () => validationError = 'Invalid duration.',
                      );
                      return;
                    }

                    final scheduledAt = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    if (scheduledAt.isBefore(DateTime.now())) {
                      setDialogState(
                        () =>
                            validationError = 'Schedule must be in the future.',
                      );
                      return;
                    }

                    result = _GroupLessonFormData(
                      title: title,
                      description: descriptionController.text.trim(),
                      language: language,
                      level: levelController.text.trim(),
                      capacity: capacity,
                      pricePerSeat: price,
                      scheduledAt: scheduledAt,
                      durationMinutes: duration,
                    );
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(existing == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    languageController.dispose();
    levelController.dispose();
    capacityController.dispose();
    priceController.dispose();
    durationController.dispose();

    return result;
  }
}

class _GroupLessonFormData {
  final String title;
  final String description;
  final String language;
  final String level;
  final int capacity;
  final double pricePerSeat;
  final DateTime scheduledAt;
  final int durationMinutes;

  const _GroupLessonFormData({
    required this.title,
    required this.description,
    required this.language,
    required this.level,
    required this.capacity,
    required this.pricePerSeat,
    required this.scheduledAt,
    required this.durationMinutes,
  });
}

class _GroupLessonCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> lesson;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const _GroupLessonCard({
    required this.lesson,
    required this.onEdit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final data = lesson.data();
    final title = (data['title'] as String?) ?? 'Untitled';
    final language = (data['language'] as String?) ?? 'Language';
    final status = (data['status'] as String?) ?? 'scheduled';
    final capacity = (data['capacity'] as num?)?.toInt() ?? 0;
    final enrolled = (data['enrolledCount'] as num?)?.toInt() ?? 0;
    final price = (data['pricePerSeat'] as num?)?.toDouble() ?? 0;
    final scheduledAt = (data['scheduledAt'] as Timestamp?)?.toDate();
    final duration = (data['durationMinutes'] as num?)?.toInt() ?? 60;
    final isScheduled = status == 'scheduled';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTypography.labelLarge)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isScheduled
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: AppTypography.labelSmall.copyWith(
                    color: isScheduled
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [
              Text(language, style: AppTypography.bodySmall),
              Text(
                '• \$${price.toStringAsFixed(2)} / seat',
                style: AppTypography.bodySmall,
              ),
              Text(
                '• $enrolled/$capacity seats',
                style: AppTypography.bodySmall,
              ),
              Text('• $duration min', style: AppTypography.bodySmall),
            ],
          ),
          if (scheduledAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Scheduled: ${scheduledAt.year}-${scheduledAt.month.toString().padLeft(2, '0')}-${scheduledAt.day.toString().padLeft(2, '0')} ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isScheduled)
                OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
              if (isScheduled)
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Cancel Session'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
