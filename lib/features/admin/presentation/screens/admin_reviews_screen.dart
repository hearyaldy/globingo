import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../widgets/admin_page_scaffold.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  int _minimumRating = 1;

  @override
  Widget build(BuildContext context) {
    final reviewsStream = FirebaseFirestore.instance
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(120)
        .snapshots();

    return AdminPageScaffold(
      title: 'Review Moderation',
      subtitle: 'Manage teacher ratings and moderate abusive/unfair reviews.',
      actions: [
        DropdownButton<int>(
          value: _minimumRating,
          onChanged: (value) {
            if (value != null) {
              setState(() => _minimumRating = value);
            }
          },
          items: const [
            DropdownMenuItem(value: 1, child: Text('Rating >= 1')),
            DropdownMenuItem(value: 2, child: Text('Rating >= 2')),
            DropdownMenuItem(value: 3, child: Text('Rating >= 3')),
            DropdownMenuItem(value: 4, child: Text('Rating >= 4')),
          ],
        ),
      ],
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: reviewsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageCard(
              message: 'Failed to load reviews: ${snapshot.error}',
              color: AppColors.error,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final rating = (data['rating'] as num?)?.toInt() ?? 0;
            return rating >= _minimumRating;
          }).toList();

          if (docs.isEmpty) {
            return const _MessageCard(message: 'No reviews in this filter.');
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _ReviewRow(reviewId: doc.id, data: doc.data());
            },
          );
        },
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.reviewId, required this.data});

  final String reviewId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 680;
    final rating = (data['rating'] as num?)?.toInt() ?? 0;
    final reviewText = (data['comment'] as String?)?.trim() ?? '';
    final hidden = (data['isHiddenByAdmin'] as bool?) ?? false;
    final bookingId = (data['bookingId'] as String?) ?? '-';

    Future<void> moderate({required bool hide, required String reason}) async {
      await FirebaseFirestore.instance.collection('reviews').doc(reviewId).set({
        'isHiddenByAdmin': hide,
        'adminModeration': {
          'reason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: 'Rating: $rating'),
              _Pill(label: hidden ? 'Hidden' : 'Visible'),
              _Pill(label: 'Booking: $bookingId'),
            ],
          ),
          if (reviewText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(reviewText, style: AppTypography.bodyMedium),
          ],
          const SizedBox(height: 10),
          isCompact
              ? Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            moderate(hide: true, reason: 'hidden_by_admin'),
                        child: const Text('Hide Review'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            moderate(hide: false, reason: 'restored_by_admin'),
                        child: const Text('Restore Review'),
                      ),
                    ),
                  ],
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () =>
                          moderate(hide: true, reason: 'hidden_by_admin'),
                      child: const Text('Hide Review'),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          moderate(hide: false, reason: 'restored_by_admin'),
                      child: const Text('Restore Review'),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

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

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.color = AppColors.info});

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
