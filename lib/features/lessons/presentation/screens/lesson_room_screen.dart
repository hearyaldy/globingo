import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive.dart';

class LessonRoomScreen extends StatefulWidget {
  final String bookingId;

  const LessonRoomScreen({super.key, required this.bookingId});

  @override
  State<LessonRoomScreen> createState() => _LessonRoomScreenState();
}

class _LessonRoomScreenState extends State<LessonRoomScreen> {
  Timer? _ticker;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final List<String> _messages = [];
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _notesController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to enter lesson.'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load lesson room.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.data!.exists) {
          return const Center(child: Text('Lesson not found.'));
        }

        final data = snapshot.data!.data() ?? const {};
        final learnerId = (data['learnerId'] as String?) ?? '';
        final teacherId = (data['teacherId'] as String?) ?? '';
        final isParticipant = user.uid == learnerId || user.uid == teacherId;
        if (!isParticipant) {
          return const Center(
            child: Text('You do not have access to this lesson.'),
          );
        }

        final teacherName = (data['teacherName'] as String?) ?? 'Teacher';
        final language = (data['language'] as String?) ?? 'Language';
        final offerTitle = (data['offerTitle'] as String?) ?? 'Lesson';
        final callLink = (data['callLink'] as String?)?.trim();
        final status = (data['status'] as String?) ?? 'pending';
        final durationMinutes =
            (data['durationMinutes'] as num?)?.toInt() ?? 60;
        final scheduledAt = (data['scheduledAt'] as Timestamp?)?.toDate();
        if (scheduledAt == null) {
          return const Center(child: Text('Lesson schedule is missing.'));
        }
        final now = DateTime.now();
        final windowOpen = scheduledAt.subtract(const Duration(minutes: 15));
        final windowClose = scheduledAt.add(
          Duration(minutes: durationMinutes + 30),
        );
        final inAllowedWindow =
            now.isAfter(windowOpen) && now.isBefore(windowClose);
        final enterableStatus = status == 'accepted' || status == 'in_progress';
        final canEnter = enterableStatus && inAllowedWindow;
        final canManageProgress = isParticipant;
        final isMobile = Responsive.isMobile(context);

        return SingleChildScrollView(
          padding: Responsive.screenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/my-courses'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Text('Lesson Room', style: AppTypography.h2),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$offerTitle • $language', style: AppTypography.h4),
                    const SizedBox(height: 8),
                    Text(
                      'Teacher: $teacherName',
                      style: AppTypography.bodyMedium,
                    ),
                    Text(
                      'Status: $status',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Session clock: ${_sessionClockLabel(now, scheduledAt, durationMinutes)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!canEnter)
                      Text(
                        'Lesson room opens 15 minutes before start and closes 30 minutes after end.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    if (callLink != null && callLink.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        'Call link: $callLink',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (canManageProgress && status == 'accepted')
                          ElevatedButton(
                            onPressed: _isUpdatingStatus || !inAllowedWindow
                                ? null
                                : () => _updateStatus('in_progress'),
                            child: const Text('Start Lesson'),
                          ),
                        if (canManageProgress && status == 'in_progress') ...[
                          ElevatedButton(
                            onPressed: _isUpdatingStatus
                                ? null
                                : () => _updateStatus('completed'),
                            child: const Text('Complete Lesson'),
                          ),
                        ],
                        if (status == 'completed') ...[
                          ElevatedButton(
                            onPressed: () =>
                                context.go('/review/${widget.bookingId}'),
                            child: const Text('Leave Review'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (canEnter || status == 'in_progress' || status == 'completed')
                if (isMobile)
                  Column(
                    children: [
                      _buildNotesPanel(),
                      const SizedBox(height: 16),
                      _buildChatPanel(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildNotesPanel()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildChatPanel()),
                    ],
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotesPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lesson Notes', style: AppTypography.h4),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            minLines: 8,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Write your lesson notes here...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chat', style: AppTypography.h4),
          const SizedBox(height: 10),
          SizedBox(
            height: 260,
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_messages[index]),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: const InputDecoration(
                    hintText: 'Type message...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final msg = _chatController.text.trim();
                  if (msg.isEmpty) return;
                  setState(() {
                    _messages.add(msg);
                    _chatController.clear();
                  });
                },
                child: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _sessionClockLabel(
    DateTime now,
    DateTime scheduledAt,
    int durationMin,
  ) {
    if (now.isBefore(scheduledAt)) {
      final diff = scheduledAt.difference(now);
      final m = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
      final h = diff.inHours.toString().padLeft(2, '0');
      final s = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
      return 'Starts in $h:$m:$s';
    }
    final end = scheduledAt.add(Duration(minutes: durationMin));
    if (now.isBefore(end)) {
      final diff = end.difference(now);
      return 'Ends in ${diff.inMinutes} min';
    }
    return 'Session ended';
  }

  Future<void> _updateStatus(String status) async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to update lesson status.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }
}
