import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/config/routes.dart';
import '../widgets/admin_page_scaffold.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Admin Console',
      subtitle:
          'Operations center for user, teacher, review, and booking management.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width < 760 ? 1 : (width < 1100 ? 2 : 3);
          return GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: width < 760 ? 1.85 : (width < 1100 ? 2.0 : 2.2),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _AdminCard(
                title: 'Users',
                description:
                    'Search students/teachers and update account status.',
                icon: Icons.people_outline,
                route: AppRoutes.adminUsers,
              ),
              _AdminCard(
                title: 'Teachers',
                description: 'Manage teaching access and quality guard status.',
                icon: Icons.school_outlined,
                route: AppRoutes.adminTeachers,
              ),
              _AdminCard(
                title: 'Reviews',
                description: 'Moderate reviews and track rating risks.',
                icon: Icons.reviews_outlined,
                route: AppRoutes.adminReviews,
              ),
              _AdminCard(
                title: 'Bookings',
                description: 'Manage schedules and resolve escalated bookings.',
                icon: Icons.calendar_month_outlined,
                route: AppRoutes.adminBookings,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 760;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          crossAxisAlignment: isNarrow
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.h4),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: isNarrow ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
