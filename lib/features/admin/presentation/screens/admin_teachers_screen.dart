import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../widgets/admin_page_scaffold.dart';

class AdminTeachersScreen extends StatefulWidget {
  const AdminTeachersScreen({super.key});

  @override
  State<AdminTeachersScreen> createState() => _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends State<AdminTeachersScreen> {
  String _qualityFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final teachersStream = FirebaseFirestore.instance
        .collection('users')
        .where('teachingModeEnabled', isEqualTo: true)
        .limit(120)
        .snapshots();

    return AdminPageScaffold(
      title: 'Teacher Operations',
      subtitle: 'Manage teaching access and quality guard overrides.',
      actions: [
        DropdownButton<String>(
          value: _qualityFilter,
          onChanged: (value) {
            if (value != null) {
              setState(() => _qualityFilter = value);
            }
          },
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All')),
            DropdownMenuItem(value: 'warning', child: Text('Warning')),
            DropdownMenuItem(value: 'freeze', child: Text('Freeze')),
          ],
        ),
      ],
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: teachersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _InfoBox(
              message: 'Failed to load teachers: ${snapshot.error}',
              color: AppColors.error,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            if (_qualityFilter == 'all') return true;
            final guard = doc.data()['qualityGuard'] as Map<String, dynamic>?;
            final status = (guard?['status'] as String?) ?? '';
            return status == _qualityFilter;
          }).toList();

          if (docs.isEmpty) {
            return const _InfoBox(
              message: 'No teacher records for the selected filter.',
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _TeacherRow(teacherId: doc.id, data: doc.data());
            },
          );
        },
      ),
    );
  }
}

class _TeacherRow extends StatelessWidget {
  const _TeacherRow({required this.teacherId, required this.data});

  final String teacherId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 680;
    final name = (data['displayName'] as String?)?.trim();
    final rating = (data['ratingAverage'] as num?)?.toDouble();
    final qualityGuard = data['qualityGuard'] as Map<String, dynamic>?;
    final guardStatus = (qualityGuard?['status'] as String?) ?? 'none';
    final teachingEnabled = (data['teachingModeEnabled'] as bool?) ?? false;

    Future<void> setTeachingEnabled(bool enabled) async {
      await FirebaseFirestore.instance.collection('users').doc(teacherId).set({
        'teachingModeEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
        'qualityGuard': {
          'status': enabled ? 'manual_unfreeze' : 'manual_freeze',
          'updatedAt': FieldValue.serverTimestamp(),
          'reason': 'admin_override',
        },
        'adminAudit': {
          'lastAction': enabled ? 'teacher_unfreeze' : 'teacher_freeze',
          'targetId': teacherId,
          'at': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name?.isNotEmpty == true ? name! : 'Unnamed teacher',
            style: AppTypography.h4,
          ),
          const SizedBox(height: 4),
          Text('Teacher ID: $teacherId', style: AppTypography.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: 'Rating: ${rating?.toStringAsFixed(2) ?? '-'}'),
              _MetaChip(label: 'Quality guard: $guardStatus'),
              _MetaChip(
                label: teachingEnabled ? 'Teaching enabled' : 'Teaching frozen',
              ),
            ],
          ),
          const SizedBox(height: 10),
          isCompact
              ? Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => setTeachingEnabled(false),
                        child: const Text('Freeze Teaching'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => setTeachingEnabled(true),
                        child: const Text('Unfreeze Teaching'),
                      ),
                    ),
                  ],
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => setTeachingEnabled(false),
                      child: const Text('Freeze Teaching'),
                    ),
                    OutlinedButton(
                      onPressed: () => setTeachingEnabled(true),
                      child: const Text('Unfreeze Teaching'),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppTypography.labelMedium),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.message, this.color = AppColors.info});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(message, style: AppTypography.bodyMedium),
    );
  }
}
