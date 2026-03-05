import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../widgets/admin_page_scaffold.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  String _status = 'all';

  @override
  Widget build(BuildContext context) {
    final bookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .limit(120)
        .snapshots();

    return AdminPageScaffold(
      title: 'Booking Management',
      subtitle: 'Manage class schedule bookings and resolve escalations.',
      actions: [
        DropdownButton<String>(
          value: _status,
          onChanged: (value) {
            if (value != null) {
              setState(() => _status = value);
            }
          },
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All statuses')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
            DropdownMenuItem(value: 'no_show', child: Text('No Show')),
          ],
        ),
      ],
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: bookingsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _InfoCard(
              message: 'Failed to load bookings: ${snapshot.error}',
              color: AppColors.error,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            if (_status == 'all') return true;
            final status = (doc.data()['status'] as String?) ?? '';
            return status == _status;
          }).toList();

          if (docs.isEmpty) {
            return const _InfoCard(
              message: 'No bookings found for this filter.',
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _BookingRow(bookingId: doc.id, data: doc.data());
            },
          );
        },
      ),
    );
  }
}

class _BookingRow extends StatefulWidget {
  const _BookingRow({required this.bookingId, required this.data});

  final String bookingId;
  final Map<String, dynamic> data;

  @override
  State<_BookingRow> createState() => _BookingRowState();
}

class _BookingRowState extends State<_BookingRow> {
  late Future<_ParticipantNames> _participantNamesFuture;

  @override
  void initState() {
    super.initState();
    _participantNamesFuture = _resolveParticipantNames();
  }

  @override
  void didUpdateWidget(covariant _BookingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookingId != widget.bookingId ||
        oldWidget.data['teacherId'] != widget.data['teacherId'] ||
        oldWidget.data['learnerId'] != widget.data['learnerId'] ||
        oldWidget.data['teacherName'] != widget.data['teacherName'] ||
        oldWidget.data['learnerName'] != widget.data['learnerName']) {
      _participantNamesFuture = _resolveParticipantNames();
    }
  }

  Future<_ParticipantNames> _resolveParticipantNames() async {
    final teacherId = (widget.data['teacherId'] as String?) ?? '-';
    final learnerId = (widget.data['learnerId'] as String?) ?? '-';
    final teacherNameHint = (widget.data['teacherName'] as String?)?.trim();
    final learnerNameHint = (widget.data['learnerName'] as String?)?.trim();

    Future<String> resolveName({
      required String userId,
      required String? nameHint,
    }) async {
      if (nameHint != null && nameHint.isNotEmpty) {
        return nameHint;
      }
      if (userId == '-' || userId.isEmpty) {
        return '-';
      }
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (!snapshot.exists) {
          return userId;
        }
        final data = snapshot.data();
        final displayName = (data?['displayName'] as String?)?.trim();
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
        final email = (data?['email'] as String?)?.trim();
        if (email != null && email.isNotEmpty) {
          return email;
        }
      } catch (_) {
        // Fallback to ID when lookup fails.
      }
      return userId;
    }

    final teacherName = await resolveName(
      userId: teacherId,
      nameHint: teacherNameHint,
    );
    final learnerName = await resolveName(
      userId: learnerId,
      nameHint: learnerNameHint,
    );

    return _ParticipantNames(
      teacherName: teacherName,
      learnerName: learnerName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 680;
    final teacherId = (widget.data['teacherId'] as String?) ?? '-';
    final learnerId = (widget.data['learnerId'] as String?) ?? '-';
    final status = (widget.data['status'] as String?) ?? 'unknown';
    final paymentRoute =
        (widget.data['paymentRoute'] as String?) ?? 'teacher_direct';

    Future<void> forceCancel() async {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .set({
            'status': 'cancelled',
            'adminOverride': {
              'action': 'force_cancel',
              'at': FieldValue.serverTimestamp(),
              'reason': 'admin_resolution',
            },
            'updatedAt': FieldValue.serverTimestamp(),
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
          Text('Booking: ${widget.bookingId}', style: AppTypography.h4),
          const SizedBox(height: 6),
          FutureBuilder<_ParticipantNames>(
            future: _participantNamesFuture,
            builder: (context, snapshot) {
              final fallbackTeacher = (widget.data['teacherName'] as String?)
                  ?.trim();
              final fallbackLearner = (widget.data['learnerName'] as String?)
                  ?.trim();
              final teacherName =
                  snapshot.data?.teacherName ??
                  (fallbackTeacher != null && fallbackTeacher.isNotEmpty
                      ? fallbackTeacher
                      : teacherId);
              final learnerName =
                  snapshot.data?.learnerName ??
                  (fallbackLearner != null && fallbackLearner.isNotEmpty
                      ? fallbackLearner
                      : learnerId);

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _LabelChip(label: 'Status: $status'),
                  _LabelChip(label: 'Teacher: $teacherName'),
                  _LabelChip(label: 'Learner: $learnerName'),
                  _LabelChip(label: 'Route: $paymentRoute'),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          if (isCompact) ...[
            Text('Teacher ID: $teacherId', style: AppTypography.bodySmall),
            Text('Learner ID: $learnerId', style: AppTypography.bodySmall),
          ] else
            Text(
              'Teacher ID: $teacherId • Learner ID: $learnerId',
              style: AppTypography.bodySmall,
            ),
          const SizedBox(height: 10),
          isCompact
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: forceCancel,
                    child: const Text('Force Cancel'),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: forceCancel,
                      child: const Text('Force Cancel'),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _ParticipantNames {
  const _ParticipantNames({
    required this.teacherName,
    required this.learnerName,
  });

  final String teacherName;
  final String learnerName;
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label});

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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message, this.color = AppColors.info});

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
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(message, style: AppTypography.bodyMedium),
    );
  }
}
