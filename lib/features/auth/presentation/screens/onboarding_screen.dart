import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../mode_switch/presentation/providers/mode_provider.dart';

enum _OnboardingRole { student, teacher, both }

class OnboardingScreen extends ConsumerStatefulWidget {
  final String? initialRole;

  const OnboardingScreen({super.key, this.initialRole});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController(text: '25');
  final _customLanguageController = TextEditingController();
  final List<String> _allLanguages = [
    'English',
    'Japanese',
    'Chinese',
    'Korean',
    'Italian',
  ];
  final Set<String> _selectedLanguages = {'English'};
  _OnboardingRole _selectedRole = _OnboardingRole.student;
  bool _isSaving = false;

  _OnboardingRole _roleFromQuery(String? role) {
    final value = role?.toLowerCase();
    if (value == 'teacher') return _OnboardingRole.teacher;
    if (value == 'both') return _OnboardingRole.both;
    return _OnboardingRole.student;
  }

  @override
  void initState() {
    super.initState();
    _selectedRole = _roleFromQuery(widget.initialRole);
  }

  @override
  void didUpdateWidget(covariant OnboardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRole != widget.initialRole) {
      _selectedRole = _roleFromQuery(widget.initialRole);
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _hourlyRateController.dispose();
    _customLanguageController.dispose();
    super.dispose();
  }

  void _addCustomLanguage() {
    final input = _customLanguageController.text.trim();
    if (input.isEmpty) return;

    final alreadyExists = _allLanguages.any(
      (language) => language.toLowerCase() == input.toLowerCase(),
    );
    if (!alreadyExists) {
      _allLanguages.add(input);
    }

    final canonicalLanguage = _allLanguages.firstWhere(
      (language) => language.toLowerCase() == input.toLowerCase(),
      orElse: () => input,
    );
    _selectedLanguages.add(canonicalLanguage);
    _customLanguageController.clear();
    setState(() {});
  }

  Future<void> _completeOnboarding() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      context.go('/login');
      return;
    }

    final needsTeacherSetup =
        _selectedRole == _OnboardingRole.teacher ||
        _selectedRole == _OnboardingRole.both;

    if (needsTeacherSetup && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final isTeacherOnly = _selectedRole == _OnboardingRole.teacher;
    final isBoth = _selectedRole == _OnboardingRole.both;
    final isTeacher = isTeacherOnly || isBoth;
    final userName = currentUser.displayName?.trim().isNotEmpty == true
        ? currentUser.displayName!.trim()
        : (currentUser.email ?? 'User');

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
            'uid': currentUser.uid,
            'displayName': userName,
            'email': currentUser.email,
            'activeMode': isTeacherOnly ? 'teaching' : 'learning',
            'learningModeEnabled': true,
            'teachingModeEnabled': isTeacher,
            'hasCompletedOnboarding': true,
            'rolePreference': isBoth
                ? 'both'
                : (isTeacherOnly ? 'teacher' : 'student'),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (isTeacher) {
        final hourlyRate =
            double.tryParse(_hourlyRateController.text.trim()) ?? 25;
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(currentUser.uid)
            .set({
              'uid': currentUser.uid,
              'name': userName,
              'bio': _bioController.text.trim(),
              'teachingLanguages': _selectedLanguages.toList(),
              'speakingLanguages': _selectedLanguages.toList(),
              'hourlyRate': hourlyRate,
              'rating': 0,
              'reviewCount': 0,
              'lessonCount': 0,
              'studentCount': 0,
              'skillRating': {
                'clearExplanation': 0,
                'patient': 0,
                'wellPrepared': 0,
                'helpful': 0,
                'fun': 0,
              },
              'availableDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
              'isActive': true,
              'updatedAt': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        ref
            .read(modeProvider.notifier)
            .setMode(isTeacherOnly ? AppMode.teaching : AppMode.learning);
      } else {
        ref.read(modeProvider.notifier).setMode(AppMode.learning);
      }

      if (!mounted) return;
      context.go(isTeacherOnly ? '/dashboard' : '/');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to complete onboarding.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showTeacherFields =
        _selectedRole == _OnboardingRole.teacher ||
        _selectedRole == _OnboardingRole.both;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Set up your account', style: AppTypography.h3),
                        const SizedBox(height: 8),
                        Text(
                          'Choose how you want to start. You can switch modes anytime.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SegmentedButton<_OnboardingRole>(
                          segments: const [
                            ButtonSegment(
                              value: _OnboardingRole.student,
                              label: Text('Student'),
                              icon: Icon(Icons.menu_book_outlined),
                            ),
                            ButtonSegment(
                              value: _OnboardingRole.teacher,
                              label: Text('Teacher'),
                              icon: Icon(Icons.school_outlined),
                            ),
                            ButtonSegment(
                              value: _OnboardingRole.both,
                              label: Text('Both'),
                              icon: Icon(Icons.compare_arrows),
                            ),
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: (value) {
                            setState(() => _selectedRole = value.first);
                          },
                        ),
                        if (showTeacherFields) ...[
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _hourlyRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Hourly Rate (USD)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final parsed = double.tryParse(
                                (value ?? '').trim(),
                              );
                              if (parsed == null || parsed <= 0) {
                                return 'Enter a valid hourly rate';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Teaching Languages',
                            style: AppTypography.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customLanguageController,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _addCustomLanguage(),
                                  decoration: const InputDecoration(
                                    labelText: 'Add language',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: _addCustomLanguage,
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _allLanguages.map((language) {
                              final selected = _selectedLanguages.contains(
                                language,
                              );
                              return FilterChip(
                                selected: selected,
                                label: Text(language),
                                onSelected: (value) {
                                  setState(() {
                                    if (value) {
                                      _selectedLanguages.add(language);
                                    } else {
                                      _selectedLanguages.remove(language);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _bioController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Teaching Bio',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Please add a short teaching bio';
                              }
                              if (_selectedLanguages.isEmpty) {
                                return 'Select at least one teaching language';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _completeOnboarding,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    showTeacherFields
                                        ? (_selectedRole == _OnboardingRole.both
                                              ? 'Finish with Both Roles'
                                              : 'Finish and Start Teaching')
                                        : 'Finish and Start Learning',
                                    style: AppTypography.button,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
