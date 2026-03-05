import 'package:cloud_firestore/cloud_firestore.dart';

class BookingCreateRequest {
  final String slotId;
  final String learnerId;
  final String learnerName;
  final String teacherId;
  final String teacherDocId;
  final String teacherName;
  final String? offerId;
  final String? offerTitle;
  final String language;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String paymentMethod;
  final String paymentRoute;
  final double lessonFee;
  final double platformFee;
  final double totalAmount;

  const BookingCreateRequest({
    required this.slotId,
    required this.learnerId,
    required this.learnerName,
    required this.teacherId,
    required this.teacherDocId,
    required this.teacherName,
    required this.offerId,
    required this.offerTitle,
    required this.language,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.paymentMethod,
    required this.paymentRoute,
    required this.lessonFee,
    required this.platformFee,
    required this.totalAmount,
  });
}

class BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  String buildSlotId({
    required String teacherUid,
    required DateTime scheduledAt,
  }) {
    return '${teacherUid}_${scheduledAt.millisecondsSinceEpoch}';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchTeacherBookings({
    required String teacherUid,
    required String teacherDocId,
  }) {
    final refs = <String>{teacherUid.trim(), teacherDocId.trim()}
      ..removeWhere((value) => value.isEmpty);

    if (refs.length == 1) {
      return _firestore
          .collection('bookings')
          .where('teacherId', isEqualTo: refs.first)
          .snapshots();
    }

    return _firestore
        .collection('bookings')
        .where('teacherId', whereIn: refs.toList())
        .snapshots();
  }

  Future<bool> hasTeacherConflict({
    required String teacherUid,
    required String teacherDocId,
    required DateTime scheduledAt,
    required int durationMinutes,
  }) async {
    final snapshot = await watchTeacherBookings(
      teacherUid: teacherUid,
      teacherDocId: teacherDocId,
    ).first;

    final requestedEnd = scheduledAt.add(Duration(minutes: durationMinutes));
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = (data['status'] as String?) ?? '';
      final isActive =
          status == 'pending' ||
          status == 'accepted' ||
          status == 'in_progress';
      if (!isActive) continue;

      final bookedAt = (data['scheduledAt'] as Timestamp?)?.toDate();
      if (bookedAt == null) continue;
      if (bookedAt.year != scheduledAt.year ||
          bookedAt.month != scheduledAt.month ||
          bookedAt.day != scheduledAt.day) {
        continue;
      }

      final bookedDuration = (data['durationMinutes'] as num?)?.toInt() ?? 60;
      final bookedEnd = bookedAt.add(Duration(minutes: bookedDuration));
      final overlaps =
          scheduledAt.isBefore(bookedEnd) && requestedEnd.isAfter(bookedAt);
      if (overlaps) {
        return true;
      }
    }

    return false;
  }

  Future<void> createPendingBooking(BookingCreateRequest request) async {
    final bookingRef = _firestore.collection('bookings').doc(request.slotId);

    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(bookingRef);
      if (existing.exists) {
        throw Exception('conflict');
      }

      tx.set(bookingRef, {
        'slotId': request.slotId,
        'learnerId': request.learnerId,
        'learnerName': request.learnerName,
        'teacherId': request.teacherId,
        'teacherDocId': request.teacherDocId,
        'teacherName': request.teacherName,
        'offerId': request.offerId,
        'offerTitle': request.offerTitle,
        'language': request.language,
        'scheduledAt': Timestamp.fromDate(request.scheduledAt),
        'durationMinutes': request.durationMinutes,
        'paymentMethod': request.paymentMethod,
        'paymentRoute': request.paymentRoute,
        'status': 'pending',
        'lessonFee': request.lessonFee,
        'platformFee': request.platformFee,
        'totalAmount': request.totalAmount,
        'currency': 'USD',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchLearnerBookings(
    String learnerId,
  ) {
    return _firestore
        .collection('bookings')
        .where('learnerId', isEqualTo: learnerId)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchBooking(
    String bookingId,
  ) {
    return _firestore.collection('bookings').doc(bookingId).snapshots();
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    String? cancellationReason,
    String? cancelledBy,
  }) {
    final payload = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (cancellationReason != null && cancellationReason.trim().isNotEmpty) {
      payload['cancellationReason'] = cancellationReason.trim();
    }

    if (cancelledBy != null && cancelledBy.trim().isNotEmpty) {
      payload['cancelledBy'] = cancelledBy.trim();
    }

    return _firestore.collection('bookings').doc(bookingId).update(payload);
  }
}
