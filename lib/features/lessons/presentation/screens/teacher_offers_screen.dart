import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/async_state_widgets.dart';

class TeacherOffersScreen extends StatelessWidget {
  const TeacherOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMobile = Responsive.isMobile(context);
    if (currentUser == null) {
      return const AppEmptyState(
        message: 'Please log in to manage lesson offers.',
      );
    }

    return SingleChildScrollView(
      padding: Responsive.screenPadding(context),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('lesson_offers')
            .where('teacherId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Failed to load offers: ${snapshot.error}',
            );
          }
          if (!snapshot.hasData) {
            return const AppLoadingState();
          }

          final docs = [...snapshot.data!.docs]
            ..sort((a, b) {
              final aTime = (a.data()['updatedAt'] as Timestamp?)?.toDate();
              final bTime = (b.data()['updatedAt'] as Timestamp?)?.toDate();
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Lesson Offers', style: AppTypography.h1),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showOfferDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text('Add Offer', style: AppTypography.button),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Text('My Lesson Offers', style: AppTypography.h1),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showOfferDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('Add Offer', style: AppTypography.button),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Text(
                'Create lesson packages students can book.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              if (docs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    'No offers yet. Add your first lesson offer.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: docs.map((doc) {
                    final data = doc.data();
                    final title = (data['title'] as String?) ?? 'Untitled';
                    final language =
                        (data['language'] as String?) ?? 'Language';
                    final level = (data['level'] as String?) ?? 'All levels';
                    final duration =
                        (data['durationMin'] as num?)?.toInt() ?? 60;
                    final price = (data['price'] as num?)?.toDouble() ?? 0;
                    final isActive = data['isActive'] == true;
                    return _OfferCard(
                      isMobile: isMobile,
                      title: title,
                      language: language,
                      level: level,
                      duration: duration,
                      price: price,
                      isActive: isActive,
                      onEdit: () => _showOfferDialog(
                        context,
                        docId: doc.id,
                        initialData: data,
                      ),
                      onDelete: () => _deleteOffer(context, doc.id),
                      onToggleActive: (value) =>
                          _toggleActive(context, doc.id, value),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    String docId,
    bool value,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('lesson_offers')
          .doc(docId)
          .set({
            'isActive': value,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to update offer.')),
      );
    }
  }

  Future<void> _deleteOffer(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('lesson_offers')
          .doc(docId)
          .delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Offer deleted.')));
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to delete offer.')),
      );
    }
  }

  Future<void> _showOfferDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? initialData,
  }) async {
    final parentContext = context;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final titleController = TextEditingController(
      text: (initialData?['title'] as String?) ?? '',
    );
    final descriptionController = TextEditingController(
      text: (initialData?['description'] as String?) ?? '',
    );
    final languageController = TextEditingController(
      text: (initialData?['language'] as String?) ?? '',
    );
    final levelController = TextEditingController(
      text: (initialData?['level'] as String?) ?? 'All levels',
    );
    final durationController = TextEditingController(
      text: ((initialData?['durationMin'] as num?)?.toInt() ?? 60).toString(),
    );
    final priceController = TextEditingController(
      text: ((initialData?['price'] as num?)?.toDouble() ?? 25).toString(),
    );
    bool isActive = initialData?['isActive'] != false;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isMobile = MediaQuery.of(context).size.width < 768;
            return AlertDialog(
              title: Text(
                docId == null ? 'Create Lesson Offer' : 'Edit Lesson Offer',
              ),
              content: SizedBox(
                width: isMobile ? double.infinity : 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isMobile)
                        Column(
                          children: [
                            TextField(
                              controller: languageController,
                              decoration: const InputDecoration(
                                labelText: 'Language',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: levelController,
                              decoration: const InputDecoration(
                                labelText: 'Level',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: languageController,
                                decoration: const InputDecoration(
                                  labelText: 'Language',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: levelController,
                                decoration: const InputDecoration(
                                  labelText: 'Level',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      if (isMobile)
                        Column(
                          children: [
                            TextField(
                              controller: durationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Duration (minutes)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price (USD)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: durationController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Duration (minutes)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Price (USD)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (value) => setState(() => isActive = value),
                        title: const Text('Offer is active'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final description = descriptionController.text.trim();
                          final language = languageController.text.trim();
                          final level = levelController.text.trim();
                          final duration = int.tryParse(
                            durationController.text.trim(),
                          );
                          final price = double.tryParse(
                            priceController.text.trim(),
                          );

                          if (title.isEmpty ||
                              description.isEmpty ||
                              language.isEmpty ||
                              duration == null ||
                              duration <= 0 ||
                              price == null ||
                              price <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please complete all fields with valid values.',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => isSaving = true);
                          try {
                            final ref = docId == null
                                ? FirebaseFirestore.instance
                                      .collection('lesson_offers')
                                      .doc()
                                : FirebaseFirestore.instance
                                      .collection('lesson_offers')
                                      .doc(docId);

                            await ref.set({
                              'teacherId': currentUser.uid,
                              'title': title,
                              'description': description,
                              'language': language,
                              'level': level.isEmpty ? 'All levels' : level,
                              'durationMin': duration,
                              'price': price,
                              'isActive': isActive,
                              'updatedAt': FieldValue.serverTimestamp(),
                              if (docId == null)
                                'createdAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  docId == null
                                      ? 'Offer created.'
                                      : 'Offer updated.',
                                ),
                              ),
                            );
                          } on FirebaseException catch (e) {
                            if (!context.mounted) return;
                            setState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.message ?? 'Failed to save offer.',
                                ),
                              ),
                            );
                          }
                        },
                  child: Text(docId == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  final bool isMobile;
  final String title;
  final String language;
  final String level;
  final int duration;
  final double price;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const _OfferCard({
    required this.isMobile,
    required this.title,
    required this.language,
    required this.level,
    required this.duration,
    required this.price,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h4),
          const SizedBox(height: 6),
          Text(
            '$language • $level • ${duration}min',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text('\$${price.toStringAsFixed(0)}', style: AppTypography.h3),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: AppTypography.labelMedium.copyWith(
                    color: isActive
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              Switch(
                value: isActive,
                onChanged: onToggleActive,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onDelete, child: const Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
