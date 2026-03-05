import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../widgets/admin_page_scaffold.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('displayName')
        .limit(120)
        .snapshots();

    return AdminPageScaffold(
      title: 'User Management',
      subtitle: 'Search and manage student/teacher account status.',
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _search = value.trim().toLowerCase()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by name or email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorBox(
                  message: 'Failed to load users: ${snapshot.error}',
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.where((doc) {
                if (_search.isEmpty) return true;
                final data = doc.data();
                final name = (data['displayName'] as String? ?? '')
                    .toLowerCase();
                final email = (data['email'] as String? ?? '').toLowerCase();
                return name.contains(_search) || email.contains(_search);
              }).toList();

              if (docs.isEmpty) {
                return const _EmptyBox(message: 'No matching users found.');
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return _UserRow(userId: doc.id, data: doc.data());
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.userId, required this.data});

  final String userId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 680;
    final displayName = (data['displayName'] as String?)?.trim();
    final email = (data['email'] as String?)?.trim() ?? '-';
    final canTeach = (data['teachingModeEnabled'] as bool?) ?? false;
    final accountStatus = (data['accountStatus'] as String?) ?? 'active';

    Future<void> updateAccountStatus(String nextStatus) async {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'accountStatus': nextStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'adminAudit': {
          'lastAction': 'update_account_status',
          'targetId': userId,
          'status': nextStatus,
          'at': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    }

    Future<void> toggleTeachingMode() async {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'teachingModeEnabled': !canTeach,
        'updatedAt': FieldValue.serverTimestamp(),
        'adminAudit': {
          'lastAction': 'toggle_teaching_mode',
          'targetId': userId,
          'teachingModeEnabled': !canTeach,
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
            displayName?.isNotEmpty == true ? displayName! : 'Unnamed user',
            style: AppTypography.h4,
          ),
          const SizedBox(height: 4),
          Text(email, style: AppTypography.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(label: 'Status: $accountStatus'),
              _StatusChip(
                label: canTeach ? 'Teacher enabled' : 'Teacher disabled',
              ),
              _StatusChip(label: 'UID: $userId'),
            ],
          ),
          const SizedBox(height: 10),
          isCompact
              ? Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: toggleTeachingMode,
                        child: Text(
                          canTeach ? 'Disable Teaching' : 'Enable Teaching',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => updateAccountStatus('suspended'),
                        child: const Text('Suspend'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => updateAccountStatus('active'),
                        child: const Text('Reactivate'),
                      ),
                    ),
                  ],
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: toggleTeachingMode,
                      child: Text(
                        canTeach ? 'Disable Teaching' : 'Enable Teaching',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => updateAccountStatus('suspended'),
                      child: const Text('Suspend'),
                    ),
                    OutlinedButton(
                      onPressed: () => updateAccountStatus('active'),
                      child: const Text('Reactivate'),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Text(message, style: AppTypography.bodyMedium),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(message, style: AppTypography.bodyMedium),
    );
  }
}
