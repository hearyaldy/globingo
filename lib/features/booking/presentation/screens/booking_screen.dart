import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../data/repositories/booking_repository.dart';
import '../../../teachers/data/models/teacher_model.dart';
import '../../../teachers/data/repositories/teacher_repository.dart';

class BookingScreen extends StatefulWidget {
  final String teacherId;

  const BookingScreen({super.key, required this.teacherId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TeacherRepository _teacherRepository = TeacherRepository();
  final BookingRepository _bookingRepository = BookingRepository();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  int _selectedDuration = 60;
  String? _selectedOfferId;
  String? _selectedOfferTitle;
  String? _selectedOfferLanguage;
  double? _selectedOfferPrice;
  int? _selectedOfferDuration;
  String _selectedPayment = 'credit_card';
  bool _isSubmittingBooking = false;

  final List<String> _availableTimes = [
    '09:00',
    '10:00',
    '11:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '19:00',
    '20:00',
  ];

  final List<int> _durations = [30, 45, 60, 90];
  static const List<String> _weekdayShortNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  double _totalPrice(Teacher teacher) {
    if (_selectedOfferPrice != null) {
      return _selectedOfferPrice!;
    }
    return teacher.hourlyRate * (_selectedDuration / 60);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.screenPadding(context);
    return FutureBuilder<String?>(
      future: _resolveTeacherDocId(),
      builder: (context, resolveSnapshot) {
        if (resolveSnapshot.hasError) {
          return const AppErrorState(message: 'Failed to resolve teacher.');
        }
        if (!resolveSnapshot.hasData) {
          return const AppLoadingState();
        }
        final resolvedTeacherDocId = resolveSnapshot.data;
        if (resolvedTeacherDocId == null) {
          return const Scaffold(body: Center(child: Text('Teacher not found')));
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _teacherRepository.watchTeacherDoc(resolvedTeacherDocId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const AppErrorState(message: 'Failed to load teacher.');
            }
            if (!snapshot.hasData) {
              return const AppLoadingState();
            }
            if (!snapshot.data!.exists) {
              return const Scaffold(
                body: Center(child: Text('Teacher not found')),
              );
            }

            final currentTeacher = Teacher.fromFirestore(
              snapshot.data!.id,
              snapshot.data!.data() ?? const {},
            );
            final nextAvailableDate = _findNextAvailableDate(
              currentTeacher.availableDays,
            );
            final selectedDayName =
                _weekdayShortNames[_selectedDate.weekday - 1];
            final selectedDayAvailable = currentTeacher.availableDays.contains(
              selectedDayName,
            );
            if (nextAvailableDate != null && !selectedDayAvailable) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _selectedDate = nextAvailableDate);
              });
            }

            return SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                            return;
                          }
                          context.go('/find-teachers');
                        },
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.bookLesson,
                        style: isMobile ? AppTypography.h3 : AppTypography.h2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (isMobile)
                    Column(
                      children: [
                        _buildTeacherSummary(currentTeacher),
                        const SizedBox(height: 24),
                        _buildBookingForm(
                          isMobile,
                          currentTeacher,
                          selectedDayAvailable,
                        ),
                        const SizedBox(height: 24),
                        _buildOrderSummary(
                          currentTeacher,
                          isMobile,
                          _totalPrice(currentTeacher),
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildTeacherSummary(currentTeacher),
                              const SizedBox(height: 24),
                              _buildBookingForm(
                                isMobile,
                                currentTeacher,
                                selectedDayAvailable,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: _buildOrderSummary(
                            currentTeacher,
                            isMobile,
                            _totalPrice(currentTeacher),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _resolveTeacherDocId() async {
    return _teacherRepository.resolveTeacherDocId(widget.teacherId);
  }

  Widget _buildTeacherSummary(Teacher teacher) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          AvatarWidget(name: teacher.name, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teacher.name, style: AppTypography.h4),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.starFilled,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${teacher.rating} (${teacher.reviewCount} reviews)',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: teacher.teachingLanguages
                      .map(
                        (lang) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lang,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${teacher.hourlyRate.round()}',
                style: AppTypography.h3.copyWith(color: AppColors.primary),
              ),
              Text('/hour', style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingForm(
    bool isMobile,
    Teacher teacher,
    bool selectedDayAvailable,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lesson Offer', style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          _buildLessonOfferSelector(teacher),
          const SizedBox(height: 24),

          // Date Selection
          Text(AppStrings.selectDate, style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          _buildDateSelector(teacher.availableDays),
          const SizedBox(height: 24),

          // Time Selection
          Text(AppStrings.selectTime, style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          _buildTimeSelector(teacher, selectedDayAvailable),
          const SizedBox(height: 24),

          // Duration Selection
          Text(AppStrings.lessonDuration, style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          _buildDurationSelector(),
          const SizedBox(height: 24),

          // Payment Method
          Text(AppStrings.paymentMethod, style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          _buildPaymentSelector(),
        ],
      ),
    );
  }

  Widget _buildLessonOfferSelector(Teacher teacher) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _teacherRepository.watchLessonOffers(
        teacherUid: teacher.uid,
        teacherDocId: teacher.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Failed to load lesson offers.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final offers = snapshot.data!.docs
            .where((doc) => doc.data()['isActive'] != false)
            .toList();
        if (offers.isEmpty) {
          return Text(
            'This teacher has no configured lesson offers. Booking will use hourly rate.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          );
        }

        final hasSelectedOffer =
            _selectedOfferId != null &&
            offers.any((doc) => doc.id == _selectedOfferId);
        if (!hasSelectedOffer) {
          final first = offers.first;
          final data = first.data();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedOfferId = first.id;
              _selectedOfferTitle = (data['title'] as String?) ?? 'Lesson';
              _selectedOfferLanguage =
                  (data['language'] as String?) ?? 'Language';
              _selectedOfferPrice =
                  (data['price'] as num?)?.toDouble() ?? _selectedOfferPrice;
              _selectedOfferDuration =
                  (data['durationMin'] as num?)?.toInt() ?? _selectedDuration;
              if (_selectedOfferDuration != null) {
                _selectedDuration = _selectedOfferDuration!;
              }
            });
          });
        }

        return Column(
          children: offers.map((doc) {
            final data = doc.data();
            final title = (data['title'] as String?) ?? 'Lesson';
            final language = (data['language'] as String?) ?? 'Language';
            final duration = (data['durationMin'] as num?)?.toInt() ?? 60;
            final price = (data['price'] as num?)?.toDouble() ?? 0;
            final isSelected = _selectedOfferId == doc.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOfferId = doc.id;
                  _selectedOfferTitle = title;
                  _selectedOfferLanguage = language;
                  _selectedOfferPrice = price;
                  _selectedOfferDuration = duration;
                  _selectedDuration = duration;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTypography.labelMedium),
                          const SizedBox(height: 2),
                          Text(
                            '$language • $duration min',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${price.toStringAsFixed(0)}',
                      style: AppTypography.labelLarge.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDateSelector(List<String> availableDays) {
    final dates = List.generate(
      14,
      (i) => DateTime.now().add(Duration(days: i + 1)),
    );

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = dates[index];
          final dayName = _weekdayShortNames[date.weekday - 1];
          final isAvailableDay = availableDays.contains(dayName);
          final isSelected =
              _selectedDate.day == date.day &&
              _selectedDate.month == date.month;

          return GestureDetector(
            onTap: isAvailableDay
                ? () => setState(() => _selectedDate = date)
                : null,
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isAvailableDay
                          ? AppColors.background
                          : AppColors.borderLight.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isAvailableDay
                            ? AppColors.border
                            : AppColors.borderLight),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : (isAvailableDay
                                ? AppColors.textSecondary
                                : AppColors.textLight),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: AppTypography.h4.copyWith(
                      color: isSelected
                          ? Colors.white
                          : (isAvailableDay
                                ? AppColors.textPrimary
                                : AppColors.textLight),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSelector(Teacher teacher, bool selectedDayAvailable) {
    if (!selectedDayAvailable) {
      return Text(
        'Teacher is not available on selected date.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _teacherBookingsStream(teacher),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Failed to load availability.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final bookings = snapshot.data!.docs.map((doc) => doc.data()).where((
          data,
        ) {
          final status = (data['status'] as String?) ?? '';
          return status == 'pending' ||
              status == 'accepted' ||
              status == 'in_progress';
        }).toList();

        final selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _availableTimes.map((time) {
            final slotDateTime = _timeToDateTime(selectedDate, time);
            final isConflicting = _isConflictingSlot(slotDateTime, bookings);
            final isSelected = _selectedTime == time;
            final isDisabled = isConflicting;
            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () => setState(() => _selectedTime = time),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDisabled
                            ? AppColors.borderLight.withValues(alpha: 0.6)
                            : AppColors.background),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDisabled
                              ? AppColors.borderLight
                              : AppColors.border),
                  ),
                ),
                child: Text(
                  time,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isDisabled
                              ? AppColors.textLight
                              : AppColors.textPrimary),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _teacherBookingsStream(
    Teacher teacher,
  ) {
    return _bookingRepository.watchTeacherBookings(
      teacherUid: teacher.uid,
      teacherDocId: teacher.id,
    );
  }

  DateTime _timeToDateTime(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  bool _isConflictingSlot(
    DateTime slotStart,
    List<Map<String, dynamic>> bookings,
  ) {
    final slotEnd = slotStart.add(Duration(minutes: _selectedDuration));
    for (final booking in bookings) {
      final scheduledAt = (booking['scheduledAt'] as Timestamp?)?.toDate();
      if (scheduledAt == null) continue;
      if (scheduledAt.year != slotStart.year ||
          scheduledAt.month != slotStart.month ||
          scheduledAt.day != slotStart.day) {
        continue;
      }
      final duration = (booking['durationMinutes'] as num?)?.toInt() ?? 60;
      final bookingEnd = scheduledAt.add(Duration(minutes: duration));
      final overlap =
          slotStart.isBefore(bookingEnd) && slotEnd.isAfter(scheduledAt);
      if (overlap) return true;
    }
    return false;
  }

  DateTime? _findNextAvailableDate(List<String> availableDays) {
    for (var i = 1; i <= 30; i++) {
      final candidate = DateTime.now().add(Duration(days: i));
      final dayName = _weekdayShortNames[candidate.weekday - 1];
      if (availableDays.contains(dayName)) {
        return DateTime(candidate.year, candidate.month, candidate.day);
      }
    }
    return null;
  }

  Widget _buildDurationSelector() {
    return Row(
      children: _durations.map((duration) {
        final isSelected = _selectedDuration == duration;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDuration = duration),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  '$duration min',
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentSelector() {
    final paymentMethods = [
      {'id': 'credit_card', 'label': 'Credit Card', 'icon': Icons.credit_card},
      {'id': 'paypal', 'label': 'PayPal', 'icon': Icons.account_balance_wallet},
      {'id': 'apple_pay', 'label': 'Apple Pay', 'icon': Icons.apple},
    ];

    return Column(
      children: paymentMethods.map((method) {
        final isSelected = _selectedPayment == method['id'];
        return GestureDetector(
          onTap: () =>
              setState(() => _selectedPayment = method['id'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  method['icon'] as IconData,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  method['label'] as String,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _resolvePaymentRoute() {
    return 'organization_escrow';
  }

  Widget _buildOrderSummary(Teacher teacher, bool isMobile, double totalPrice) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.orderSummary, style: AppTypography.h4),
          const SizedBox(height: 20),
          _SummaryRow(label: 'Teacher', value: teacher.name),
          _SummaryRow(
            label: 'Date',
            value:
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          ),
          _SummaryRow(label: 'Time', value: _selectedTime ?? 'Not selected'),
          _SummaryRow(label: 'Duration', value: '$_selectedDuration minutes'),
          const Divider(height: 32),
          _SummaryRow(
            label: 'Lesson Fee',
            value: '\$${totalPrice.toStringAsFixed(2)}',
          ),
          if (_selectedOfferTitle != null)
            _SummaryRow(label: 'Offer', value: _selectedOfferTitle!),
          _SummaryRow(
            label: 'Platform Fee',
            value: '\$${(totalPrice * 0.1).toStringAsFixed(2)}',
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTypography.labelLarge),
              Text(
                '\$${(totalPrice * 1.1).toStringAsFixed(2)}',
                style: AppTypography.h3.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedTime != null && !_isSubmittingBooking
                  ? _confirmBooking
                  : null,
              child: _isSubmittingBooking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      AppStrings.confirmBooking,
                      style: AppTypography.button,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'You won\'t be charged until the lesson is confirmed',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    final currentTeacher = await _teacherRepository.getTeacherByIdOrUid(
      widget.teacherId,
    );
    if (!mounted) return;
    final selectedTime = _selectedTime;

    if (currentUser == null || currentTeacher == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in and complete booking details.'),
        ),
      );
      return;
    }

    final parts = selectedTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    final lessonFee = _totalPrice(currentTeacher);
    final platformFee = lessonFee * 0.1;
    final totalAmount = lessonFee + platformFee;
    final slotId = _bookingRepository.buildSlotId(
      teacherUid: currentTeacher.uid,
      scheduledAt: scheduledAt,
    );

    final currentDayName = _weekdayShortNames[_selectedDate.weekday - 1];
    if (!currentTeacher.availableDays.contains(currentDayName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher is not available on selected day.'),
        ),
      );
      return;
    }

    final hasConflict = await _bookingRepository.hasTeacherConflict(
      teacherUid: currentTeacher.uid,
      teacherDocId: currentTeacher.id,
      scheduledAt: scheduledAt,
      durationMinutes: _selectedDuration,
    );
    if (hasConflict) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected time slot is no longer available.'),
        ),
      );
      return;
    }

    setState(() => _isSubmittingBooking = true);
    try {
      await _bookingRepository.createPendingBooking(
        BookingCreateRequest(
          slotId: slotId,
          learnerId: currentUser.uid,
          learnerName:
              currentUser.displayName ?? currentUser.email ?? 'Learner',
          teacherId: currentTeacher.uid,
          teacherDocId: currentTeacher.id,
          teacherName: currentTeacher.name,
          offerId: _selectedOfferId,
          offerTitle: _selectedOfferTitle,
          language:
              _selectedOfferLanguage ??
              (currentTeacher.teachingLanguages.isNotEmpty
                  ? currentTeacher.teachingLanguages.first
                  : 'Language'),
          scheduledAt: scheduledAt,
          durationMinutes: _selectedOfferDuration ?? _selectedDuration,
          paymentMethod: _selectedPayment,
          paymentRoute: _resolvePaymentRoute(),
          lessonFee: lessonFee,
          platformFee: platformFee,
          totalAmount: totalAmount,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create booking. Please try again.'),
        ),
      );
      setState(() => _isSubmittingBooking = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmittingBooking = false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text('Booking Requested!', style: AppTypography.h4),
            const SizedBox(height: 8),
            Text(
              'Your booking request has been sent to ${currentTeacher.name}. You\'ll receive a notification once they confirm.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/my-courses');
                },
                child: Text('View My Bookings', style: AppTypography.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}
