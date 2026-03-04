import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/mode_provider.dart';

class ModeToggle extends ConsumerWidget {
  final bool? compact;

  const ModeToggle({super.key, this.compact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(modeProvider);
    final isMobile = compact ?? Responsive.isMobile(context);
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final canTeach = userProfile?.teachingModeEnabled ?? false;
    final desiredMode = (userProfile?.activeMode == 'teaching')
        ? AppMode.teaching
        : AppMode.learning;
    if (currentMode != desiredMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(modeProvider.notifier).setMode(desiredMode);
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            label: isMobile ? 'Learn' : AppStrings.learningMode,
            icon: Icons.menu_book_outlined,
            isActive: currentMode == AppMode.learning,
            activeColor: AppColors.learningMode,
            onTap: () => _setMode(context, ref, AppMode.learning),
            compact: isMobile,
          ),
          _ModeButton(
            label: isMobile ? 'Teach' : AppStrings.teachingMode,
            icon: Icons.school_outlined,
            isActive: currentMode == AppMode.teaching,
            activeColor: AppColors.teachingMode,
            onTap: () {
              if (!canTeach) {
                context.go('/onboarding?role=teacher');
                return;
              }
              _setMode(context, ref, AppMode.teaching);
            },
            compact: isMobile,
            enabled: canTeach,
          ),
        ],
      ),
    );
  }

  Future<void> _setMode(
    BuildContext context,
    WidgetRef ref,
    AppMode mode,
  ) async {
    ref.read(modeProvider.notifier).setMode(mode);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'activeMode': mode == AppMode.teaching ? 'teaching' : 'learning',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!context.mounted) return;
    context.go(mode == AppMode.teaching ? '/dashboard' : '/');
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;
  final bool compact;
  final bool enabled;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    this.compact = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          border: !enabled ? Border.all(color: AppColors.borderLight) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 16 : 18,
              color: !enabled
                  ? AppColors.textLight
                  : (isActive ? Colors.white : AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style:
                  (compact
                          ? AppTypography.bodySmall
                          : AppTypography.labelMedium)
                      .copyWith(
                        color: !enabled
                            ? AppColors.textLight
                            : (isActive
                                  ? Colors.white
                                  : AppColors.textSecondary),
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
