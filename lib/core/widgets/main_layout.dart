import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../utils/responsive.dart';
import '../../features/mode_switch/presentation/widgets/mode_toggle.dart';
import '../../features/mode_switch/presentation/providers/mode_provider.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;
    final isMobile = Responsive.isMobile(context);
    final currentMode = ref.watch(modeProvider);
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final canTeach = userProfile?.teachingModeEnabled ?? false;
    final homePath = currentMode == AppMode.teaching ? '/dashboard' : '/';
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'User';
    final userEmail = user?.email ?? '';

    return Scaffold(
      appBar: isMobile
          ? _buildMobileAppBar(context, currentPath, homePath)
          : null,
      drawer: isMobile
          ? _buildDrawer(
              context,
              currentPath,
              userName,
              userEmail,
              currentMode,
              canTeach,
            )
          : null,
      body: Column(
        children: [
          if (!isMobile)
            _buildDesktopNavBar(
              context,
              ref,
              currentPath,
              currentMode,
              canTeach,
            ),
          Expanded(
            child: isMobile
                ? child
                : Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.contentMaxWidth(context),
                      ),
                      child: child,
                    ),
                  ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(
    BuildContext context,
    String currentPath,
    String homePath,
  ) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: GestureDetector(
        onTap: () => context.go(homePath),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.language,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: AppTypography.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap: () => context.go('/settings'),
          child: const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    String currentPath,
    String userName,
    String userEmail,
    AppMode currentMode,
    bool canTeach,
  ) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppColors.teacherCardGradient,
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppTypography.h4.copyWith(color: Colors.white),
                      ),
                      Text(
                        userEmail,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Mode Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const ModeToggle(compact: true),
            ),
            const Divider(),

            // Navigation Links
            if (currentMode == AppMode.learning) ...[
              _DrawerLink(
                icon: Icons.home_outlined,
                label: AppStrings.home,
                isActive: currentPath == '/',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/');
                },
              ),
              _DrawerLink(
                icon: Icons.search,
                label: AppStrings.findTeachers,
                isActive: currentPath == '/find-teachers',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/find-teachers');
                },
              ),
              _DrawerLink(
                icon: Icons.menu_book_outlined,
                label: AppStrings.myCourses,
                isActive: currentPath == '/my-courses',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/my-courses');
                },
              ),
            ],
            if (currentMode == AppMode.teaching && canTeach) ...[
              _DrawerLink(
                icon: Icons.dashboard_outlined,
                label: 'Teacher Bookings',
                isActive: currentPath == '/dashboard',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/dashboard');
                },
              ),
              _DrawerLink(
                icon: Icons.library_books_outlined,
                label: 'My Offers',
                isActive: currentPath == '/teacher-offers',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/teacher-offers');
                },
              ),
              _DrawerLink(
                icon: Icons.menu_book_outlined,
                label: AppStrings.myCourses,
                isActive: currentPath == '/my-courses',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/my-courses');
                },
              ),
            ],
            const Divider(),
            _DrawerLink(
              icon: Icons.settings_outlined,
              label: AppStrings.settings,
              isActive: currentPath == '/settings',
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),

            const Spacer(),

            // Language Selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.language, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text('English', style: AppTypography.bodyMedium),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopNavBar(
    BuildContext context,
    WidgetRef ref,
    String currentPath,
    AppMode currentMode,
    bool canTeach,
  ) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          // Logo
          GestureDetector(
            onTap: () => context.go(
              currentMode == AppMode.teaching ? '/dashboard' : '/',
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.language,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.appName,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 60),
          // Nav Links
          if (currentMode == AppMode.learning) ...[
            _NavLink(
              label: AppStrings.home,
              isActive: currentPath == '/',
              onTap: () => context.go('/'),
            ),
            _NavLink(
              label: AppStrings.findTeachers,
              isActive: currentPath == '/find-teachers',
              onTap: () => context.go('/find-teachers'),
            ),
            _NavLink(
              label: AppStrings.myCourses,
              isActive: currentPath == '/my-courses',
              onTap: () => context.go('/my-courses'),
            ),
          ],
          if (currentMode == AppMode.teaching && canTeach) ...[
            _NavLink(
              label: 'Teacher Bookings',
              isActive: currentPath == '/dashboard',
              onTap: () => context.go('/dashboard'),
            ),
            _NavLink(
              label: 'My Offers',
              isActive: currentPath == '/teacher-offers',
              onTap: () => context.go('/teacher-offers'),
            ),
            _NavLink(
              label: AppStrings.myCourses,
              isActive: currentPath == '/my-courses',
              onTap: () => context.go('/my-courses'),
            ),
          ],
          const Spacer(),
          // Mode Toggle
          const ModeToggle(),
          const SizedBox(width: 16),
          // Language Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('EN', style: AppTypography.labelMedium),
          ),
          const SizedBox(width: 16),
          // User Avatar
          GestureDetector(
            onTap: () => context.go('/settings'),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.language,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.appName,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.footerTagline,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '© 2025 Globingo. All rights reserved.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Column
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.language,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.appName,
                      style: AppTypography.h4.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.footerTagline,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Find Teachers Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.findTeachers, style: AppTypography.labelLarge),
                const SizedBox(height: 12),
                _FooterLink(label: 'Find your perfect teacher'),
                _FooterLink(label: 'English'),
                _FooterLink(label: 'Japanese'),
              ],
            ),
          ),
          // Why Globingo Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.whyGlobingo, style: AppTypography.labelLarge),
                const SizedBox(height: 12),
                _FooterLink(label: AppStrings.dualIdentity),
                _FooterLink(label: AppStrings.zeroBarrier),
                _FooterLink(label: AppStrings.communityReviews),
              ],
            ),
          ),
          // Account Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.accountSettings,
                  style: AppTypography.labelLarge,
                ),
                const SizedBox(height: 12),
                _FooterLink(label: AppStrings.personalInfo),
                _FooterLink(label: AppStrings.languagePreferences),
                _FooterLink(label: AppStrings.notifications),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavLink({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: isActive ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DrawerLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerLink({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          color: isActive ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;

  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
